import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:venom_shield_ph/core/di/injection_container.dart';
import 'package:venom_shield_ph/domain/models/classification_report.dart';
import 'package:venom_shield_ph/domain/services/classification_db_service.dart';
import 'package:venom_shield_ph/domain/services/snake_info_service.dart';
import 'package:venom_shield_ph/presentation/pages/create_snake_report_page.dart';
import 'package:venom_shield_ph/presentation/widgets/safety_info_widget.dart';

class ClassificationReportDetailPage extends StatefulWidget {
  final String reportId;

  const ClassificationReportDetailPage({
    super.key,
    required this.reportId,
  });

  @override
  State<ClassificationReportDetailPage> createState() => _ClassificationReportDetailPageState();
}

class _ClassificationReportDetailPageState extends State<ClassificationReportDetailPage> {
  final ClassificationDbService _dbService = getIt<ClassificationDbService>();
  final SnakeInfoService _snakeInfoService = getIt<SnakeInfoService>();
  ClassificationReport? _report;
  Map<String, dynamic>? _snakeInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Initialize snake info service
      await _snakeInfoService.initialize();

      ClassificationReport? report = await _dbService.getClassificationReportById(widget.reportId);

      // Always load snake info from results.json based on snake name
      Map<String, dynamic>? snakeInfoData;
      if (report != null) {
        debugPrint('🔍 Loading snake info for: "${report.snakeName}"');
        
        // First try to load from results.json
        snakeInfoData = _snakeInfoService.getSnakeInfoByName(report.snakeName);
        debugPrint('📊 Snake info found: ${snakeInfoData != null}');
        
        if (snakeInfoData != null && snakeInfoData.isNotEmpty) {
          debugPrint('✅ Snake info keys: ${snakeInfoData.keys.toList()}');
          debugPrint('✅ Snake info common_name: ${snakeInfoData['common_name']}');
          // Update the report with snake info
          report = report.copyWith(snakeInfo: snakeInfoData);
          // Save it back to the database
          await _dbService.updateClassificationReport(report);
        } else {
          debugPrint('❌ No snake info found for: "${report.snakeName}"');
          debugPrint('📋 Trying existing snakeInfo from report...');
          // Try to use existing snakeInfo from report if available
          if (report.snakeInfo.isNotEmpty) {
            debugPrint('✅ Using existing snakeInfo from report');
            snakeInfoData = report.snakeInfo;
          } else {
            debugPrint('❌ No existing snakeInfo in report either');
            debugPrint('📝 Report snakeInfo: ${report.snakeInfo}');
          }
        }
      }

