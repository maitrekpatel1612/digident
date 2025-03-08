import 'package:flutter/material.dart';
import '../widgets/camera_view_widget.dart';
import 'frame_display_screen.dart';
import 'dart:typed_data';
import 'server_settings_screen.dart';
import '../widgets/app_logo.dart';

class CameraViewScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  
  const CameraViewScreen({
    super.key, 
    required this.toggleTheme,
  });

  @override
  State<CameraViewScreen> createState() => _CameraViewScreenState();
}

class _CameraViewScreenState extends State<CameraViewScreen> {
  Uint8List? _currentFrame;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const AppLogo(useLightModeColor: false),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ServerSettingsScreen(
                    toggleTheme: widget.toggleTheme,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: CameraViewWidget(
                onFrameReceived: (frameData) {
                  setState(() {
                    _currentFrame = frameData;
                  });
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _currentFrame != null
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FrameDisplayScreen(
                                  frameData: _currentFrame!,
                                ),
                              ),
                            );
                          }
                        : null,
                    icon: const Icon(Icons.camera),
                    label: const Text('Capture Frame'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 12.0,
                      ),
                      backgroundColor: Colors.blue.shade800,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
