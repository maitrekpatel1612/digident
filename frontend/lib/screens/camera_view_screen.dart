import 'package:flutter/material.dart';
import '../widgets/camera_view_widget.dart';
import 'frame_display_screen.dart';
import 'dart:typed_data';
import 'server_settings_screen.dart';
import '../widgets/app_logo.dart';
import '../services/ml_service.dart';
import '../models/detection_result.dart';
import 'result_display_screen.dart';

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
  bool _isProcessing = false;
  final MLService _mlService = MLService();

  @override
  void initState() {
    super.initState();
    _initMLService();
  }

  Future<void> _initMLService() async {
    try {
      await _mlService.loadModel();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load ML model: $e')),
        );
      }
    }
  }

  Future<void> _processImage() async {
    if (_currentFrame == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No image to process. Please wait for camera feed.')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final List<DetectionResult> results = await _mlService.processImage(_currentFrame!);
      
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultDisplayScreen(
              frameData: _currentFrame!,
              results: results,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing image: $e')),
        );
      }
    }
  }

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
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _currentFrame != null && !_isProcessing
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
                        horizontal: 20.0,
                        vertical: 12.0,
                      ),
                      backgroundColor: Colors.blue.shade800,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _currentFrame != null && !_isProcessing
                        ? _processImage
                        : null,
                    icon: _isProcessing 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.auto_fix_high),
                    label: Text(_isProcessing ? 'Processing...' : 'Process Image'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 12.0,
                      ),
                      backgroundColor: Colors.purple.shade800,
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
