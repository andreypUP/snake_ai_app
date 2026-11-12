import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:venom_shield_ph/domain/models/snake_report.dart';

class SnakeReportDetailPage extends StatefulWidget {
  final SnakeReport report;

  const SnakeReportDetailPage({
    super.key,
    required this.report,
  });

  @override
  State<SnakeReportDetailPage> createState() => _SnakeReportDetailPageState();
}

class _SnakeReportDetailPageState extends State<SnakeReportDetailPage> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Snake Report Details'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image carousel
            _buildImageCarousel(),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Snake name and scientific name
                  Text(
                    widget.report.snakeName,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.report.scientificName != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.report.scientificName!,
                      style: TextStyle(
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Venom status card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: widget.report.isVenomous
                          ? Colors.red.shade50
                          : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: widget.report.isVenomous
                            ? Colors.red.shade300
                            : Colors.green.shade300,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          widget.report.isVenomous
                              ? Icons.warning_rounded
                              : Icons.check_circle_rounded,
                          color: widget.report.isVenomous
                              ? Colors.red.shade700
                              : Colors.green.shade700,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.report.isVenomous
                                    ? 'VENOMOUS SNAKE'
                                    : 'NON-VENOMOUS SNAKE',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: widget.report.isVenomous
                                      ? Colors.red.shade900
                                      : Colors.green.shade900,
                                ),
                              ),
                              if (widget.report.venomToxicity != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  widget.report.venomToxicity!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: widget.report.isVenomous
                                        ? Colors.red.shade800
                                        : Colors.green.shade800,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Stats row
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.percent,
                          label: 'Confidence',
                          value:
                              '${(widget.report.confidence * 100).toStringAsFixed(1)}%',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.calendar_today,
                          label: 'Date',
                          value: DateFormat('MMM dd, yyyy')
                              .format(widget.report.createdAt),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Location section
                  _buildSection(
                    icon: Icons.location_on,
                    title: 'Location',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.report.locationName != null) ...[
                          Text(
                            widget.report.locationName!,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                        ],
                        Text(
                          'Lat: ${widget.report.latitude.toStringAsFixed(6)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Text(
                          'Long: ${widget.report.longitude.toStringAsFixed(6)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Reporter section
                  _buildSection(
                    icon: Icons.person,
                    title: 'Reported By',
                    child: Text(
                      widget.report.userName ?? 'Anonymous',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),

                  // Description section
                  if (widget.report.description != null &&
                      widget.report.description!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildSection(
                      icon: Icons.description,
                      title: 'Description',
                      child: Text(
                        widget.report.description!,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                    ),
                  ],

                  // Snake info section
                  if (widget.report.snakeInfo.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildSection(
                      icon: Icons.info_outline,
                      title: 'Snake Information',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow('Scientific Classification',
                              widget.report.snakeInfo['scientific_classification']),
                          _buildInfoRow(
                              'Family', widget.report.snakeInfo['family']),
                          _buildInfoRow(
                              'Habitat', widget.report.snakeInfo['habitat']),
                          _buildInfoRow('Geographic Range',
                              widget.report.snakeInfo['geographic_range']),
                          _buildInfoRow(
                              'Diet', widget.report.snakeInfo['diet']),
                          _buildInfoRow('Physical Characteristics',
                              widget.report.snakeInfo['physical_characteristics']),
                          _buildInfoRow('Behavior',
                              widget.report.snakeInfo['behavior']),
                          _buildInfoRow('Conservation Status',
                              widget.report.snakeInfo['conservation_status']),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCarousel() {
    // Decode all images
    List<Uint8List?> images = [];
    for (var base64Image in widget.report.imageBase64List) {
      try {
        images.add(base64Decode(base64Image));
      } catch (e) {
        print('❌ Error decoding image: $e');
        images.add(null);
      }
    }

    return SizedBox(
      height: 300,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: images.length,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final imageBytes = images[index];
              if (imageBytes != null) {
                return Image.memory(
                  imageBytes,
                  width: double.infinity,
                  height: 300,
                  fit: BoxFit.cover,
                );
              } else {
                return Container(
                  color: Colors.grey.shade300,
                  child: Center(
                    child: Icon(
                      Icons.image_not_supported,
                      size: 64,
                      color: Colors.grey.shade500,
                    ),
                  ),
                );
              }
            },
          ),

          // Image counter
          if (images.length > 1)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentImageIndex + 1}/${images.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          // Navigation arrows
          if (images.length > 1) ...[
            // Left arrow
            if (_currentImageIndex > 0)
              Positioned(
                left: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios),
                    color: Colors.white,
                    iconSize: 32,
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withOpacity(0.5),
                    ),
                  ),
                ),
              ),

            // Right arrow
            if (_currentImageIndex < images.length - 1)
              Positioned(
                right: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    icon: const Icon(Icons.arrow_forward_ios),
                    color: Colors.white,
                    iconSize: 32,
                    onPressed: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.green.shade700, size: 24),
          const SizedBox(height: 8),
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
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.green.shade700, size: 24),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    if (value == null || value.toString().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.toString(),
            style: const TextStyle(fontSize: 15, height: 1.4),
          ),
        ],
      ),
    );
  }
}
