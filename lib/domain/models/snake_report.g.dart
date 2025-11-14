// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'snake_report.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SnakeReport _$SnakeReportFromJson(Map<String, dynamic> json) => SnakeReport(
  id: json['id'] as String,
  userId: json['userId'] as String,
  userName: json['userName'] as String?,
  classificationReportId: json['classificationReportId'] as String?,
  snakeName: json['snakeName'] as String,
  scientificName: json['scientificName'] as String?,
  confidence: (json['confidence'] as num).toDouble(),
  isVenomous: json['isVenomous'] as bool,
  venomToxicity: json['venomToxicity'] as String?,
  description: json['description'] as String?,
  imageBase64List: (json['imageBase64List'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  locationName: json['locationName'] as String?,
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
  snakeInfo: json['snakeInfo'] as Map<String, dynamic>,
  createdAt: SnakeReport._dateTimeFromTimestamp(json['createdAt']),
);

Map<String, dynamic> _$SnakeReportToJson(SnakeReport instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'userName': instance.userName,
      'classificationReportId': instance.classificationReportId,
      'snakeName': instance.snakeName,
      'scientificName': instance.scientificName,
      'confidence': instance.confidence,
      'isVenomous': instance.isVenomous,
      'venomToxicity': instance.venomToxicity,
      'description': instance.description,
      'imageBase64List': instance.imageBase64List,
      'locationName': instance.locationName,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'snakeInfo': instance.snakeInfo,
      'createdAt': SnakeReport._dateTimeToTimestamp(instance.createdAt),
    };
