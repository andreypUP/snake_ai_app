import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import 'package:venom_shield_ph/domain/models/classification_report.dart';

@singleton
class ClassificationSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Upload classification report to Firestore under users/{userId}/classification_reports
  /// Stores image as base64 string (no Firebase Storage needed!)
  /// Returns 'base64' as a placeholder for imageUrl
  Future<String> syncClassificationReport(ClassificationReport report, File imageFile) async {
    print('🔄 Starting sync for report: ${report.id}');
    print('   User ID: ${report.userId}');
    print('   Snake: ${report.snakeName}');
    print('   Image path: ${report.imageLocalPath}');

    try {
      // Check if file exists
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist: ${imageFile.path}');
      }
      print('   ✓ Image file exists');

      // 1. Convert image to base64
      print('   📦 Converting image to base64...');
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      final imageSizeKB = (bytes.length / 1024).toStringAsFixed(2);
      print('   ✓ Image converted: $imageSizeKB KB');

      // 2. Update report with base64 image
      final reportData = report.toFirestore();
      reportData['imageBase64'] = base64Image; // Store base64 in Firestore
      reportData['isSynced'] = true;
      reportData['syncedAt'] = Timestamp.fromDate(DateTime.now());
      reportData['imageUrl'] = 'base64'; // Placeholder

      // 3. Upload to Firestore
      print('   📤 Uploading to Firestore: users/${report.userId}/classification_reports/${report.id}');
      print('   📊 Document size: ${(base64Image.length / 1024).toStringAsFixed(2)} KB');

      await _firestore
          .collection('users')
          .doc(report.userId)
          .collection('classification_reports')
          .doc(report.id)
          .set(reportData);

      print('   ✓ Firestore upload successful');
      print('✅ Sync completed successfully for report: ${report.id}');

      return 'base64'; // Return placeholder
    } catch (e, stackTrace) {
      print('❌ Error syncing classification report: $e');
      print('   Stack trace: $stackTrace');
      rethrow;
    }
  }


  /// Get all classification reports for a user from Firestore
  Future<List<ClassificationReport>> getClassificationReports(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('classification_reports')
          .orderBy('dateClassified', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ClassificationReport.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting classification reports: $e');
      return [];
    }
  }

  /// Delete a classification report from Firestore
  Future<void> deleteClassificationReport(String userId, String reportId) async {
    try {
      // Delete the document (image is stored as base64, so no separate deletion needed)
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('classification_reports')
          .doc(reportId)
          .delete();
    } catch (e) {
      print('Error deleting classification report: $e');
      rethrow;
    }
  }

  /// Stream classification reports for a user
  Stream<List<ClassificationReport>> streamClassificationReports(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('classification_reports')
        .orderBy('dateClassified', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ClassificationReport.fromFirestore(doc)).toList());
  }
}
