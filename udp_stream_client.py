'''
START SEQUENCE
The client.py sends a UDP packet containting the string "START".
The ESP starts sending image frames continously to the client.py (while checking afer every 5 frames if the client.py sent over a "STOP")

'''

import socket
import cv2
import numpy as np

UDP_IP = "192.168.4.1"  # ESP32CAM's IP address
UDP_PORT = 12345
BUFFER_SIZE = 1024

# Create UDP socket
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.bind(('', UDP_PORT))
sock.settimeout(10)  # Timeout for response

# Send START command
sock.sendto(b"START", (UDP_IP, UDP_PORT))
print("Streaming started. Press 'q' to stop.")

try:
    while True:
        # Receive image size
        print("Listening...")
        size_packet, addr = sock.recvfrom(BUFFER_SIZE)
        print(addr, size_packet)
        image_size = int.from_bytes(size_packet, "little")


        # Receive image data
        image_data = bytearray()
        while len(image_data) < image_size:
            packet, addr = sock.recvfrom(BUFFER_SIZE)
            image_data.extend(packet)

        # Decode and display the image
        image_array = np.frombuffer(image_data, dtype=np.uint8)
        frame = cv2.imdecode(image_array, cv2.IMREAD_COLOR)

        if frame is not None:
            cv2.imshow("Live Stream", frame)
            if cv2.waitKey(1) & 0xFF == ord('q'):
                print("Streaming stopped.")
                break
        else:
            print("Failed to decode frame.")

except socket.timeout:
    print("Stream timeout.")
except KeyboardInterrupt:
    print("Stream stopped by user.")
finally:
    sock.sendto(b"STOP", (UDP_IP, UDP_PORT))  # Send STOP command
    sock.close()
    cv2.destroyAllWindows()
