import 'dart:convert';

/// Represents an office / branch location for geo-fenced attendance.
class OfficeLocationModel {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeter;

  const OfficeLocationModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeter,
  });

  // ── copyWith ────────────────────────────────────────────────────────────

  OfficeLocationModel copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    double? radiusMeter,
  }) {
    return OfficeLocationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusMeter: radiusMeter ?? this.radiusMeter,
    );
  }

  // ── Serialization ───────────────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radiusMeter': radiusMeter,
    };
  }

  factory OfficeLocationModel.fromMap(Map<String, dynamic> map) {
    return OfficeLocationModel(
      id: map['id'] as String,
      name: map['name'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      radiusMeter: (map['radiusMeter'] as num).toDouble(),
    );
  }

  String toJson() => json.encode(toMap());

  factory OfficeLocationModel.fromJson(String source) =>
      OfficeLocationModel.fromMap(
          json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'OfficeLocationModel(id: $id, name: $name, lat: $latitude, lng: $longitude, radius: ${radiusMeter}m)';
}
