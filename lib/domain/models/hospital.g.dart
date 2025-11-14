// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hospital.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Hospital _$HospitalFromJson(Map<String, dynamic> json) => Hospital(
  id: json['id'] as String,
  name: json['name'] as String,
  unit: json['unit'] as String,
  address: json['address'] as String,
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
  contact: (json['contact'] as List<dynamic>).map((e) => e as String).toList(),
  email: json['email'] as String?,
  toxicologist: json['toxicologist'] as String?,
  provinces: (json['provinces'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$HospitalToJson(Hospital instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'unit': instance.unit,
  'address': instance.address,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'contact': instance.contact,
  'email': instance.email,
  'toxicologist': instance.toxicologist,
  'provinces': instance.provinces,
};
