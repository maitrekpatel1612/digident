<p align="center">
  <img src="frontend/assets/images/digident_banner.png" alt="Digident Logo"/>
</p>

<p align="center" style="font-size: 32px;">AI Based Futuristic Device for Dental Care</p>

## Overview

Digident is a comprehensive dental care solution that combines hardware and software to provide real-time dental analysis. The system consists of a Flutter mobile application that connects wirelessly to the Digident device via WiFi, allowing users to capture, view, and analyze dental images.

## Features

- **WiFi Connectivity**: Seamlessly connect to the Digident device via WiFi
- **Real-time Camera Feed**: View live camera feed from the dental device
- **Image Capture**: Save high-quality dental images for later reference
- **Image Sharing**: Easily share dental images with professionals
- **Dark/Light Mode**: Comfortable viewing experience in any environment
- **User-friendly Interface**: Intuitive design for easy navigation

## Technical Architecture

### Frontend (Flutter)

- Cross-platform mobile application (Android/iOS)
- Real-time image processing and display
- Secure local storage for dental images
- Modern UI with Material Design

### Backend (Python)

- Camera server with UDP streaming
- WiFi hotspot creation for direct device connection
- Image processing capabilities
- Configurable settings for different environments

## Getting Started

### Frontend Setup

1. **Install Flutter**: Follow the instructions on the official [Flutter website](https://docs.flutter.dev/get-started/install) to install Flutter on your machine.

2. **Clone the Repository**:

    ```sh
    git clone <repository-url>
    cd digident
    ```

3. **Install Dependencies**:

    ```sh
    cd frontend
    flutter pub get
    ```

4. **Run the Application**:

    ```sh
    flutter run
    ```

### Backend Setup

1. Navigate to the `backend` directory:

    ```sh
    cd backend
    ```

2. Install the required Python packages:

    ```sh
    pip install -r requirements.txt
    ```

3. Run the backend server:

    ```sh
    python main.py
    ```

## Configuration

### Custom IP Address for UDP Connection

1. Frontend configuration (`frontend/lib/config/app_config.dart`):

    ```dart
    static const String SERVER_IP = '192.168.137.1'; // Your computer or ESP32 IP address
    ```

2. Backend configuration (`backend/config.py`):

    ```python
    SERVER_CONFIG = {
        'HOST': '192.168.137.1', # Your server IP address
        'PORT': 5000,
        'FRAME_WIDTH': 640,
        'FRAME_HEIGHT': 480,
        'JPEG_QUALITY': 80
    }
    ```

## User Flow

1. Start the backend server on your computer
2. Launch the Digident app on your mobile device
3. Connect to the Digident WiFi network
4. View the live camera feed
5. Capture and analyze dental images
6. Save or share images as needed

## Contributing

If you would like to contribute to this project, please follow these steps:

1. Fork the repository
2. Create a new branch (`git checkout -b feature-branch`)
3. Commit your changes (`git commit -m 'Add some feature'`)
4. Push to the branch (`git push origin feature-branch`)
5. Open a pull request

## About

This project is developed by the Students of IIITDM Jabalpur under the mentorship of **Dr. Punnet Tandon**.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
