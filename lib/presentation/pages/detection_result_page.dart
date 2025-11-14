import 'dart:io';
import 'package:flutter/material.dart';
import 'package:venom_shield_ph/core/di/injection_container.dart';
import 'package:venom_shield_ph/domain/models/classification_report.dart';
import 'package:venom_shield_ph/domain/services/auth_service.dart';
import 'package:venom_shield_ph/domain/services/classification_db_service.dart';
import 'package:venom_shield_ph/domain/services/snake_info_service.dart';
import 'package:venom_shield_ph/domain/services/yolo_detector.dart';
import 'package:venom_shield_ph/presentation/widgets/safety_info_widget.dart';
import 'package:uuid/uuid.dart';

class DetectionResultPage extends StatefulWidget {
  final File imageFile;
  final List<DetectionResult> detections;

  const DetectionResultPage({
    super.key,
    required this.imageFile,
    required this.detections,
  });

  @override
  State<DetectionResultPage> createState() => _DetectionResultPageState();
}

class _DetectionResultPageState extends State<DetectionResultPage> {
  final SnakeInfoService _snakeInfoService = getIt<SnakeInfoService>();
  final ClassificationDbService _dbService = getIt<ClassificationDbService>();
  final AuthService _authService = getIt<AuthService>();

  bool _isSaving = false;
  bool _isSaved = false;
  Map<String, dynamic>? _snakeInfo;

  @override
  void initState() {
    super.initState();
    _loadSnakeInfoAndSave();
  }

  /// Extract scientific name from scientific_classification (handles both String and Map)
  String? _extractScientificName(dynamic scientificClassification) {
    if (scientificClassification == null) return null;
    if (scientificClassification is String) {
      return scientificClassification;
    }
    if (scientificClassification is Map<String, dynamic>) {
      return scientificClassification['scientific_name'] as String?;
    }
    return null;
  }

  Future<void> _loadSnakeInfoAndSave() async {
    if (widget.detections.isEmpty) return;

    // Get the best detection (highest confidence)
    final bestDetection = widget.detections.first;

    try {
      // Initialize snake info service if needed
      await _snakeInfoService.initialize();

      // Get snake info from results.json
      final snakeInfo = _snakeInfoService.getSnakeInfoByName(bestDetection.label);

      setState(() {
        _snakeInfo = snakeInfo;
      });

      // Automatically save the classification report
      await _saveClassificationReport(bestDetection, snakeInfo ?? {});
    } catch (e) {
      debugPrint('Error loading snake info: $e');
    }
  }

