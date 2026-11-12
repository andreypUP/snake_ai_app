import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

@singleton
class SnakeInfoService {
  Map<String, dynamic>? _snakesData;
  List<dynamic>? _snakesList;

  Future<void> initialize() async {
    if (_snakesData != null) return;

    try {
      final String jsonString =
          await rootBundle.loadString('lib/data/datasources/results.json');
      _snakesData = jsonDecode(jsonString);
      _snakesList = _snakesData!['snakes'] as List<dynamic>;
    } catch (e) {
      print('Error loading snake data: $e');
      _snakesData = {'snakes': []};
      _snakesList = [];
    }
  }

  /// Normalize a name for matching (remove spaces, underscores, make lowercase)
  String _normalizeName(String name) {
    return name
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('_', '')
        .replaceAll("'", '')
        .trim();
  }

  /// Get snake names from an entry (handles both common_name and common_names)
  /// Also splits comma-separated names
  List<String> _getSnakeNames(dynamic snake) {
    final List<String> names = [];
    
    // Handle common_name (singular) - may contain comma-separated names
    if (snake['common_name'] != null) {
      final name = snake['common_name'];
      if (name is String) {
        // Split by comma and add each name
        final splitNames = name.split(',').map((n) => n.trim()).where((n) => n.isNotEmpty);
        names.addAll(splitNames);
      }
    }
    
    // Handle common_names (plural array)
    if (snake['common_names'] != null) {
      final namesList = snake['common_names'];
      if (namesList is List) {
        for (var name in namesList) {
          if (name is String) {
            names.add(name.trim());
          }
        }
      }
    }
    
    return names;
  }

  /// Get snake info by common name (flexible matching)
  Map<String, dynamic>? getSnakeInfoByName(String commonName) {
    if (_snakesList == null) return null;

    try {
      final normalizedInput = _normalizeName(commonName);
      print('Looking for snake: "$commonName" (normalized: "$normalizedInput")');

      // Try to find matching snake
      dynamic snake;
      
      // First, try exact match (case-insensitive) with all possible names
      try {
        snake = _snakesList!.firstWhere(
          (snake) {
            final names = _getSnakeNames(snake);
            return names.any((name) => 
              name.toLowerCase().trim() == commonName.toLowerCase().trim()
            );
          },
          orElse: () => null,
        );
      } catch (e) {
        print('Error in exact match: $e');
      }

      // If not found, try normalized matching
      if (snake == null) {
        print('Exact match not found, trying normalized matching...');
        try {
          snake = _snakesList!.firstWhere(
            (snake) {
              final names = _getSnakeNames(snake);
              return names.any((name) {
                final normalizedName = _normalizeName(name);
                final matches = normalizedName == normalizedInput ||
                       normalizedName.contains(normalizedInput) ||
                       normalizedInput.contains(normalizedName);
                if (matches) {
                  print('Found match: "$name" matches "$commonName"');
                }
                return matches;
              });
            },
            orElse: () => null,
          );
        } catch (e) {
          print('Error in normalized match: $e');
        }
      } else {
        final names = _getSnakeNames(snake);
        print('Found exact match: "${names.first}"');
      }

      if (snake == null) {
        print('No match found for "$commonName"');
        final availableNames = _snakesList!.expand((s) => _getSnakeNames(s)).toList();
        print('Available snakes: ${availableNames.take(10).join(', ')}${availableNames.length > 10 ? '...' : ''}');
      }

      return snake != null ? Map<String, dynamic>.from(snake) : null;
    } catch (e) {
      print('Error finding snake "$commonName": $e');
      return null;
    }
  }

  /// Get snake info by scientific name
  Map<String, dynamic>? getSnakeInfoByScientificName(String scientificName) {
    if (_snakesList == null) return null;

    try {
      final snake = _snakesList!.firstWhere(
        (snake) => (snake['scientific_classification'] as String)
            .toLowerCase()
            .trim() ==
            scientificName.toLowerCase().trim(),
        orElse: () => null,
      );
      return snake != null ? Map<String, dynamic>.from(snake) : null;
    } catch (e) {
      return null;
    }
  }

  /// Get all snakes
  List<Map<String, dynamic>> getAllSnakes() {
    if (_snakesList == null) return [];
    return _snakesList!
        .map((snake) => Map<String, dynamic>.from(snake))
        .toList();
  }

  /// Create a snake ID from the common name (for consistency)
  String createSnakeId(String commonName) {
    return commonName
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
  }
}
