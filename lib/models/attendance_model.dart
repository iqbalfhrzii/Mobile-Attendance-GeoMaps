import 'dart:convert';

import '../core/enums.dart';

/// Represents a single attendance record.
class AttendanceModel {
  final String id;
  final String userId;
  final String employeeName;
  final DateTime date;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final String? checkInPhotoPath;
  final String? checkOutPhotoPath;
  final double? latitude;
  final double? longitude;
  final double? distanceFromOffice;
  final LocationStatus locationStatus;
  final AttendanceStatus attendanceStatus;
  final DateTime createdAt;

  const AttendanceModel({
    required this.id,
    required this.userId,
    required this.employeeName,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    this.checkInPhotoPath,
    this.checkOutPhotoPath,
    this.latitude,
    this.longitude,
    this.distanceFromOffice,
    required this.locationStatus,
    required this.attendanceStatus,
    required this.createdAt,
  });

  /// Whether the user has checked in.
  bool get hasCheckedIn => checkInTime != null;

  /// Whether the user has checked out.
  bool get hasCheckedOut => checkOutTime != null;

  /// Whether this attendance record is complete (both in and out).
  bool get isComplete => hasCheckedIn && hasCheckedOut;

  /// Duration of work (if both check-in and check-out exist).
  Duration? get workDuration {
    if (checkInTime == null || checkOutTime == null) return null;
    Duration diff = checkOutTime!.difference(checkInTime!);
    if (diff.isNegative) {
      diff = diff + const Duration(hours: 24);
    }
    return diff;
  }

  /// Formatted work duration string.
  String get workDurationFormatted {
    final d = workDuration;
    if (d == null) return '-';
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    return '${hours}j ${minutes}m';
  }

  // ── copyWith ────────────────────────────────────────────────────────────

  AttendanceModel copyWith({
    String? id,
    String? userId,
    String? employeeName,
    DateTime? date,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    String? checkInPhotoPath,
    String? checkOutPhotoPath,
    double? latitude,
    double? longitude,
    double? distanceFromOffice,
    LocationStatus? locationStatus,
    AttendanceStatus? attendanceStatus,
    DateTime? createdAt,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      employeeName: employeeName ?? this.employeeName,
      date: date ?? this.date,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      checkInPhotoPath: checkInPhotoPath ?? this.checkInPhotoPath,
      checkOutPhotoPath: checkOutPhotoPath ?? this.checkOutPhotoPath,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      distanceFromOffice: distanceFromOffice ?? this.distanceFromOffice,
      locationStatus: locationStatus ?? this.locationStatus,
      attendanceStatus: attendanceStatus ?? this.attendanceStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ── Serialization ───────────────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'employeeName': employeeName,
      'date': date.toIso8601String(),
      'checkInTime': checkInTime?.toIso8601String(),
      'checkOutTime': checkOutTime?.toIso8601String(),
      'checkInPhotoPath': checkInPhotoPath,
      'checkOutPhotoPath': checkOutPhotoPath,
      'latitude': latitude,
      'longitude': longitude,
      'distanceFromOffice': distanceFromOffice,
      'locationStatus': locationStatus.name,
      'attendanceStatus': attendanceStatus.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AttendanceModel.fromMap(Map<String, dynamic> map) {
    return AttendanceModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      employeeName: map['employeeName'] as String,
      date: DateTime.parse(map['date'] as String),
      checkInTime: map['checkInTime'] != null
          ? DateTime.parse(map['checkInTime'] as String)
          : null,
      checkOutTime: map['checkOutTime'] != null
          ? DateTime.parse(map['checkOutTime'] as String)
          : null,
      checkInPhotoPath: map['checkInPhotoPath'] as String?,
      checkOutPhotoPath: map['checkOutPhotoPath'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      distanceFromOffice: (map['distanceFromOffice'] as num?)?.toDouble(),
      locationStatus: LocationStatus.values
          .firstWhere((e) => e.name == map['locationStatus']),
      attendanceStatus: AttendanceStatus.values
          .firstWhere((e) => e.name == map['attendanceStatus']),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  String toJson() => json.encode(toMap());

  factory AttendanceModel.fromJson(String source) =>
      AttendanceModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'AttendanceModel(id: $id, userId: $userId, employeeName: $employeeName, date: $date, status: ${attendanceStatus.name})';
}
