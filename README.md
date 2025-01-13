# Digident - Futuristic Device for Dental Care🪥

Digident is a full-stack application that connects to the Digident Device using a UDP connection (wireless) to access the camera and process data frames. It provides proper analysis about dental health via the application.

## Getting Started

### Frontend Setup

1. **Install Flutter**: Follow the instructions on the official [Flutter website](https://docs.flutter.dev/get-started/install) to install Flutter on your machine.

2. **Clone the Repository**:

    ```sh
    git clone <repository-url>
    cd digident/frontend
    ```

3. **Install Dependencies**:

    ```sh
    flutter pub get
    ```

4. **Run the Application**:

    ```sh
    flutter run
    ```

### Backend Setup

1. Navigate to the `backend` directory:

    ```sh
    cd digident/backend
    ```

2. Install the required Python packages:

    ```sh
    pip install -r requirements.txt
    ```

3. Run the backend server:

    ```sh
    python main.py
    ```

### Important Cofiguration for Custom IP Address for the UDP Connection

1. Navigate to this path `cd frontend\lib\config\app_config.dart` and change the IP Address in the frontend app

    ```dart
    static const String SERVER_IP = '172.27.33.57';//Your IP Address of the Computer or ESP32 Module
    ```

2. Navigate to this path `backend\config.py` and change the IP Address in the backend server

    ```dart
    SERVER_CONFIG = {
        'HOST': '172.27.33.57', //Write your IP Address of the server here(Computer of ESP 32)
        'PORT': 5000,
        'FRAME_WIDTH': 640,
        'FRAME_HEIGHT': 480,
        'JPEG_QUALITY': 80
    }
    ```

### Contributing

If you would like to contribute to this project, please follow these steps:

1. Fork the repository.
2. Create a new branch (`git checkout -b feature-branch`).
3. Commit your changes (`git commit -m 'Add some feature'`).
4. Push to the branch (`git push origin feature-branch`).
5. Open a pull request.

## About Us

This project is created by the Students of IIITDM Jabalpur under the mentorship of **Dr. Punnet Tandon**.
