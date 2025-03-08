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

This project is developed by the Students of IIITDM Jabalpur under the mentorship of **Dr. Punnet Tandon** and co-mentorship of **Pritee Khanna**.

# Digident - Dental Imaging and Analysis App

A Flutter application for dental imaging, analysis, and condition detection using machine learning.

## Features

### 1. WiFi Connection Screen
- Automatic scanning for available WiFi networks
- Highlights the Digident camera server network
- Seamless connection to the camera server
- Real-time connection status updates
- Automatic redirection to camera screen upon successful connection

### 2. Camera View Screen
- Real-time camera feed display from the dental camera
- High-quality frame capture functionality
- ML-powered image processing
- Quick access to server settings
- Supports both light and dark modes

### 3. Frame Display Screen
- High-resolution display of captured dental images
- Advanced image saving features:
  - Dedicated `/Download/Digident` folder
  - Timestamp-based unique filenames
  - Android 10+ storage compatibility
  - Clear success notifications with save location
- Universal sharing capabilities:
  - System share sheet integration
  - Multi-platform support
- Modern UI elements:
  - Gradient backgrounds
  - Shadowed containers
  - Rounded corners
  - Adaptive theming

### 4. ML Analysis Capabilities
- Dental condition detection for:
  - Caries
  - Healthy teeth
  - Plaque
  - Calculus
  - Gingivitis
  - Periodontitis
  - Dental Abscess
  - Fluorosis
  - Enamel Hypoplasia
  - Dental Erosion
- Confidence scoring system
- Priority-based result sorting

### 5. Results Display Screen
- Processed image visualization
- Detailed condition analysis:
  - Percentage-based confidence scores
  - Color-coded indicators
  - Priority-sorted listings
- Result sharing functionality
- Easy navigation back to camera

### 6. Server Settings Screen
- IP and port configuration
- Persistent settings storage
- Connection testing
- Default settings restoration
- Built-in troubleshooting guide

## Technical Details

### Permissions
- Storage access for saving images
- WiFi connectivity
- Location services for network scanning

### System Requirements
- Android API 29+ (Android 10 or higher)
- Flutter 3.0 or higher
- Dart SDK 3.0 or higher

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
