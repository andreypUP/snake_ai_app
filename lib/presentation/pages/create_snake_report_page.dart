import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:venom_shield_ph/core/di/injection_container.dart';
import 'package:venom_shield_ph/domain/models/classification_report.dart';
import 'package:venom_shield_ph/domain/models/snake_report.dart';
import 'package:venom_shield_ph/domain/services/auth_service.dart';
import 'package:venom_shield_ph/domain/services/snake_report_service.dart';
import 'package:venom_shield_ph/presentation/pages/map_location_picker_page.dart';

class CreateSnakeReportPage extends StatefulWidget {
  final ClassificationReport classificationReport;

  const CreateSnakeReportPage({
    super.key,
    required this.classificationReport,
  });

  @override
  State<CreateSnakeReportPage> createState() => _CreateSnakeReportPageState();
}

class _CreateSnakeReportPageState extends State<CreateSnakeReportPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _picker = ImagePicker();

  final SnakeReportService _reportService = getIt<SnakeReportService>();
  final AuthService _authService = getIt<AuthService>();

  List<File> _additionalImages = [];
  double? _latitude;
  double? _longitude;
  String? _locationName;
  bool _isSubmitting = false;

  static const int maxImages = 5;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => MapLocationPickerPage(
          initialLatitude: _latitude,
          initialLongitude: _longitude,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _latitude = result['latitude'];
        _longitude = result['longitude'];
        _locationName = result['locationName'];
      });
    }
  }

  Future<void> _pickImages(ImageSource source) async {
    if (_additionalImages.length >= maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum of $maxImages images allowed'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      if (source == ImageSource.camera) {
        final XFile? image = await _picker.pickImage(source: source);
        if (image != null) {
          setState(() {
            _additionalImages.add(File(image.path));
          });
        }
      } else {
        final List<XFile> images = await _picker.pickMultiImage();
        final remaining = maxImages - _additionalImages.length;

        if (images.length > remaining) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You can only add $remaining more image(s)'),
              backgroundColor: Colors.orange,
            ),
          );
        }

        setState(() {
          _additionalImages.addAll(
            images.take(remaining).map((xfile) => File(xfile.path)),
          );
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking images: $e')),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _additionalImages.removeAt(index);
    });
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.green),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImages(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImages(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a location on the map'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      print('🐍 Creating snake report...');
      print('   Converting and compressing images...');

      // Convert and compress main image from classification report
      final mainImageFile = File(widget.classificationReport.imageLocalPath);
      final mainImageBase64List = await _reportService.convertImagesToBase64([mainImageFile]);

      if (mainImageBase64List.isEmpty) {
        throw Exception('Failed to compress main image');
      }

      // Convert and compress additional images
      final additionalImagesBase64 = await _reportService.convertImagesToBase64(_additionalImages);

      // Combine all images
      final allImages = [mainImageBase64List.first, ...additionalImagesBase64];

      print('   Total images: ${allImages.length}');

      // Calculate total size
      int totalSize = 0;
      for (var img in allImages) {
        totalSize += img.length;
      }
      print('   Total data size: ${(totalSize / 1024).toStringAsFixed(2)} KB');

      // Determine if venomous
      final venomText = widget.classificationReport.snakeInfo['venom_toxicity']?.toString().toLowerCase() ?? '';
      final isVenomous = venomText.contains('venomous') && !venomText.contains('non-venomous');

      // Create snake report
      final report = SnakeReport(
        id: const Uuid().v4(),
        userId: user.uid,
        userName: user.displayName ?? user.email ?? 'Anonymous',
        classificationReportId: widget.classificationReport.id,
        snakeName: widget.classificationReport.snakeName,
        scientificName: widget.classificationReport.scientificName,
        confidence: widget.classificationReport.confidence,
        isVenomous: isVenomous,
        venomToxicity: widget.classificationReport.snakeInfo['venom_toxicity'],
        description: _descriptionController.text.trim(),
        imageBase64List: allImages,
        locationName: _locationName,
        latitude: _latitude!,
        longitude: _longitude!,
        snakeInfo: widget.classificationReport.snakeInfo,
        createdAt: DateTime.now(),
      );

      print('   Uploading to Firestore...');
      await _reportService.createSnakeReport(report);

      print('✅ Snake report created successfully!');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Snake report shared to community! 🎉'),
            backgroundColor: Colors.green,
          ),
        );

        // Go back twice (to detail page, then list)
        Navigator.pop(context);
        Navigator.pop(context);
      }
    } catch (e, stackTrace) {
      print('❌ Error creating snake report: $e');
      print('   Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Snake Report'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isSubmitting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.green),
                  SizedBox(height: 16),
                  Text('Sharing to community...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Snake Info Card
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Snake Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              'Species',
                              widget.classificationReport.snakeName,
                            ),
                            if (widget.classificationReport.scientificName != null)
                              _buildInfoRow(
                                'Scientific Name',
                                widget.classificationReport.scientificName!,
                              ),
                            _buildInfoRow(
                              'Confidence',
                              '${(widget.classificationReport.confidence * 100).toStringAsFixed(1)}%',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Location Section
                    const Text(
                      'Location *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 2,
                      child: InkWell(
                        onTap: _pickLocation,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: _latitude != null ? Colors.green : Colors.grey,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _latitude != null
                                          ? 'Location Selected'
                                          : 'Tap to select location',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: _latitude != null
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    if (_latitude != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Lat: ${_latitude!.toStringAsFixed(6)}\nLong: ${_longitude!.toStringAsFixed(6)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Description Section
                    const Text(
                      'Description (Optional)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      maxLength: 500,
                      decoration: InputDecoration(
                        hintText: 'Add any additional details about the sighting...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.green, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Additional Images Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Additional Photos',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_additionalImages.length}/$maxImages',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Add Images Button
                    if (_additionalImages.length < maxImages)
                      OutlinedButton.icon(
                        onPressed: _showImageSourceDialog,
                        icon: const Icon(Icons.add_photo_alternate),
                        label: const Text('Add Photos'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                          side: const BorderSide(color: Colors.green),
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),

                    // Images Grid
                    if (_additionalImages.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _additionalImages.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _additionalImages[index],
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submitReport,
                        icon: const Icon(Icons.share_location, color: Colors.white),
                        label: const Text(
                          'Share to Community',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Info text
                    Text(
                      'Your report will be visible to all users on the community map.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
