import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:venom_shield_ph/core/constants/mapbox_constants.dart';
import 'package:venom_shield_ph/core/di/injection_container.dart';
import 'package:venom_shield_ph/domain/models/hospital.dart';
import 'package:venom_shield_ph/domain/models/snake_report.dart';
import 'package:venom_shield_ph/domain/services/hospital_service.dart';
import 'package:venom_shield_ph/domain/services/mapbox_service.dart';
import 'package:venom_shield_ph/domain/services/snake_report_service.dart';
import 'package:venom_shield_ph/presentation/pages/snake_report_detail_page.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final SnakeReportService _reportService = getIt<SnakeReportService>();
  final MapboxService _mapboxService = getIt<MapboxService>();
  final HospitalService _hospitalService = getIt<HospitalService>();
  final TextEditingController _searchController = TextEditingController();

  MapboxMap? _mapboxMap;
  PointAnnotationManager? _pointAnnotationManager;
  PolylineAnnotationManager? _polylineAnnotationManager;
  List<PointAnnotation> _markers = [];
  Map<String, SnakeReport> _markerReports = {};
  List<PointAnnotation> _hospitalMarkers = [];
  Map<String, Hospital> _markerHospitals = {};
  PointAnnotation? _currentLocationMarker;
  PolylineAnnotation? _routeLine;
  geo.Position? _currentPosition;
  List<SnakeReport> _snakeReports = [];
  List<Hospital> _hospitals = [];
  List<MapboxSearchResult> _searchResults = [];
  MapboxRoute? _currentRoute;
  bool _showSnakeReports = true;
  bool _showHospitals = false;
  bool _isLoading = true;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    MapboxOptions.setAccessToken(MapboxConstants.accessToken);
    _loadSnakeReports();
    _loadHospitals();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pointAnnotationManager = null;
    _polylineAnnotationManager = null;
    _mapboxMap = null;
    super.dispose();
  }

  Future<void> _loadSnakeReports() async {
    try {
      final reports = await _reportService.getAllSnakeReports();
      setState(() {
        _snakeReports = reports;
        _isLoading = false;
      });

      // Add markers if map is ready
      if (_mapboxMap != null && _showSnakeReports) {
        await _addSnakeReportMarkers();
      }
    } catch (e) {
      print('❌ Error loading snake reports: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadHospitals() async {
    try {
      final hospitals = await _hospitalService.loadHospitals();
      setState(() {
        _hospitals = hospitals;
      });

      // Add markers if map is ready
      if (_mapboxMap != null && _showHospitals) {
        await _addHospitalMarkers();
      }
    } catch (e) {
      print('❌ Error loading hospitals: $e');
    }
  }

  // Get current location
  Future<void> _getCurrentLocation() async {
    try {
      print('🔍 Checking location services...');
      bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('⚠️  Location services are disabled');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enable location services in your device settings'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      print('🔍 Checking location permissions...');
      geo.LocationPermission permission = await geo.Geolocator.checkPermission();
      print('📍 Permission status: $permission');

      if (permission == geo.LocationPermission.denied) {
        print('🔐 Requesting location permission...');
        permission = await geo.Geolocator.requestPermission();
        if (permission == geo.LocationPermission.denied) {
          print('⚠️  Location permissions denied');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission is required to find nearby hospitals'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 4),
              ),
            );
          }
          return;
        }
      }

      if (permission == geo.LocationPermission.deniedForever) {
        print('⚠️  Location permissions permanently denied');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enable location permissions in app settings'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Settings',
                textColor: Colors.white,
                onPressed: geo.Geolocator.openLocationSettings,
              ),
            ),
          );
        }
        return;
      }

      print('📍 Getting current position...');
      final position = await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      print('✅ Current location: ${position.latitude}, ${position.longitude}');

      setState(() {
        _currentPosition = position;
      });

      // Add current location marker if map is ready
      if (_mapboxMap != null && mounted) {
        await _addCurrentLocationMarker();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location acquired successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Error getting location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // Add current location marker
  Future<void> _addCurrentLocationMarker() async {
    if (_pointAnnotationManager == null || _currentPosition == null) return;

    // Remove existing current location marker
    if (_currentLocationMarker != null) {
      await _pointAnnotationManager!.delete(_currentLocationMarker!);
    }

    final pointAnnotationOptions = PointAnnotationOptions(
      geometry: Point(
          coordinates: Position(
              _currentPosition!.longitude, _currentPosition!.latitude)),
      iconSize: 3.0,
      iconImage: "marker",
      iconColor: Colors.blue.value, // Blue for current location
    );

    _currentLocationMarker =
        await _pointAnnotationManager!.create(pointAnnotationOptions);
    print('✅ Added current location marker');
  }

  // Search for location
  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final results = await _mapboxService.searchLocation(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      print('❌ Error searching: $e');
      setState(() => _isSearching = false);
    }
  }

  // Navigate to searched location
  void _navigateToSearchResult(MapboxSearchResult result) async {
    // Close search
    setState(() {
      _searchResults = [];
      _searchController.clear();
    });

    // Fly to location
    _mapboxMap?.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(result.longitude, result.latitude)),
        zoom: 14.0,
      ),
      MapAnimationOptions(duration: 1000),
    );

    // Get route if current location is available
    if (_currentPosition != null) {
      await _getRoute(
        endLat: result.latitude,
        endLng: result.longitude,
      );
    }
  }

  // Get route from current location to destination
  Future<void> _getRoute({
    required double endLat,
    required double endLng,
  }) async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Current location not available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final route = await _mapboxService.getRoute(
        startLat: _currentPosition!.latitude,
        startLng: _currentPosition!.longitude,
        endLat: endLat,
        endLng: endLng,
      );

      if (route == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not find route'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _currentRoute = route;
      });

      await _drawRoute(route);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Route: ${route.distanceText} • ${route.durationText}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      print('❌ Error getting route: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting route: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Draw route on map
  Future<void> _drawRoute(MapboxRoute route) async {
    if (_mapboxMap == null) return;

    // Create polyline manager if not exists
    _polylineAnnotationManager ??=
        await _mapboxMap!.annotations.createPolylineAnnotationManager();

    // Remove existing route
    if (_routeLine != null) {
      await _polylineAnnotationManager!.delete(_routeLine!);
    }

    // Create route line
    final lineCoordinates = route.coordinates
        .map((point) => Position(point.longitude, point.latitude))
        .toList();

    final polylineOptions = PolylineAnnotationOptions(
      geometry: LineString(coordinates: lineCoordinates),
      lineColor: Colors.blue.value,
      lineWidth: 5.0,
    );

    _routeLine = await _polylineAnnotationManager!.create(polylineOptions);
    print('✅ Route drawn on map');
  }

  // Clear route
  Future<void> _clearRoute() async {
    if (_routeLine != null && _polylineAnnotationManager != null) {
      await _polylineAnnotationManager!.delete(_routeLine!);
      _routeLine = null;
    }
    setState(() {
      _currentRoute = null;
    });
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    _pointAnnotationManager =
        await _mapboxMap!.annotations.createPointAnnotationManager();

    // Add markers if reports are loaded
    if (_snakeReports.isNotEmpty && _showSnakeReports) {
      await _addSnakeReportMarkers();
    }

    // Add tap listener for map - will detect taps on markers
    _mapboxMap!.setOnMapTapListener((context) async {
      await _handleMapTap(context);
    });
  }

  Future<void> _addSnakeReportMarkers() async {
    if (_pointAnnotationManager == null) return;

    // Clear existing markers
    for (var marker in _markers) {
      await _pointAnnotationManager!.delete(marker);
    }
    _markers.clear();
    _markerReports.clear();

    // Add new markers for each snake report
    for (var report in _snakeReports) {
      try {
        final pointAnnotationOptions = PointAnnotationOptions(
          geometry: Point(
              coordinates: Position(report.longitude, report.latitude)),
          iconSize: 5.0,
          iconImage: "marker",
          iconColor: report.isVenomous 
              ? Colors.red.value 
              : Colors.green.value, // Red for venomous, green for non-venomous
        );

        final marker =
            await _pointAnnotationManager!.create(pointAnnotationOptions);
        _markers.add(marker);
        // Store the report ID with the marker
        _markerReports[marker.id] = report;
      } catch (e) {
        print('❌ Error adding marker for ${report.snakeName}: $e');
      }
    }

    print('✅ Added ${_markers.length} snake report markers to map');
  }

  Future<void> _addHospitalMarkers() async {
    if (_pointAnnotationManager == null) return;

    // Clear existing hospital markers
    for (var marker in _hospitalMarkers) {
      await _pointAnnotationManager!.delete(marker);
    }
    _hospitalMarkers.clear();
    _markerHospitals.clear();

    // Add new markers for each hospital
    for (var hospital in _hospitals) {
      try {
        final pointAnnotationOptions = PointAnnotationOptions(
          geometry: Point(
              coordinates: Position(hospital.longitude, hospital.latitude)),
          iconSize: 5.0,
          iconImage: "marker",
          iconColor: Colors.blue.value, // Blue for hospitals
        );

        final marker =
            await _pointAnnotationManager!.create(pointAnnotationOptions);
        _hospitalMarkers.add(marker);
        _markerHospitals[marker.id] = hospital;
      } catch (e) {
        print('❌ Error adding marker for ${hospital.name}: $e');
      }
    }

    print('✅ Added ${_hospitalMarkers.length} hospital markers to map');
  }

  Future<void> _handleMapTap(MapContentGestureContext context) async {
    final point = context.point;
    final tappedLat = point.coordinates.lat.toDouble();
    final tappedLng = point.coordinates.lng.toDouble();

    // Find nearest snake report within 100 meters (marker tap radius)
    if (_showSnakeReports) {
      SnakeReport? nearestReport;
      double minDistance = double.infinity;

      for (var report in _snakeReports) {
        final distance = _calculateDistance(
          tappedLat,
          tappedLng,
          report.latitude,
          report.longitude,
        );

        // Convert to meters (distance is in km)
        final distanceMeters = distance * 1000;

        if (distanceMeters < 100 && distanceMeters < minDistance) {
          minDistance = distanceMeters;
          nearestReport = report;
        }
      }

      if (nearestReport != null) {
        _showSnakeReportDialog(nearestReport);
        return;
      }
    }

    // Find nearest hospital within 100 meters (marker tap radius)
    if (_showHospitals) {
      Hospital? nearestHospital;
      double minDistance = double.infinity;

      for (var hospital in _hospitals) {
        final distance = _calculateDistance(
          tappedLat,
          tappedLng,
          hospital.latitude,
          hospital.longitude,
        );

        // Convert to meters (distance is in km)
        final distanceMeters = distance * 1000;

        if (distanceMeters < 100 && distanceMeters < minDistance) {
          minDistance = distanceMeters;
          nearestHospital = hospital;
        }
      }

      if (nearestHospital != null) {
        _showHospitalDialog(nearestHospital);
      }
    }
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.asin(math.sqrt(a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (3.141592653589793 / 180);
  }


  void _showSnakeReportDialog(SnakeReport report) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Snake name
              Text(
                report.snakeName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Venom status
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: report.isVenomous
                      ? Colors.red.shade50
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: report.isVenomous
                        ? Colors.red.shade300
                        : Colors.green.shade300,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      report.isVenomous ? Icons.warning_rounded : Icons.check_circle,
                      color: report.isVenomous
                          ? Colors.red.shade700
                          : Colors.green.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      report.isVenomous ? 'Venomous' : 'Non-venomous',
                      style: TextStyle(
                        color: report.isVenomous
                            ? Colors.red.shade700
                            : Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // View Details button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Navigate to detailed snake report page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SnakeReportDetailPage(
                          report: report,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'View Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHospitalDialog(Hospital hospital) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hospital icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.local_hospital,
                      color: Colors.blue.shade700,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hospital.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          hospital.unit,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Address
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on, size: 20, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hospital.address,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Contact
              Row(
                children: [
                  Icon(Icons.phone, size: 20, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hospital.primaryContact,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Toxicologist
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.medical_services, size: 20, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hospital.toxicologist?? "N/A",
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Get Directions button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _getDirectionsToHospital(hospital);
                  },
                  icon: const Icon(Icons.directions),
                  label: const Text('Get Directions'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _getDirectionsToHospital(Hospital hospital) async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to get current location'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Clear any existing route
    await _clearRoute();

    // Fly to hospital location
    await _mapboxMap?.flyTo(
      CameraOptions(
        center: Point(
          coordinates: Position(hospital.longitude, hospital.latitude),
        ),
        zoom: 13.0,
      ),
      MapAnimationOptions(duration: 2000, startDelay: 0),
    );

    // Get route from current location to hospital
    await _getRoute(
      endLat: hospital.latitude,
      endLng: hospital.longitude,
    );
  }

  Future<void> _findNearestHospital() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to get current location. Please enable location services.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final nearestHospital = _hospitalService.findNearestHospital(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );

    if (nearestHospital == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hospitals found'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show hospitals if not already shown
    if (!_showHospitals) {
      await _toggleHospitals();
    }

    // Show hospital dialog
    _showHospitalDialog(nearestHospital);
  }

  void _toggleSnakeReports() async {
    setState(() {
      _showSnakeReports = !_showSnakeReports;
    });

    if (_showSnakeReports) {
      await _addSnakeReportMarkers();
    } else {
      // Clear markers
      if (_pointAnnotationManager != null) {
        for (var marker in _markers) {
          await _pointAnnotationManager!.delete(marker);
        }
        _markers.clear();
      }
    }
  }

  Future<void> _toggleHospitals() async {
    print('🏥 Toggle hospitals called. Current state: $_showHospitals');
    print('🏥 Hospitals loaded: ${_hospitals.length}');
    print('🏥 Map ready: ${_mapboxMap != null}');
    print('🏥 Point annotation manager ready: ${_pointAnnotationManager != null}');

    setState(() {
      _showHospitals = !_showHospitals;
    });

    print('🏥 New state: $_showHospitals');

    if (_showHospitals) {
      if (_hospitals.isEmpty) {
        print('⚠️  No hospitals loaded yet, loading now...');
        await _loadHospitals();
      }

      if (_mapboxMap == null || _pointAnnotationManager == null) {
        print('⚠️  Map not ready yet');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Map is still loading, please wait...'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      await _addHospitalMarkers();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Showing ${_hospitals.length} hospitals'),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      // Clear hospital markers
      if (_pointAnnotationManager != null) {
        for (var marker in _hospitalMarkers) {
          await _pointAnnotationManager!.delete(marker);
        }
        _hospitalMarkers.clear();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hospitals hidden'),
            backgroundColor: Colors.grey,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Snake Reports Map'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          else ...[
            // Toggle Snake Reports
            IconButton(
              onPressed: _toggleSnakeReports,
              icon: Icon(
                _showSnakeReports ? Icons.pets : Icons.pets_outlined,
                color: Colors.white,
              ),
              tooltip: _showSnakeReports ? 'Hide Snake Reports' : 'Show Snake Reports',
            ),
            // Toggle Hospitals
            IconButton(
              onPressed: _toggleHospitals,
              icon: Icon(
                _showHospitals ? Icons.local_hospital : Icons.local_hospital_outlined,
                color: Colors.white,
              ),
              tooltip: _showHospitals ? 'Hide Hospitals' : 'Show Hospitals',
            ),
            // Find Nearest Hospital
            IconButton(
              onPressed: _findNearestHospital,
              icon: const Icon(
                Icons.emergency,
                color: Colors.white,
              ),
              tooltip: 'Find Nearest Hospital',
            ),
          ],
        ],
      ),
      body: Stack(
        children: [
          // Map
          MapWidget(
            key: const ValueKey("snakeReportsMap"),
            cameraOptions: CameraOptions(
              center: Point(
                coordinates: Position(
                  MapboxConstants.defaultLongitude,
                  MapboxConstants.defaultLatitude,
                ),
              ),
              zoom: MapboxConstants.defaultZoom,
            ),
            styleUri: MapboxConstants.styleUrl,
            textureView: true,
            onMapCreated: _onMapCreated,
          ),

          // Search bar at the top
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search location in Philippines...',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onChanged: (value) {
                          if (value.isEmpty) {
                            setState(() {
                              _searchResults = [];
                              _isSearching = false;
                            });
                          }
                        },
                        onSubmitted: (value) {
                          if (value.isNotEmpty) {
                            _searchLocation(value);
                          }
                        },
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults = [];
                            _isSearching = false;
                          });
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    if (_isSearching)
                      const Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.green,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Search results dropdown
          if (_searchResults.isNotEmpty)
            Positioned(
              top: 80,
              left: 16,
              right: 16,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _searchResults.map((result) {
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.location_on, color: Colors.green),
                      title: Text(
                        result.placeName,
                        style: const TextStyle(fontSize: 14),
                      ),
                      onTap: () {
                        _navigateToSearchResult(result);
                      },
                    );
                  }).toList(),
                ),
              ),
            ),

          // Route info card (shown when route is active)
          if (_currentRoute != null)
            Positioned(
              top: 80,
              left: 16,
              right: 16,
              child: Card(
                elevation: 4,
                color: Colors.blue.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.directions, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Text(
                            'Route Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: _clearRoute,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(Icons.straighten,
                                    size: 18, color: Colors.grey.shade700),
                                const SizedBox(width: 6),
                                Text(
                                  _currentRoute!.distanceText,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                Icon(Icons.access_time,
                                    size: 18, color: Colors.grey.shade700),
                                const SizedBox(width: 6),
                                Text(
                                  _currentRoute!.durationText,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Info card - moved to bottom to avoid covering compass
          if (_snakeReports.isNotEmpty && _currentRoute == null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.green),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${_snakeReports.length} snake report${_snakeReports.length == 1 ? '' : 's'} found. Tap on markers to view details.',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
