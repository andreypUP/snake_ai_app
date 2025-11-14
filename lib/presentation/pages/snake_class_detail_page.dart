import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:venom_shield_ph/core/di/injection_container.dart';
import 'package:venom_shield_ph/domain/services/snake_info_service.dart';
import 'package:venom_shield_ph/presentation/widgets/safety_info_widget.dart';
import 'package:octo_image/octo_image.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SnakeClassDetailPage extends StatefulWidget {
  final String snakeId;

  const SnakeClassDetailPage({
    super.key,
    required this.snakeId,
  });

  @override
  State<SnakeClassDetailPage> createState() => _SnakeClassDetailPageState();
}

class _SnakeClassDetailPageState extends State<SnakeClassDetailPage> {
  final SnakeInfoService _snakeInfoService = getIt<SnakeInfoService>();
  Map<String, dynamic>? _snakeInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSnakeInfo();
  }

  Future<void> _loadSnakeInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _snakeInfoService.initialize();

      // Get all snakes and find the one with matching ID
      final allSnakes = _snakeInfoService.getAllSnakes();
      final snake = allSnakes.firstWhere(
        (s) {
          final commonName = s['common_name'] ?? '';
          final id = _snakeInfoService.createSnakeId(commonName);
          return id == widget.snakeId;
        },
        orElse: () => {},
      );

      if (mounted) {
        setState(() {
          _snakeInfo = snake.isNotEmpty ? snake : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading snake info: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading snake information: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Snake Details'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : _snakeInfo == null
              ? const Center(child: Text('Snake information not found'))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                          (_snakeInfo!['common_name'] is String) ? _snakeInfo!['common_name'] : 'Unknown',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        if (_snakeInfo!['scientific_classification'] != null && _snakeInfo!['scientific_classification'] is String) ...[
                          const SizedBox(height: 8),
                          Text(
                            _snakeInfo!['scientific_classification'],
                            style: TextStyle(
                              fontSize: 18,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Image gallery
                        if (_snakeInfo!['image_links'] != null && _snakeInfo!['image_links'] is List) ...[
                          SizedBox(
                            height: 200,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: (_snakeInfo!['image_links'] as List).length,
                              itemBuilder: (context, index) {
                                final imageUrl = (_snakeInfo!['image_links'] as List)[index].toString();
                                return Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: SizedBox(
                                      width: 200,
                                      child: OctoImage(
                                        image: CachedNetworkImageProvider(imageUrl),
                                        placeholderBuilder: (context) => Container(
                                          color: Colors.grey[200],
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              color: Colors.green,
                                            ),
                                          ),
                                        ),
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          color: Colors.grey[300],
                                          child: const Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.broken_image,
                                                size: 48,
                                                color: Colors.grey,
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                'Image not available',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        const Divider(),
                        const SizedBox(height: 16),

                        // Snake Information
                        const Text(
                          'Snake Information',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Description
                        if (_snakeInfo!['description'] != null && _snakeInfo!['description'] is String) ...[
                          _buildInfoSection(
                            'Description',
                            _snakeInfo!['description'],
                            Icons.info_outline,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Venom Toxicity (Important!)
                        if (_snakeInfo!['venom_toxicity'] != null && _snakeInfo!['venom_toxicity'] is String) ...[
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
                        if (_snakeInfo!['geographic_range'] != null && _snakeInfo!['geographic_range'] is String) ...[
                          _buildInfoSection(
                            'Geographic Range',
                            _snakeInfo!['geographic_range'],
                            Icons.public,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Habitat
                        if (_snakeInfo!['habitat'] != null && _snakeInfo!['habitat'] is String) ...[
                          _buildInfoSection(
                            'Habitat',
                            _snakeInfo!['habitat'],
                            Icons.landscape,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Behavior
                        if (_snakeInfo!['behavior'] != null && _snakeInfo!['behavior'] is String) ...[
                          _buildInfoSection(
                            'Behavior',
                            _snakeInfo!['behavior'],
                            Icons.psychology,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Diet
                        if (_snakeInfo!['diet'] != null && _snakeInfo!['diet'] is String) ...[
                          _buildInfoSection(
                            'Diet',
                            _snakeInfo!['diet'],
                            Icons.restaurant,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Reproduction
                        if (_snakeInfo!['reproduction'] != null && _snakeInfo!['reproduction'] is String) ...[
                          _buildInfoSection(
                            'Reproduction',
                            _snakeInfo!['reproduction'],
                            Icons.favorite,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Lifespan
                        if (_snakeInfo!['lifespan'] != null && _snakeInfo!['lifespan'] is String) ...[
                          _buildInfoSection(
                            'Lifespan',
                            _snakeInfo!['lifespan'],
                            Icons.access_time,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Conservation Status
                        if (_snakeInfo!['conservation_status'] != null && _snakeInfo!['conservation_status'] is String) ...[
                          _buildInfoSection(
                            'Conservation Status',
                            _snakeInfo!['conservation_status'],
                            Icons.eco,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // References
                        if (_snakeInfo!['references'] != null) ...[
                          const Divider(),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.link, size: 20, color: Colors.green),
                              const SizedBox(width: 8),
                              const Text(
                                'References',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...(_snakeInfo!['references'] as List).map((ref) => Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Text(
                                  ref.toString(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.blue.shade700,
                                    decoration: TextDecoration.underline,
                                    height: 1.5,
                                  ),
                                ),
                              )),
                          const SizedBox(height: 16),
                        ],

                        const Divider(),
                        const SizedBox(height: 16),

                        // Safety Information
                        const SafetyInfoWidget(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
    );
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
    // All venomous snakes (regardless of toxicity level) should be red
    if (lowerVenom.contains('venomous') && !lowerVenom.contains('non-venomous')) {
      return Colors.red;
    } else if (lowerVenom.contains('risk') && !lowerVenom.contains('no risk')) {
      return Colors.red;
    } else if (lowerVenom.contains('non-venomous') ||
        lowerVenom.contains('none') ||
        lowerVenom.contains('no risk')) {
      return Colors.green;
    }
    return Colors.grey;
  }
}
