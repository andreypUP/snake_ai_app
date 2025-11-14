import 'package:flutter/material.dart';
import 'package:venom_shield_ph/core/di/injection_container.dart';
import 'package:venom_shield_ph/domain/services/snake_info_service.dart';
import 'package:venom_shield_ph/routes.dart';

class SnakeClassListPage extends StatefulWidget {
  const SnakeClassListPage({super.key});

  @override
  State<SnakeClassListPage> createState() => _SnakeClassListPageState();
}

class _SnakeClassListPageState extends State<SnakeClassListPage> {
  final SnakeInfoService _snakeInfoService = getIt<SnakeInfoService>();
  List<Map<String, dynamic>> _snakes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSnakes();
  }

  Future<void> _loadSnakes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _snakeInfoService.initialize();
      final snakes = _snakeInfoService.getAllSnakes();

      if (mounted) {
        setState(() {
          _snakes = snakes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading snake classes: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Snake Classes'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : _snakes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.pets,
                        size: 100,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No snake classes found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadSnakes,
                  color: Colors.green,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: _snakes.map((snake) => _buildSnakeCard(snake)).toList(),
                    ),
                  ),
                ),
    );
  }

  Widget _buildSnakeCard(Map<String, dynamic> snake) {
    final String commonName = (snake['common_name'] is String) ? snake['common_name'] : 'Unknown';
    final String scientificName = (snake['scientific_classification'] is String) ? snake['scientific_classification'] : '';
    final String venomToxicity = (snake['venom_toxicity'] is String) ? snake['venom_toxicity'] : '';
    final String description = (snake['description'] is String) ? snake['description'] : '';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          final snakeId = _snakeInfoService.createSnakeId(commonName);
          SnakeClassDetailPageRoute(snakeId: snakeId).push(context);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Snake name
              Text(
                commonName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (scientificName.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  scientificName,
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              // Description
              if (description.isNotEmpty) ...[
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade800,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
              ],
              // Venom toxicity badge
              if (venomToxicity.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getVenomColor(venomToxicity).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getVenomColor(venomToxicity),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning,
                        size: 16,
                        color: _getVenomColor(venomToxicity),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          venomToxicity,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getVenomColor(venomToxicity),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
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
