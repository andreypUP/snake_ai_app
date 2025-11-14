import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'snake_report.g.dart';

@JsonSerializable()
class SnakeReport {
  final String id;
  final String userId;
  final String? userName; // Display name of user
  final String? classificationReportId; // Reference to ClassificationReport
  final String snakeName;
  final String? scientificName;
  final double confidence; // From classification
  final bool isVenomous;
  final String? venomToxicity; // From snake info
  final String? description; // User description
  final List<String> imageBase64List; // Store images as base64
  final String? locationName; // e.g., "Manila, Philippines"
  final double latitude;
  final double longitude;
  final Map<String, dynamic> snakeInfo; // Full snake data
  @JsonKey(fromJson: _dateTimeFromTimestamp, toJson: _dateTimeToTimestamp)
  final DateTime createdAt;

  SnakeReport({
    required this.id,
    required this.userId,
    this.userName,
    this.classificationReportId,
    required this.snakeName,
    this.scientificName,
    required this.confidence,
    required this.isVenomous,
    this.venomToxicity,
    this.description,
    required this.imageBase64List,
    this.locationName,
    required this.latitude,
    required this.longitude,
    required this.snakeInfo,
    required this.createdAt,
  });

  factory SnakeReport.fromJson(Map<String, dynamic> json) =>
      _$SnakeReportFromJson(json);

  Map<String, dynamic> toJson() => _$SnakeReportToJson(this);

  factory SnakeReport.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SnakeReport(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'],
      classificationReportId: data['classificationReportId'],
      snakeName: data['snakeName'] ?? '',
      scientificName: data['scientificName'],
      confidence: (data['confidence'] ?? 0.0).toDouble(),
      isVenomous: data['isVenomous'] ?? false,
      venomToxicity: data['venomToxicity'],
      description: data['description'],
      imageBase64List: List<String>.from(data['imageBase64List'] ?? []),
      locationName: data['locationName'],
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      snakeInfo: Map<String, dynamic>.from(data['snakeInfo'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'classificationReportId': classificationReportId,
      'snakeName': snakeName,
      'scientificName': scientificName,
      'confidence': confidence,
      'isVenomous': isVenomous,
      'venomToxicity': venomToxicity,
      'description': description,
      'imageBase64List': imageBase64List,
      'locationName': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'snakeInfo': snakeInfo,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static DateTime _dateTimeFromTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
    return DateTime.parse(timestamp.toString());
  }

  static dynamic _dateTimeToTimestamp(DateTime dateTime) {
    return dateTime.toIso8601String();
  }
}
