# main.py
from src.camera_server import CameraServer
from config import SERVER_CONFIG

if __name__ == "__main__":
    server = CameraServer(
        host=SERVER_CONFIG['HOST'],
        port=SERVER_CONFIG['PORT']
    )
    server.start()
