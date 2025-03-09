import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../models/detection_result.dart';

class MLService {
  List<String>? _labels;
  bool _modelAvailable = false;
  static const String labelsFileName = "labels.txt";

  // Model configuration
  final int inputSize = 224; // Standard size for many models
  final int numResults = 5; // Top 5 results
  final double threshold = 0.1; // Minimum confidence threshold
  final Random _random = Random();

  Future<void> loadModel() async {
    try {
      // Try to load labels from assets
      final labelsData = await _loadLabelsFromAssets();

      // Parse labels
      _labels =
          labelsData.split('\n').where((label) => label.isNotEmpty).toList();

      // For now, we'll just use mock results
      _modelAvailable = false;
    } catch (e) {
      rethrow;
    }
  }

  Future<String> _loadLabelsFromAssets() async {
    try {
      // First try to load from assets
      return await rootBundle.loadString('assets/ml/$labelsFileName');
    } catch (e) {
      // If not in assets, check if it's in the app directory
      final appDir = await getApplicationDocumentsDirectory();
      final labelsFile = File('${appDir.path}/$labelsFileName');

      if (await labelsFile.exists()) {
        return await labelsFile.readAsString();
      }

      // If no labels file found, return some default dental labels
      return '''
Caries
Healthy
Plaque
Calculus
Gingivitis
Periodontitis
Dental Abscess
Fluorosis
Enamel Hypoplasia
Dental Erosion
''';
    }
  }

  Future<List<DetectionResult>> processImage(Uint8List imageBytes) async {
    if (_labels == null || _labels!.isEmpty) {
      throw Exception('Labels not loaded');
    }

    // Use mock results if model is not available
    if (!_modelAvailable) {
      return _generateMockResults();
    }

    return _generateMockResults();
  }

  List<DetectionResult> _generateMockResults() {
    if (_labels == null || _labels!.isEmpty) {
      return [];
    }

    // Generate 1-3 random results
    final numDetections = 1 + _random.nextInt(3);
    final results = <DetectionResult>[];

    // Always include "Healthy" with high confidence if we have it
    final healthyIndex =
        _labels!.indexWhere((label) => label.toLowerCase() == 'healthy');

    if (healthyIndex >= 0) {
      results.add(DetectionResult(
        label: _labels![healthyIndex],
        confidence: 0.7 + (_random.nextDouble() * 0.25), // 70-95% confidence
      ));
    }

    // Add some random detections
    final usedIndices = <int>{if (healthyIndex >= 0) healthyIndex};

    while (results.length < numDetections &&
        usedIndices.length < _labels!.length) {
      int index;
      do {
        index = _random.nextInt(_labels!.length);
      } while (usedIndices.contains(index));

      usedIndices.add(index);

      // Generate a random confidence between threshold and 0.9
      final confidence = threshold + (_random.nextDouble() * (0.9 - threshold));

      results.add(DetectionResult(
        label: _labels![index],
        confidence: confidence,
      ));
    }

    // Sort by confidence (descending)
    results.sort((a, b) => b.confidence.compareTo(a.confidence));

    return results;
  }

  void dispose() {
    // No resources to dispose
  }
}