  Future<void> _saveClassificationReport(
    DetectionResult detection,
    Map<String, dynamic> snakeInfo,
  ) async {
    if (_isSaved || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final snakeId = _snakeInfoService.createSnakeId(detection.label);
      final report = ClassificationReport(
        id: const Uuid().v4(),
        userId: userId,
        snakeId: snakeId,
        snakeName: detection.label,
        scientificName: _extractScientificName(snakeInfo['scientific_classification']),
        confidence: detection.confidence,
        imageLocalPath: widget.imageFile.path,
        snakeInfo: snakeInfo,
        dateClassified: DateTime.now(),
        isSynced: false,
      );

      await _dbService.insertClassificationReport(report);

      if (mounted) {
        setState(() {
          _isSaved = true;
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Classification saved to history'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving classification: $e');
      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save classification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detection Results'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Image with bounding boxes (background)
          Container(
            color: Colors.black,
            child: Center(
              child: Stack(
                children: [
                  Image.file(
                    widget.imageFile,
                    fit: BoxFit.contain,
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: DetectionPainter(
                        imageFile: widget.imageFile,
                        detections: widget.detections,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Draggable detection results sheet
          DraggableScrollableSheet(
            initialChildSize: 0.4, // 40% of screen initially
            minChildSize: 0.2, // Minimum 20% of screen
            maxChildSize: 0.95, // Maximum 95% of screen (almost fullscreen)
            snap: true,
            snapSizes: const [0.4, 0.95], // Snap to 40% or 95%
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Drag handle
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Content
                    Expanded(
                      child: widget.detections.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.search_off,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No snakes detected',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Try taking another photo',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: widget.detections.length + 1, // +1 for safety widget
                              itemBuilder: (context, index) {
                                // Show safety widget after all detections
                                if (index == widget.detections.length) {
                                  return const SafetyInfoWidget();
                                }

                                final detection = widget.detections[index];
                                // Only show snake info for the first (best) detection
                                final showSnakeInfo = index == 0 && _snakeInfo != null;
                                return _buildDetectionCard(detection, index, showSnakeInfo);
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetectionCard(DetectionResult detection, int index, bool showSnakeInfo) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getConfidenceColor(detection.confidence),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Detection header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getConfidenceColor(detection.confidence)
                        .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: _getConfidenceColor(detection.confidence),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        detection.label,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_snakeInfo != null && showSnakeInfo) ...[
                        const SizedBox(height: 4),
                        Text(
                          _extractScientificName(_snakeInfo!['scientific_classification']) ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Confidence bar
            _buildConfidenceBar(detection.confidence),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Confidence',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  '${(detection.confidence * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _getConfidenceColor(detection.confidence),
                  ),
                ),
              ],
            ),

            // Snake info (only for best detection)
            if (showSnakeInfo) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              // Venom toxicity warning
              if (_snakeInfo!['venom_toxicity'] != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getVenomColor(_snakeInfo!['venom_toxicity'])
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getVenomColor(_snakeInfo!['venom_toxicity']),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_rounded,
                        color: _getVenomColor(_snakeInfo!['venom_toxicity']),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _snakeInfo!['venom_toxicity'],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _getVenomColor(_snakeInfo!['venom_toxicity']),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Description
              if (_snakeInfo!['description'] != null) ...[
                Text(
                  _snakeInfo!['description'],
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ],

            // Saved indicator
            if (index == 0 && _isSaved) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green.shade700,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Saved to history',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceBar(double confidence) {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: confidence,
        child: Container(
          decoration: BoxDecoration(
            color: _getConfidenceColor(confidence),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) {
      return Colors.green;
    } else if (confidence >= 0.6) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  Color _getVenomColor(String venomText) {
    final lowerVenom = venomText.toLowerCase();
    if (lowerVenom.contains('highly venomous') ||
        lowerVenom.contains('extremely venomous') ||
        lowerVenom.contains('deadly') ||
        lowerVenom.contains('fatal')) {
      return Colors.red;
    } else if (lowerVenom.contains('mildly venomous') ||
        lowerVenom.contains('not dangerous')) {
      return Colors.orange;
    } else if (lowerVenom.contains('non-venomous')) {
      return Colors.green;
    }
    return Colors.grey;
  }
}

class DetectionPainter extends CustomPainter {
  final File imageFile;
  final List<DetectionResult> detections;

  DetectionPainter({
    required this.imageFile,
    required this.detections,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (detections.isEmpty) return;

    for (var i = 0; i < detections.length; i++) {
      final detection = detections[i];

      // Create paint for bounding box
      final paint = Paint()
        ..color = _getConfidenceColor(detection.confidence)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      // Draw bounding box
      final rect = Rect.fromLTWH(
        detection.x,
        detection.y,
        detection.width,
        detection.height,
      );

      canvas.drawRect(rect, paint);

      // Draw label background
      final textSpan = TextSpan(
        // text: '${detection.label} ${(detection.confidence * 100).toStringAsFixed(0)}%',
        text: '',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      final labelRect = Rect.fromLTWH(
        detection.x,
        detection.y - textPainter.height - 8,
        textPainter.width + 12,
        textPainter.height + 8,
      );

      final labelPaint = Paint()
        ..color = _getConfidenceColor(detection.confidence);

      canvas.drawRect(labelRect, labelPaint);

      // Draw label text
      textPainter.paint(
        canvas,
        Offset(detection.x + 6, detection.y - textPainter.height - 4),
      );
    }
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) {
      return Colors.green;
    } else if (confidence >= 0.6) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
