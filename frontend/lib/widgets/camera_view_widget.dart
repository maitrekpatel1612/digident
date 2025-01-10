// camera_view_widget.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/udp_service.dart';

class CameraViewWidget extends StatefulWidget {
  const CameraViewWidget({super.key});

  @override
  State<CameraViewWidget> createState() => _CameraViewWidgetState();
}

class _CameraViewWidgetState extends State<CameraViewWidget> {
  final UDPService _udpService = UDPService();
  Uint8List? _currentFrame;
  bool _isConnected = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeUDPService();
  }

  Future<void> _initializeUDPService() async {
    try {
      await _udpService.initialize();

      _udpService.onFrameReceived = (Uint8List frameData) {
        if (mounted) {
          setState(() {
            _currentFrame = frameData;
            _errorMessage = null;
          });
        }
      };

      _udpService.onConnectionStateChanged = (bool connected) {
        if (mounted) {
          setState(() {
            _isConnected = connected;
            if (!connected) {
              _currentFrame = null;
            }
          });
        }
      };

      _udpService.onError = (String error) {
        if (mounted) {
          setState(() {
            _errorMessage = error;
          });
        }
      };
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to initialize camera stream: $e';
        });
      }
    }
  }

  Future<void> _retryConnection() async {
    if (mounted) {
      setState(() {
        _errorMessage = null;
      });
    }
    await _initializeUDPService();
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _retryConnection,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry Connection'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoConnectionWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.signal_wifi_off,
            size: 48,
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(height: 16),
          const Text('No connection to camera server'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _retryConnection,
            icon: const Icon(Icons.refresh),
            label: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_currentFrame == null) {
      return const Center(child: Text('Waiting for video stream...'));
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.memory(
          _currentFrame!,
          gaplessPlayback: true,
          fit: BoxFit.contain,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            return child;
          },
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image,
                    size: 48,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  const Text('Error loading frame'),
                ],
              ),
            );
          },
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isConnected
                  ? Colors.green.withAlpha((0.7 * 255).toInt())
                  : Colors.red.withAlpha((0.7 * 255).toInt()),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _isConnected ? 'Connected' : 'Disconnected',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return _buildErrorWidget();
    }

    if (!_isConnected) {
      return _buildNoConnectionWidget();
    }

    return _buildCameraPreview();
  }

  @override
  void dispose() {
    _udpService.dispose();
    super.dispose();
  }
}
