import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:device_info_plus/device_info_plus.dart';

class FrameDisplayScreen extends StatelessWidget {
  final Uint8List frameData;

  const FrameDisplayScreen({super.key, required this.frameData});

  // Simple function to share the image
  Future<void> _shareImage(BuildContext context) async {
    try {
      // Get temporary directory
      final tempDir = await path_provider.getTemporaryDirectory();
      
      // Create a file with a simple name
      final file = File('${tempDir.path}/digident_capture.jpg');
      await file.writeAsBytes(frameData);
      
      // Share the file using share_plus
      await Share.shareXFiles([XFile(file.path)], text: 'Captured with Digident');
      
    } catch (e) {
      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing: $e')),
        );
      }
    }
  }

  // Function to save the image to Digident folder
  Future<void> _saveImage(BuildContext context) async {
    try {
      // Check Android version first
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;
      
      // For Android 13+ (API 33+), we need to use photos permission
      // For Android 10-12 (API 29-32), we use storage permission
      // For older versions, we also use storage permission
      final Permission storagePermission = sdkInt >= 33 
          ? Permission.photos
          : Permission.storage;
      
      // Check if permission is already granted
      var status = await storagePermission.status;
      
      // If permission is not granted, request it directly without showing our custom dialog
      if (!status.isGranted) {
        status = await storagePermission.request();
        
        // If still not granted after request, handle the denial
        if (!status.isGranted) {
          if (status.isPermanentlyDenied && context.mounted) {
            // Show dialog to open app settings
            final openSettings = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Permission Denied'),
                content: const Text(
                  'Storage permission is required to save images. '
                  'Please enable it in app settings.'
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('CANCEL'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('OPEN SETTINGS'),
                  ),
                ],
              ),
            ) ?? false;
            
            if (openSettings) {
              await openAppSettings();
            }
          }
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Storage permission is required to save images')),
            );
          }
          return;
        }
      }

      // Get the root storage path
      String basePath;
      
      if (sdkInt >= 29) {
        // For Android 10+, use the Downloads directory
        final downloadsDir = await path_provider.getExternalStorageDirectories(
          type: path_provider.StorageDirectory.downloads,
        );
        if (downloadsDir == null || downloadsDir.isEmpty) {
          // Fallback to standard Downloads directory
          basePath = '/storage/emulated/0/Download';
          // Check if directory exists
          final dir = Directory(basePath);
          if (!await dir.exists()) {
            // Final fallback to app's external files directory
            final appDir = await path_provider.getExternalStorageDirectory();
            if (appDir == null) {
              throw Exception('Could not access external storage');
            }
            basePath = appDir.path;
          }
        } else {
          // Extract the root path from the downloads directory
          final pathParts = downloadsDir[0].path.split('/Android');
          basePath = '${pathParts[0]}/Download';
        }
      } else {
        // For older Android versions, use the Download directory directly
        basePath = '/storage/emulated/0/Download';
        // Check if directory exists
        final dir = Directory(basePath);
        if (!await dir.exists()) {
          // Fallback to external storage
          final externalDir = await path_provider.getExternalStorageDirectory();
          if (externalDir == null) {
            throw Exception('Could not access external storage');
          }
          basePath = externalDir.path;
        }
      }

      // Create Digident directory if it doesn't exist
      final imagesPath = '$basePath/Digident';
      final imagesDir = Directory(imagesPath);
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      // Generate a unique filename with timestamp
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filePath = '$imagesPath/digident_capture_${timestamp}.jpg';
      
      // Save the image
      final file = File(filePath);
      await file.writeAsBytes(frameData);
      
      // Show success message with path
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Image saved successfully!'),
                Text(
                  'Location: $imagesPath',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        title: const Text('Captured Frame'),
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.blue.shade700,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareImage(context),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode 
                ? [Colors.black, Colors.grey[900]!] 
                : [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: isDarkMode 
                              ? Colors.blue.withAlpha(40) 
                              : Colors.grey.withAlpha(100),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                      border: Border.all(
                        color: isDarkMode 
                            ? Colors.grey[800]! 
                            : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.memory(
                        frameData,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      context,
                      icon: Icons.edit,
                      label: 'Edit',
                      color: Colors.orange,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Edit functionality coming soon')),
                        );
                      },
                    ),
                    _buildActionButton(
                      context,
                      icon: Icons.save_alt,
                      label: 'Save',
                      color: Colors.green,
                      onPressed: () => _saveImage(context),
                    ),
                    _buildActionButton(
                      context,
                      icon: Icons.share,
                      label: 'Share',
                      color: Colors.blue,
                      onPressed: () => _shareImage(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, color: color),
            onPressed: onPressed,
            iconSize: 28,
            padding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white70
                : Colors.grey[800],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
} 