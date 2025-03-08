import 'package:flutter/material.dart';
import '../widgets/camera_view_widget.dart';
import 'frame_display_screen.dart';
import 'dart:typed_data';

class CameraViewScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;
  
  const CameraViewScreen({
    super.key, 
    required this.toggleTheme,
    required this.isDarkMode,
  });

  @override
  State<CameraViewScreen> createState() => _CameraViewScreenState();
}

class _CameraViewScreenState extends State<CameraViewScreen> {
  Uint8List? _currentFrame;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // App name with icon
                    Row(
                      children: [
                        const Icon(
                          Icons.donut_large, // Replace with your desired icon
                          color: Colors.blue,
                          size: 28,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Digident',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: widget.isDarkMode 
                            ? Colors.amber.withAlpha(40) 
                            : Colors.indigo.withAlpha(40),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: Icon(
                          widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                          color: widget.isDarkMode ? Colors.amber : Colors.indigo,
                          size: 24,
                        ),
                        tooltip: widget.isDarkMode ? 'Switch to light mode' : 'Switch to dark mode',
                        onPressed: () {
                          widget.toggleTheme();
                        },
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.refresh,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: () {
                        // Refresh functionality can be added here
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Refreshing connection...')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: widget.isDarkMode 
                            ? Colors.blue.withAlpha(51) 
                            : Colors.grey.withAlpha(100),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                    child: CameraViewWidget(
                      onFrameReceived: (Uint8List frameData) {
                        // Store the frame data for capturing
                        setState(() {
                          _currentFrame = frameData; // Store the current frame
                        });
                      },
                    ),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                decoration: BoxDecoration(
                  color: widget.isDarkMode 
                      ? Colors.blue.withAlpha(20) 
                      : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.isDarkMode 
                        ? Colors.blue.withAlpha(60) 
                        : Colors.blue.shade200,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.isDarkMode 
                          ? Colors.blue.withAlpha(15) 
                          : Colors.grey.withAlpha(40),
                      blurRadius: 4,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: widget.isDarkMode 
                          ? Colors.blue.shade300 
                          : Colors.blue.shade700,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Make sure server is running',
                      style: TextStyle(
                        color: widget.isDarkMode 
                            ? Colors.blue.shade300 
                            : Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // Add Capture Button
              ElevatedButton(
                onPressed: () {
                  // Capture the frame and navigate to the next screen
                  if (_currentFrame != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FrameDisplayScreen(frameData: _currentFrame!),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No frame available to capture')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Capture Frame',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
