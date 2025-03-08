import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/detection_result.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'dart:io';

class ResultDisplayScreen extends StatelessWidget {
  final Uint8List frameData;
  final List<DetectionResult> results;

  const ResultDisplayScreen({
    super.key,
    required this.frameData,
    required this.results,
  });

  // Simple function to share the image with results
  Future<void> _shareResults(BuildContext context) async {
    try {
      // Get temporary directory
      final tempDir = await path_provider.getTemporaryDirectory();
      
      // Create a file with a simple name
      final file = File('${tempDir.path}/digident_analysis.jpg');
      await file.writeAsBytes(frameData);
      
      // Create text with results
      final resultsText = results.isEmpty 
          ? 'No results detected'
          : results.map((result) => 
              '${result.label}: ${(result.confidence * 100).toStringAsFixed(1)}%')
              .join('\n');
      
      // Share the file and results using share_plus
      await Share.shareXFiles(
        [XFile(file.path)], 
        text: 'Digident Analysis Results:\n$resultsText',
      );
      
    } catch (e) {
      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Analysis Results'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareResults(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Image container
            Container(
              height: MediaQuery.of(context).size.height * 0.4,
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withAlpha(40),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.memory(
                  frameData,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            
            // Results header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.auto_fix_high, color: Colors.purple),
                  const SizedBox(width: 8),
                  Text(
                    'Analysis Results',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade200,
                    ),
                  ),
                ],
              ),
            ),
            
            // Results list
            Expanded(
              child: results.isEmpty
                  ? _buildEmptyResults()
                  : _buildResultsList(),
            ),
            
            // Bottom buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back to Camera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _shareResults(context),
                    icon: const Icon(Icons.share),
                    label: const Text('Share Results'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
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

  Widget _buildEmptyResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey.shade700,
          ),
          const SizedBox(height: 16),
          Text(
            'No results detected',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try with a different image or adjust settings',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        final confidence = result.confidence * 100;
        
        // Determine color based on confidence
        Color confidenceColor;
        if (confidence >= 90) {
          confidenceColor = Colors.green;
        } else if (confidence >= 70) {
          confidenceColor = Colors.lightGreen;
        } else if (confidence >= 50) {
          confidenceColor = Colors.amber;
        } else {
          confidenceColor = Colors.orange;
        }
        
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          color: Colors.grey.shade900,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Label number
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.purple.shade900,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Label and confidence
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.label,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Confidence: ',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade400,
                            ),
                          ),
                          Text(
                            '${confidence.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: confidenceColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Confidence indicator
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: confidenceColor.withOpacity(0.5),
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${confidence.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: confidenceColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
} 