      if (mounted) {
        setState(() {
          _report = report;
          _snakeInfo = snakeInfoData;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading report: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading report: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Classification Details'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: _report != null
          ? FloatingActionButton.extended(
              onPressed: () {
                // Navigate to snake report creation page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateSnakeReportPage(
                      classificationReport: _report!,
                    ),
                  ),
                );
              },
              backgroundColor: Colors.green,
              icon: const Icon(Icons.share_location, color: Colors.white),
              label: const Text(
                'Share to Community',
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : _report == null
              ? const Center(child: Text('Report not found'))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image
                      Container(
                        width: double.infinity,
                        height: 300,
                        color: Colors.grey.shade200,
                        child: Image.file(
                          File(_report!.imageLocalPath),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                Icons.image_not_supported,
                                size: 100,
                                color: Colors.grey.shade400,
                              ),
                            );
                          },
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Sync status badge
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _report!.isSynced
                                        ? Colors.green.shade100
                                        : Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _report!.isSynced
                                            ? Icons.cloud_done
                                            : Icons.cloud_off,
                                        size: 16,
                                        color: _report!.isSynced
                                            ? Colors.green.shade700
                                            : Colors.orange.shade700,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _report!.isSynced ? 'Synced' : 'Not Synced',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: _report!.isSynced
                                              ? Colors.green.shade700
                                              : Colors.orange.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Snake name
                            const Text(
                              'Snake Species',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _report!.snakeName,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            if (_report!.scientificName != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                _report!.scientificName!,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],

                            const SizedBox(height: 24),
                            const Divider(),
                            const SizedBox(height: 16),

                            // Confidence score
                            _buildInfoRow(
                              'Confidence',
                              '${(_report!.confidence * 100).toStringAsFixed(1)}%',
                              Icons.percent,
                            ),

                            const SizedBox(height: 16),

                            // Date classified
                            _buildInfoRow(
                              'Date Classified',
                              _formatDateTime(_report!.dateClassified),
                              Icons.calendar_today,
                            ),

                            const SizedBox(height: 24),
                            const Divider(),
                            const SizedBox(height: 16),

                            // Snake Information
                            Builder(
                              builder: (context) {
                                debugPrint('🎨 Building UI - _snakeInfo is null: ${_snakeInfo == null}');
                                if (_snakeInfo != null) {
                                  debugPrint('🎨 _snakeInfo.isEmpty: ${_snakeInfo!.isEmpty}');
                                  debugPrint('🎨 _snakeInfo keys: ${_snakeInfo!.keys.toList()}');
                                }
                                if (_report != null) {
                                  debugPrint('🎨 Report snakeName: ${_report!.snakeName}');
                                  debugPrint('🎨 Report snakeInfo isEmpty: ${_report!.snakeInfo.isEmpty}');
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                            // Always show snake information section if we have a snake name
                            if (_report != null) ...[
                              const Text(
                                'Snake Information',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (_snakeInfo != null && _snakeInfo!.isNotEmpty) ...[

                              // Description
                              if (_snakeInfo!['description'] != null) ...[
                                _buildInfoSection(
                                  'Description',
                                  _snakeInfo!['description'],
                                  Icons.info_outline,
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Venom Toxicity (Important!)
                              if (_snakeInfo!['venom_toxicity'] != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: _getVenomColor(_snakeInfo!['venom_toxicity'])
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _getVenomColor(_snakeInfo!['venom_toxicity']),
                                      width: 2,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.warning,
                                            color: _getVenomColor(_snakeInfo!['venom_toxicity']),
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            'Venom Toxicity',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _snakeInfo!['venom_toxicity'],
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Geographic Range
                              if (_snakeInfo!['geographic_range'] != null) ...[
                                _buildInfoSection(
                                  'Geographic Range',
                                  _snakeInfo!['geographic_range'],
                                  Icons.public,
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Habitat
                              if (_snakeInfo!['habitat'] != null) ...[
                                _buildInfoSection(
                                  'Habitat',
                                  _snakeInfo!['habitat'],
                                  Icons.landscape,
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Behavior
                              if (_snakeInfo!['behavior'] != null) ...[
                                _buildInfoSection(
                                  'Behavior',
                                  _snakeInfo!['behavior'],
                                  Icons.psychology,
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Diet
                              if (_snakeInfo!['diet'] != null) ...[
                                _buildInfoSection(
                                  'Diet',
                                  _snakeInfo!['diet'],
                                  Icons.restaurant,
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Conservation Status
                              if (_snakeInfo!['conservation_status'] != null) ...[
                                _buildInfoSection(
                                  'Conservation Status',
                                  _snakeInfo!['conservation_status'],
                                  Icons.eco,
                                ),
                                const SizedBox(height: 16),
                              ],

                              const Divider(),
                              const SizedBox(height: 16),
                              ] else ...[
                                // Show message if snake info not found
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.orange.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.info_outline, color: Colors.orange.shade700),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Snake information not found for "${_report!.snakeName}". Please check the debug console for details.',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.orange.shade900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ],

                            // Safety Information
                            const SafetyInfoWidget(),
                            const SizedBox(height: 24),

                            // Additional information
                            const Text(
                              'Classification Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'This classification was performed using AI-powered snake detection. '
                              'The confidence score indicates how certain the model is about this identification.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                                height: 1.5,
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

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.green),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDateTime(DateTime date) {
    return '${_getMonthName(date.month)} ${date.day}, ${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  Widget _buildInfoSection(String title, String content, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.green),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
            height: 1.5,
          ),
        ),
      ],
    );
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
