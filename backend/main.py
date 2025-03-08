# main.py
from src.camera_server import CameraServer
from src.wifi_hotspot import WiFiHotspot
from config import SERVER_CONFIG
import time
import logging
import signal
import sys
import socket
import os

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

def signal_handler(sig, frame):
    """Handle Ctrl+C gracefully"""
    logger.info("Shutting down...")
    if hotspot and hotspot.is_active:
        logger.info("Stopping WiFi hotspot...")
        hotspot.stop()
    if server:
        logger.info("Stopping camera server...")
        server.cleanup()
    sys.exit(0)

def is_port_in_use(host, port):
    """Check if a port is already in use"""
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.bind((host, port))
            return False
    except socket.error:
        return True

def find_available_port(start_port, max_attempts=10):
    """Find an available port starting from start_port"""
    port = start_port
    for _ in range(max_attempts):
        if not is_port_in_use(SERVER_CONFIG['HOST'], port):
            return port
        port += 1
    return None

if __name__ == "__main__":
    # Register signal handler for graceful shutdown
    signal.signal(signal.SIGINT, signal_handler)
    
    # Global variables for cleanup
    hotspot = None
    server = None
    
    try:
        # Start WiFi hotspot
        logger.info("Starting WiFi hotspot...")
        hotspot = WiFiHotspot(
            ssid=SERVER_CONFIG.get('HOTSPOT_SSID', 'Digident'),
            password=SERVER_CONFIG.get('HOTSPOT_PASSWORD', 'digident123')
        )
        
        if hotspot.start():
            # Get the IP address of the hotspot
            ip_address = hotspot.get_ip_address()
            if ip_address:
                logger.info(f"WiFi hotspot started with SSID: {hotspot.ssid}")
                logger.info(f"Password: {hotspot.password}")
                logger.info(f"IP Address: {ip_address}")
                
                # Update server config with hotspot IP
                SERVER_CONFIG['HOST'] = ip_address
            else:
                logger.warning("Could not determine hotspot IP address, using configured IP")
        else:
            logger.warning("Failed to start WiFi hotspot, using configured network settings")
            # Try to get the current network IP as a fallback
            fallback_ip = hotspot.get_current_network_ip()
            if fallback_ip:
                logger.info(f"Using current network IP address: {fallback_ip}")
                SERVER_CONFIG['HOST'] = fallback_ip
                
                # Get current WiFi SSID if available
                current_ssid = hotspot.get_current_wifi_ssid()
                if current_ssid:
                    logger.info(f"Current WiFi network: {current_ssid}")
                    logger.info(f"Please connect your mobile device to the WiFi network: {current_ssid}")
                else:
                    logger.info(f"Please connect your mobile device to the same WiFi network as this computer")
        
        # Check if the configured port is available, if not find an available one
        if is_port_in_use(SERVER_CONFIG['HOST'], SERVER_CONFIG['PORT']):
            logger.warning(f"Port {SERVER_CONFIG['PORT']} is already in use")
            available_port = find_available_port(SERVER_CONFIG['PORT'] + 1)
            if available_port:
                logger.info(f"Using alternative port: {available_port}")
                SERVER_CONFIG['PORT'] = available_port
            else:
                logger.error("Could not find an available port")
                sys.exit(1)
        
        # Create a file with the server information for the Flutter app
        server_info_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'server_info.txt')
        with open(server_info_path, 'w') as f:
            f.write(f"HOST={SERVER_CONFIG['HOST']}\n")
            f.write(f"PORT={SERVER_CONFIG['PORT']}\n")
            f.write(f"SSID={hotspot.ssid}\n")
            f.write(f"PASSWORD={hotspot.password}\n")
        logger.info(f"Server information saved to {server_info_path}")
        
        # Start camera server
        logger.info(f"Starting camera server on {SERVER_CONFIG['HOST']}:{SERVER_CONFIG['PORT']}...")
        server = CameraServer(
            host=SERVER_CONFIG['HOST'],
            port=SERVER_CONFIG['PORT']
        )
        server.start()
        
    except Exception as e:
        logger.error(f"Error in main: {e}")
        # Cleanup
        if hotspot and hotspot.is_active:
            hotspot.stop()
        if server:
            server.cleanup()
