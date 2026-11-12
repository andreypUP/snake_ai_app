import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:venom_shield_ph/core/constants/mapbox_constants.dart';

@singleton
class MapboxService {
  // Geocoding - Search for places
  Future<List<MapboxSearchResult>> searchLocation(String query) async {
    if (query.isEmpty) return [];

    try {
      final url = Uri.parse(
        'https://api.mapbox.com/geocoding/v5/mapbox.places/${Uri.encodeComponent(query)}.json'
        '?access_token=${MapboxConstants.accessToken}'
        '&country=PH' // Limit to Philippines
        '&limit=5'
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final features = data['features'] as List;

        return features.map((feature) {
          final coordinates = feature['geometry']['coordinates'] as List;
          return MapboxSearchResult(
            placeName: feature['place_name'] as String,
            longitude: coordinates[0] as double,
            latitude: coordinates[1] as double,
          );
        }).toList();
      } else {
        print('❌ Geocoding error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error searching location: $e');
      return [];
    }
  }

  // Directions - Get route between two points
  Future<MapboxRoute?> getRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    try {
      final url = Uri.parse(
        'https://api.mapbox.com/directions/v5/mapbox/driving/'
        '$startLng,$startLat;$endLng,$endLat'
        '?access_token=${MapboxConstants.accessToken}'
        '&geometries=geojson'
        '&overview=full'
        '&steps=true'
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final routes = data['routes'] as List;

        if (routes.isEmpty) return null;

        final route = routes.first;
        final geometry = route['geometry'];
        final coordinates = (geometry['coordinates'] as List)
            .map((coord) => RoutePoint(
                  longitude: coord[0] as double,
                  latitude: coord[1] as double,
                ))
            .toList();

        return MapboxRoute(
          coordinates: coordinates,
          distance: route['distance'] as double, // in meters
          duration: route['duration'] as double, // in seconds
        );
      } else {
        print('❌ Directions error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error getting route: $e');
      return null;
    }
  }
}

class MapboxSearchResult {
  final String placeName;
  final double longitude;
  final double latitude;

  MapboxSearchResult({
    required this.placeName,
    required this.longitude,
    required this.latitude,
  });
}

class MapboxRoute {
  final List<RoutePoint> coordinates;
  final double distance; // meters
  final double duration; // seconds

  MapboxRoute({
    required this.coordinates,
    required this.distance,
    required this.duration,
  });

  String get distanceText {
    if (distance < 1000) {
      return '${distance.toStringAsFixed(0)} m';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)} km';
    }
  }

  String get durationText {
    final minutes = (duration / 60).round();
    if (minutes < 60) {
      return '$minutes min';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '$hours hr $remainingMinutes min';
    }
  }
}

class RoutePoint {
  final double longitude;
  final double latitude;

  RoutePoint({
    required this.longitude,
    required this.latitude,
  });
}
