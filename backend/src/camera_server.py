import cv2
import socket
import struct
import numpy as np
from threading import Thread, Lock
from queue import Empty, Queue, Full
import time

class CameraServer:
    def __init__(self, host='172.27.111.74', port=5000, fps_limit=30):
        # Network setup
        self.server_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, 65507)
        self.server_socket.bind((host, port))
        
        # Camera setup
        self.camera = cv2.VideoCapture(0)
        self._optimize_camera_settings()
        
        # Threading and synchronization
        self.frame_queue = Queue(maxsize=2)  # Limit queue size to prevent memory buildup
        self.client_lock = Lock()
        self.client_address = None
        self.running = True
        self.fps_limit = fps_limit
        self.last_frame_time = 0
        
    def _optimize_camera_settings(self):
        """Configure optimal camera settings for performance"""
        self.camera.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
        self.camera.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)
        self.camera.set(cv2.CAP_PROP_FPS, 30)
        self.camera.set(cv2.CAP_PROP_FOURCC, cv2.VideoWriter_fourcc(*'MJPG'))
        self.camera.set(cv2.CAP_PROP_BUFFERSIZE, 1)  # Minimize buffer size
        
    def start(self):
        """Start the server with separate threads for frame capture and sending"""
        print(f"Server started, waiting for connection...")
        
        # Start worker threads
        Thread(target=self._handle_client_messages, daemon=True).start()
        Thread(target=self._capture_frames, daemon=True).start()
        Thread(target=self._send_frames, daemon=True).start()
        
        try:
            while self.running:
                time.sleep(0.1)  # Main thread sleep to reduce CPU usage
        except KeyboardInterrupt:
            self.cleanup()
            
    def _capture_frames(self):
        """Continuously capture frames in a separate thread"""
        while self.running:
            if not self.client_address:
                time.sleep(0.1)
                continue
                
            # Implement frame rate limiting
            current_time = time.time()
            if (current_time - self.last_frame_time) < (1.0 / self.fps_limit):
                continue
                
            ret, frame = self.camera.read()
            if not ret:
                continue
                
            # Optimize frame before queueing
            frame = cv2.resize(frame, (640, 480))
            _, img_encoded = cv2.imencode(
                '.jpg',
                frame,
                [cv2.IMWRITE_JPEG_QUALITY, 70]  # Reduced quality for better performance
            )
            
            try:
                self.frame_queue.put_nowait(img_encoded.tobytes())
                self.last_frame_time = current_time
            except Full:
                # If queue is full, skip frame
                continue
                
    def _send_frames(self):
        """Send frames to client in a separate thread"""
        chunk_size = 65000  # Just under UDP max size
        
        while self.running:
            if not self.client_address:
                time.sleep(0.1)
                continue
                
            try:
                data = self.frame_queue.get(timeout=1)
                chunks = [data[i:i + chunk_size] for i in range(0, len(data), chunk_size)]
                
                with self.client_lock:
                    # Send number of chunks
                    self.server_socket.sendto(
                        struct.pack('I', len(chunks)),
                        self.client_address
                    )
                    
                    # Send chunks with minimal delay
                    for i, chunk in enumerate(chunks):
                        packet = struct.pack('I', i) + chunk
                        self.server_socket.sendto(packet, self.client_address)
                        
            except Empty:
                continue
            except Exception as e:
                print(f"Error sending frame: {e}")
                
    def _handle_client_messages(self):
        """Handle client connection messages"""
        while self.running:
            try:
                data, address = self.server_socket.recvfrom(1024)
                if data == b'connect':
                    with self.client_lock:
                        self.client_address = address
                        print(f"Client connected from {address}")
                elif data == b'disconnect':
                    with self.client_lock:
                        self.client_address = None
                        print(f"Client disconnected from {address}")
            except Exception as e:
                print(f"Error handling client message: {e}")
                continue
                
    def cleanup(self):
        """Clean up resources"""
        self.running = False
        time.sleep(0.5)  # Allow threads to finish
        self.camera.release()
        self.server_socket.close()
        print("Server shutdown complete")

if __name__ == "__main__":
    server = CameraServer()
    try:
        server.start()
    except KeyboardInterrupt:
        print("\nShutting down server...")
        server.cleanup()