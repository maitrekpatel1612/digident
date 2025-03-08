class DetectionResult {
  final String label;
  final double confidence;
  final List<double>? boundingBox; // [x, y, width, height] if object detection

  DetectionResult({
    required this.label,
    required this.confidence,
    this.boundingBox,
  });

  @override
  String toString() {
    return 'DetectionResult(label: $label, confidence: ${(confidence * 100).toStringAsFixed(2)}%)';
  }
} 