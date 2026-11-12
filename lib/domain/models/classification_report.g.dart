// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'classification_report.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClassificationReport _$ClassificationReportFromJson(
  Map<String, dynamic> json,
) => ClassificationReport(
  id: json['id'] as String,
  userId: json['userId'] as String,
  snakeId: json['snakeId'] as String,
  snakeName: json['snakeName'] as String,
  scientificName: json['scientificName'] as String?,
  confidence: (json['confidence'] as num).toDouble(),
  imageLocalPath: json['imageLocalPath'] as String,
  imageUrl: json['imageUrl'] as String?,
  snakeInfo: json['snakeInfo'] as Map<String, dynamic>,
  dateClassified: DateTime.parse(json['dateClassified'] as String),
  isSynced: json['isSynced'] as bool? ?? false,
  syncedAt: json['syncedAt'] == null
      ? null
      : DateTime.parse(json['syncedAt'] as String),
  sharedAsSnakeReport: json['sharedAsSnakeReport'] as bool? ?? false,
  sharedReportId: json['sharedReportId'] as String?,
);

Map<String, dynamic> _$ClassificationReportToJson(
  ClassificationReport instance,
) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'snakeId': instance.snakeId,
  'snakeName': instance.snakeName,
  'scientificName': instance.scientificName,
  'confidence': instance.confidence,
  'imageLocalPath': instance.imageLocalPath,
  'imageUrl': instance.imageUrl,
  'snakeInfo': instance.snakeInfo,
  'dateClassified': instance.dateClassified.toIso8601String(),
  'isSynced': instance.isSynced,
  'syncedAt': instance.syncedAt?.toIso8601String(),
  'sharedAsSnakeReport': instance.sharedAsSnakeReport,
  'sharedReportId': instance.sharedReportId,
};
