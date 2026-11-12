import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SafetyInfoWidget extends StatefulWidget {
  const SafetyInfoWidget({super.key});

  @override
  State<SafetyInfoWidget> createState() => _SafetyInfoWidgetState();
}

class _SafetyInfoWidgetState extends State<SafetyInfoWidget> {
  Map<String, dynamic>? _safetyData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSafetyData();
  }

  Future<void> _loadSafetyData() async {
    try {
      final String jsonString =
          await rootBundle.loadString('lib/data/datasources/safety.json');
      setState(() {
        _safetyData = jsonDecode(jsonString);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading safety data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 50,
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_safetyData == null) {
      return const SizedBox.shrink();
    }

    final sections = _safetyData!['sections'] as Map<String, dynamic>;
    final title = _safetyData!['title'] as String;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.shade200,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red.shade700,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Signs and Symptoms
            if (sections['signs_and_symptoms'] != null) ...[
              _buildSectionTitle('Signs and Symptoms'),
              const SizedBox(height: 8),
              if (sections['signs_and_symptoms']['description'] != null) ...[
                Text(
                  sections['signs_and_symptoms']['description'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (sections['signs_and_symptoms']['list'] != null) ...[
                ...(sections['signs_and_symptoms']['list'] as List)
                    .map((item) => _buildListItem(item)),
                const SizedBox(height: 16),
              ],
            ],

            // Treatment
            if (sections['treatment'] != null) ...[
              _buildSectionTitle('First Aid Treatment'),
              const SizedBox(height: 8),
              if (sections['treatment']['description'] != null) ...[
                Text(
                  sections['treatment']['description'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (sections['treatment']['steps'] != null) ...[
                ...(sections['treatment']['steps'] as List)
                    .asMap()
                    .entries
                    .map((entry) => _buildNumberedItem(entry.value, entry.key + 1)),
                const SizedBox(height: 16),
              ],
            ],

            // Don'ts
            if (sections['donts'] != null) ...[
              _buildSectionTitle('Important Don\'ts'),
              const SizedBox(height: 8),
              if (sections['donts']['list'] != null) ...[
                ...(sections['donts']['list'] as List)
                    .map((item) => _buildDonItem(item)),
                const SizedBox(height: 16),
              ],
            ],

            // References
            if (sections['reference'] != null &&
                sections['reference']['sources'] != null) ...[
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'References',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              ...(sections['reference']['sources'] as List)
                  .map((source) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '• $source',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.red.shade900,
      ),
    );
  }

  Widget _buildListItem(String item) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              item,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade800,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberedItem(String item, int number) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.red.shade700,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade800,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonItem(String item) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.close,
            size: 18,
            color: Colors.red.shade700,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade800,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

