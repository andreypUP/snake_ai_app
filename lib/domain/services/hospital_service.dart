import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import '../models/hospital.dart';

@singleton
class HospitalService {
  List<Hospital>? _cachedHospitals;

  /// Load all hospitals from JSON file
  Future<List<Hospital>> loadHospitals() async {
    if (_cachedHospitals != null) {
      print('📋 Returning cached hospitals: ${_cachedHospitals!.length}');
      return _cachedHospitals!;
    }

    try {
      print('📂 Loading hospitals from assets/data/hospitals.json...');
      final String jsonString =
          await rootBundle.loadString('assets/data/hospitals.json');
      print('📄 JSON loaded, length: ${jsonString.length} characters');

      final List<dynamic> jsonList = json.decode(jsonString);
      print('📋 Parsed JSON array with ${jsonList.length} items');

      _cachedHospitals = jsonList
          .map((json) => Hospital.fromJson(json as Map<String, dynamic>))
          .toList();

      print('✅ Loaded ${_cachedHospitals!.length} hospitals:');
      for (var hospital in _cachedHospitals!) {
        print('   🏥 ${hospital.name} (${hospital.latitude}, ${hospital.longitude})');
      }

      return _cachedHospitals!;
    } catch (e, stackTrace) {
      print('❌ Error loading hospitals: $e');
      print('📚 Stack trace: $stackTrace');
      return [];
    }
  }

  /// Find nearest hospital to given coordinates
  Hospital? findNearestHospital(double latitude, double longitude) {
    if (_cachedHospitals == null || _cachedHospitals!.isEmpty) {
      return null;
    }

    Hospital? nearest;
    double minDistance = double.infinity;

    for (var hospital in _cachedHospitals!) {
      final distance = _calculateDistance(
        latitude,
        longitude,
        hospital.latitude,
        hospital.longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
        nearest = hospital;
      }
    }

    return nearest;
  }

  /// Calculate distance between two coordinates (Haversine formula)
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_toRadians(lat1)) *
            _cos(_toRadians(lat2)) *
            _sin(dLon / 2) *
            _sin(dLon / 2);

    final c = 2 * _asin(_sqrt(a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * (3.141592653589793 / 180);
  double _sin(double x) => x - (x * x * x) / 6 + (x * x * x * x * x) / 120;
  double _cos(double x) => 1 - (x * x) / 2 + (x * x * x * x) / 24;
  double _sqrt(double x) {
    if (x < 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 10; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  double _asin(double x) {
    return x +
        (x * x * x) / 6 +
        (3 * x * x * x * x * x) / 40 +
        (15 * x * x * x * x * x * x * x) / 336;
  }
}
