import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:venom_shield_ph/core/constants/mapbox_constants.dart';

class MapLocationPickerPage extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;

  const MapLocationPickerPage({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<MapLocationPickerPage> createState() => _MapLocationPickerPageState();
}

class _MapLocationPickerPageState extends State<MapLocationPickerPage> {
  MapboxMap? _mapboxMap;
  PointAnnotation? _marker;
  PointAnnotationManager? _pointAnnotationManager;

  double? _selectedLatitude;
  double? _selectedLongitude;
  String? _locationName;

  @override
  void initState() {
    super.initState();
    _selectedLatitude = widget.initialLatitude;
    _selectedLongitude = widget.initialLongitude;
    // Initialize Mapbox with access token
    MapboxOptions.setAccessToken(MapboxConstants.accessToken);
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;

    // Create marker manager
    _pointAnnotationManager =
        await _mapboxMap!.annotations.createPointAnnotationManager();

    // Add marker if initial location provided
    if (_selectedLatitude != null && _selectedLongitude != null) {
      _addMarker(_selectedLatitude!, _selectedLongitude!);
    }

    // Add tap listener - for v2.3.0, use setOnMapTapListener
    _mapboxMap!.setOnMapTapListener((context) async {
      // Get the Point from context - it's a geographic coordinate (Point type)
      final point = context.point;

      // Extract latitude and longitude from Point.coordinates
      final latitude = point.coordinates.lat.toDouble();
      final longitude = point.coordinates.lng.toDouble();

      setState(() {
        _selectedLatitude = latitude;
        _selectedLongitude = longitude;
        _locationName =
            'Lat: ${latitude.toStringAsFixed(6)}, Long: ${longitude.toStringAsFixed(6)}';
      });

      _addMarker(latitude, longitude);
    });
  }

  void _addMarker(double lat, double lon) async {
    // Remove existing marker
    if (_marker != null && _pointAnnotationManager != null) {
      await _pointAnnotationManager!.delete(_marker!);
    }

    // Add new marker
    final pointAnnotationOptions = PointAnnotationOptions(
      geometry: Point(coordinates: Position(lon, lat)),
      iconSize: 1.5,
      iconImage: "marker", // make sure you added this asset to your Mapbox style
    );

    _marker = await _pointAnnotationManager!.create(pointAnnotationOptions);

    // Fly to marker
    _mapboxMap!.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(lon, lat)),
        zoom: 14.0,
      ),
      MapAnimationOptions(duration: 1000),
    );
  }

  void _confirmLocation() {
    if (_selectedLatitude != null && _selectedLongitude != null) {
      Navigator.pop(context, {
        'latitude': _selectedLatitude,
        'longitude': _selectedLongitude,
        'locationName': _locationName,
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a location on the map'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  void dispose() {
    // Clean up resources
    _pointAnnotationManager = null;
    _mapboxMap = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _confirmLocation,
            tooltip: 'Confirm Location',
          ),
        ],
      ),
      body: Stack(
        children: [
          MapWidget(
            key: const ValueKey("mapWidget"),
            cameraOptions: CameraOptions(
              center: Point(
                coordinates: Position(
                  widget.initialLongitude ?? MapboxConstants.defaultLongitude,
                  widget.initialLatitude ?? MapboxConstants.defaultLatitude,
                ),
              ),
              zoom: widget.initialLatitude != null
                  ? 14.0
                  : MapboxConstants.defaultZoom,
            ),
            styleUri: MapboxConstants.styleUrl,
            textureView: true,
            onMapCreated: _onMapCreated,
          ),

          // Instructions
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.touch_app, color: Colors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tap anywhere on the map to pin the location',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Selected location info
          if (_selectedLatitude != null && _selectedLongitude != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Card(
                elevation: 4,
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.green.shade700),
                          const SizedBox(width: 8),
                          const Text(
                            'Selected Location',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Latitude: ${_selectedLatitude!.toStringAsFixed(6)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        'Longitude: ${_selectedLongitude!.toStringAsFixed(6)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _confirmLocation,
                          icon: const Icon(Icons.check, color: Colors.white),
                          label: const Text(
                            'Confirm Location',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding:
                            const EdgeInsets.symmetric(vertical: 12),
                          ),
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
