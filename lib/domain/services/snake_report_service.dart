import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import 'package:venom_shield_ph/domain/models/snake_report.dart';
import 'dart:math' as math;
import 'package:image/image.dart' as img;


@singleton
class SnakeReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _collectionName = 'snake_reports';

  // Create a new snake report
  Future<String> createSnakeReport(SnakeReport report) async {
    final docRef = await _firestore
        .collection(_collectionName)
        .add(report.toFirestore());
    return docRef.id;
  }

  // Convert images to base64 strings with compression
  Future<List<String>> convertImagesToBase64(List<File> imageFiles) async {
    List<String> base64Images = [];

    for (var imageFile in imageFiles) {
      try {
        // Read and decode the image
        final bytes = await imageFile.readAsBytes();
        final image = img.decodeImage(bytes);

        if (image == null) {
          print('   ❌ Failed to decode image');
          continue;
        }

        // Resize if too large (max 800px width to reduce size)
        img.Image resized = image;
        if (image.width > 800) {
          resized = img.copyResize(image, width: 800);
        }

        // Compress to JPEG with quality 85 (good balance between quality and size)
        final compressedBytes = img.encodeJpg(resized, quality: 85);
        final base64 = base64Encode(compressedBytes);

        // Check if still too large (Firestore has ~1MB limit per field)
        final sizeKB = compressedBytes.length / 1024;
        if (sizeKB > 200) {
          print('   ⚠️  Warning: Image still large after compression: ${sizeKB.toStringAsFixed(2)} KB');
        } else {
          print('   ✅ Compressed image: ${sizeKB.toStringAsFixed(2)} KB (original: ${(bytes.length / 1024).toStringAsFixed(2)} KB)');
        }

        base64Images.add(base64);
      } catch (e) {
        print('   ❌ Failed to convert image: $e');
      }
    }

    return base64Images;
  }

  // Get all snake reports
  Future<List<SnakeReport>> getAllSnakeReports() async {
    final snapshot = await _firestore
        .collection(_collectionName)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => SnakeReport.fromFirestore(doc)).toList();
  }

  // Get snake reports by user
  Future<List<SnakeReport>> getSnakeReportsByUser(String userId) async {
    final snapshot = await _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => SnakeReport.fromFirestore(doc)).toList();
  }

  // Get a single snake report
  Future<SnakeReport?> getSnakeReportById(String id) async {
    final doc = await _firestore.collection(_collectionName).doc(id).get();
    if (!doc.exists) return null;
    return SnakeReport.fromFirestore(doc);
  }

  // Update a snake report
  Future<void> updateSnakeReport(String id, SnakeReport report) async {
    await _firestore
        .collection(_collectionName)
        .doc(id)
        .update(report.toFirestore());
  }

  // Delete a snake report
  Future<void> deleteSnakeReport(String id) async {
    // Delete document (images stored as base64, no separate deletion needed)
    await _firestore.collection(_collectionName).doc(id).delete();
  }

  // Stream of all snake reports (for real-time updates)
  Stream<List<SnakeReport>> streamAllSnakeReports() {
    return _firestore
        .collection(_collectionName)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => SnakeReport.fromFirestore(doc)).toList());
  }

  // Get snake reports within a radius (for map view)
  Future<List<SnakeReport>> getSnakeReportsNearby({
    required double latitude,
    required double longitude,
    required double radiusInKm,
  }) async {
    // Firestore doesn't support geospatial queries directly
    // We'll fetch all and filter in memory (for production, consider using GeoFlutterFire)
    final allReports = await getAllSnakeReports();

    return allReports.where((report) {
      final distance = _calculateDistance(
        latitude,
        longitude,
        report.latitude,
        report.longitude,
      );
      return distance <= radiusInKm;
    }).toList();
  }

// Calculate distance between two coordinates (Haversine formula)
  double _calculateDistance(
      double lat1,
      double lon1,
      double lat2,
      double lon2,
      ) {
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
}
