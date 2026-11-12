import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:injectable/injectable.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class DetectionResult {
  final String label;
  final double confidence;
  final double x;
  final double y;
  final double width;
  final double height;

  DetectionResult({
    required this.label,
    required this.confidence,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
}

@singleton
class YoloDetector {
  Interpreter? _interpreter;
  List<String>? _labels;

  static const int inputSize = 640;
  static const double confidenceThreshold = 0.5;
  static const double iouThreshold = 0.45;

  Future<void> initialize() async {
    try {
      // Load the model
      _interpreter = await Interpreter.fromAsset(
        'lib/domain/models/best_float32.tflite',
      );

      // Load labels
      final labelsData = await rootBundle.loadString('lib/domain/models/labels.txt');
      _labels = labelsData.split('\n').where((label) => label.isNotEmpty).toList();
      print('📋 Loaded ${_labels!.length} labels from labels.txt');
      print('📋 First few labels: ${_labels!.take(5).join(", ")}');
      print('📋 Label at index 1: "${_labels![1]}"');
      print('📋 Label at index 17: "${_labels!.length > 17 ? _labels![17] : "N/A"}"');
    } catch (e) {
      rethrow;
    }
  }

  Future<List<DetectionResult>> detectObjects(File imageFile) async {
    if (_interpreter == null || _labels == null) {
      await initialize();
    }

    // Read and decode image
    final imageBytes = await imageFile.readAsBytes();
    img.Image? image = img.decodeImage(imageBytes);

    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // Preprocess image
    final preprocessed = _preprocessImage(image);

    // Run inference
    // Output shape: [1, 29, 8400] where 29 = 4 bbox + 25 classes
    var output = List.filled(1 * 29 * 8400, 0.0).reshape([1, 29, 8400]);

    _interpreter!.run(preprocessed, output);

    // Post-process results
    final detections = _postProcess(output, image.width, image.height);

    return detections;
  }

  List _preprocessImage(img.Image image) {
    // Resize image to 640x640
    final resizedImage = img.copyResize(
      image,
      width: inputSize,
      height: inputSize,
      interpolation: img.Interpolation.linear,
    );

    // Convert to Float32List and normalize
    final input = Float32List(1 * inputSize * inputSize * 3);
    int pixelIndex = 0;

    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final pixel = resizedImage.getPixel(x, y);

        // Normalize to 0-1 range
        input[pixelIndex++] = pixel.r / 255.0;
        input[pixelIndex++] = pixel.g / 255.0;
        input[pixelIndex++] = pixel.b / 255.0;
      }
    }

    return input.reshape([1, inputSize, inputSize, 3]);
  }

  List<DetectionResult> _postProcess(List output, int imgWidth, int imgHeight) {
    List<DetectionResult> detections = [];

    // YOLOv11 output format: [1, 29, 8400]
    // 29 = 4 (bbox) + 25 (classes)
    // 8400 = number of anchor boxes
    final predictions = output[0]; // Shape: [29, 8400]

    // Transpose to iterate through each detection
    for (int i = 0; i < 8400; i++) {
      // Get bounding box coordinates (first 4 values)
      final cx = predictions[0][i];
      final cy = predictions[1][i];
      final w = predictions[2][i];
      final h = predictions[3][i];

      // Get class scores (indices 4-28 for 25 classes)
      List<double> classScores = [];
      for (int j = 4; j < 29; j++) {
        classScores.add(predictions[j][i]);
      }

      // Find class with highest score
      int maxClassIndex = 0;
      double maxScore = classScores[0];
      for (int j = 1; j < classScores.length; j++) {
        if (classScores[j] > maxScore) {
          maxScore = classScores[j];
          maxClassIndex = j;
        }
      }

      if (maxScore < confidenceThreshold) continue;

      // Convert from center format to corner format and scale to original image size
      final x = (cx - w / 2) * imgWidth / inputSize;
      final y = (cy - h / 2) * imgHeight / inputSize;
      final width = w * imgWidth / inputSize;
      final height = h * imgHeight / inputSize;

      // Get label safely
      String label;
      if (_labels != null && maxClassIndex >= 0 && maxClassIndex < _labels!.length) {
        label = _labels![maxClassIndex];
        print('✅ Detected class index $maxClassIndex: "$label" (confidence: ${(maxScore * 100).toStringAsFixed(1)}%)');
      } else {
        print('⚠️ Warning: Invalid class index $maxClassIndex. Labels length: ${_labels?.length ?? 0}');
        print('⚠️ Available labels: ${_labels?.take(5).join(", ") ?? "null"}...');
        label = 'Unknown snake (class $maxClassIndex)';
      }

      detections.add(DetectionResult(
        label: label,
        confidence: maxScore,
        x: x,
        y: y,
        width: width,
        height: height,
      ));
    }

    // Apply Non-Maximum Suppression (NMS)
    return _applyNMS(detections);
  }

  List<DetectionResult> _applyNMS(List<DetectionResult> detections) {
    if (detections.isEmpty) return [];

    // Sort by confidence
    detections.sort((a, b) => b.confidence.compareTo(a.confidence));

    List<DetectionResult> results = [];
    List<bool> suppressed = List.filled(detections.length, false);

    for (int i = 0; i < detections.length; i++) {
      if (suppressed[i]) continue;

      results.add(detections[i]);

      for (int j = i + 1; j < detections.length; j++) {
        if (suppressed[j]) continue;

        final iou = _calculateIOU(detections[i], detections[j]);
        if (iou > iouThreshold) {
          suppressed[j] = true;
        }
      }
    }

    return results;
  }

  double _calculateIOU(DetectionResult a, DetectionResult b) {
    final x1 = a.x.clamp(0.0, double.infinity);
    final y1 = a.y.clamp(0.0, double.infinity);
    final x2 = (a.x + a.width).clamp(0.0, double.infinity);
    final y2 = (a.y + a.height).clamp(0.0, double.infinity);

    final x1B = b.x.clamp(0.0, double.infinity);
    final y1B = b.y.clamp(0.0, double.infinity);
    final x2B = (b.x + b.width).clamp(0.0, double.infinity);
    final y2B = (b.y + b.height).clamp(0.0, double.infinity);

    final intersectX1 = x1 > x1B ? x1 : x1B;
    final intersectY1 = y1 > y1B ? y1 : y1B;
    final intersectX2 = x2 < x2B ? x2 : x2B;
    final intersectY2 = y2 < y2B ? y2 : y2B;

    final intersectArea = (intersectX2 - intersectX1).clamp(0.0, double.infinity) *
        (intersectY2 - intersectY1).clamp(0.0, double.infinity);

    final areaA = (x2 - x1) * (y2 - y1);
    final areaB = (x2B - x1B) * (y2B - y1B);

    final unionArea = areaA + areaB - intersectArea;

    return intersectArea / unionArea;
  }

  void dispose() {
    _interpreter?.close();
  }
}
