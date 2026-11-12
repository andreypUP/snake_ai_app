import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'classification_report.g.dart';

@JsonSerializable(explicitToJson: true)
class ClassificationReport {
  final String id;
  final String userId;
  final String snakeId; // ID to match with results.json
  final String snakeName;
  final String? scientificName;
  final double confidence;
  final String imageLocalPath;
  final String? imageUrl; // Firebase Storage URL after sync
  final Map<String, dynamic> snakeInfo; // Full snake data from results.json
  final DateTime dateClassified;
  final bool isSynced;
  final DateTime? syncedAt;
  final bool sharedAsSnakeReport; // Whether this was shared to community
  final String? sharedReportId; // ID of snake report if shared

  ClassificationReport({
    required this.id,
    required this.userId,
    required this.snakeId,
    required this.snakeName,
    this.scientificName,
    required this.confidence,
    required this.imageLocalPath,
    this.imageUrl,
    required this.snakeInfo,
    required this.dateClassified,
    this.isSynced = false,
    this.syncedAt,
    this.sharedAsSnakeReport = false,
    this.sharedReportId,
  });

  factory ClassificationReport.fromJson(Map<String, dynamic> json) =>
      _$ClassificationReportFromJson(json);

  Map<String, dynamic> toJson() => _$ClassificationReportToJson(this);

  // Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'snakeId': snakeId,
      'snakeName': snakeName,
      'scientificName': scientificName,
      'confidence': confidence,
      'imageUrl': imageUrl,
      'snakeInfo': snakeInfo,
      'dateClassified': Timestamp.fromDate(dateClassified),
      'isSynced': isSynced,
      'syncedAt': syncedAt != null ? Timestamp.fromDate(syncedAt!) : null,
      'sharedAsSnakeReport': sharedAsSnakeReport,
      'sharedReportId': sharedReportId,
    };
  }

  // Create from Firestore document
  factory ClassificationReport.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ClassificationReport(
      id: doc.id,
      userId: data['userId'] ?? '',
      snakeId: data['snakeId'] ?? '',
      snakeName: data['snakeName'] ?? '',
      scientificName: data['scientificName'],
      confidence: (data['confidence'] ?? 0.0).toDouble(),
      imageLocalPath: '', // Not stored in Firestore
      imageUrl: data['imageUrl'],
      snakeInfo: data['snakeInfo'] ?? {},
      dateClassified: (data['dateClassified'] as Timestamp).toDate(),
      isSynced: data['isSynced'] ?? true, // Firestore data is always synced
      syncedAt: data['syncedAt'] != null
          ? (data['syncedAt'] as Timestamp).toDate()
          : null,
      sharedAsSnakeReport: data['sharedAsSnakeReport'] ?? false,
      sharedReportId: data['sharedReportId'],
    );
  }

  ClassificationReport copyWith({
    String? id,
    String? userId,
    String? snakeId,
    String? snakeName,
    String? scientificName,
    double? confidence,
    String? imageLocalPath,
    String? imageUrl,
    Map<String, dynamic>? snakeInfo,
    DateTime? dateClassified,
    bool? isSynced,
    DateTime? syncedAt,
    bool? sharedAsSnakeReport,
    String? sharedReportId,
  }) {
    return ClassificationReport(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      snakeId: snakeId ?? this.snakeId,
      snakeName: snakeName ?? this.snakeName,
      scientificName: scientificName ?? this.scientificName,
      confidence: confidence ?? this.confidence,
      imageLocalPath: imageLocalPath ?? this.imageLocalPath,
      imageUrl: imageUrl ?? this.imageUrl,
      snakeInfo: snakeInfo ?? this.snakeInfo,
      dateClassified: dateClassified ?? this.dateClassified,
      isSynced: isSynced ?? this.isSynced,
      syncedAt: syncedAt ?? this.syncedAt,
      sharedAsSnakeReport: sharedAsSnakeReport ?? this.sharedAsSnakeReport,
      sharedReportId: sharedReportId ?? this.sharedReportId,
    );
  }
}
