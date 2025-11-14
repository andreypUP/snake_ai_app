import 'package:json_annotation/json_annotation.dart';

part 'hospital.g.dart';

@JsonSerializable()
class Hospital {
  final String id;
  final String name;
  final String unit;
  final String address;
  final double latitude;
  final double longitude;
  final List<String> contact;
  final String email;
  final String toxicologist;
  final List<String> provinces;

  Hospital({
    required this.id,
    required this.name,
    required this.unit,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.contact,
    required this.email,
    required this.toxicologist,
    required this.provinces,
  });

  factory Hospital.fromJson(Map<String, dynamic> json) =>
      _$HospitalFromJson(json);

  Map<String, dynamic> toJson() => _$HospitalToJson(this);

  String get fullName => '$name - $unit';

  String get primaryContact => contact.isNotEmpty ? contact.first : '';

  String get provincesText => provinces.join(', ');
}
