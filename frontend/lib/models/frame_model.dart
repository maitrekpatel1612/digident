// lib/models/frame_model.dart
import 'dart:typed_data';

class FrameModel {
  final Uint8List frameData;
  final DateTime timestamp;

  FrameModel({required this.frameData}) : timestamp = DateTime.now();
}
