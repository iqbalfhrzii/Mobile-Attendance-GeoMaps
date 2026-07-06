import 'dart:convert';

import '../core/enums.dart';

/// Represents a single attendance record.
class AttendanceModel {
  final String id;
  final String userId;
  final String employeeName;
  final String shiftId;
  final String shiftName;
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
    required this.shiftId,
    required this.shiftName,
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
    if (hours > 0) return '${hours}j ${minutes}m';
    return '${minutes}m';
  }

  // ── copyWith ────────────────────────────────────────────────────────────

  AttendanceModel copyWith({
    String? id,
    String? userId,
    String? employeeName,
    String? shiftId,
    String? shiftName,
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
      shiftId: shiftId ?? this.shiftId,
      shiftName: shiftName ?? this.shiftName,
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
      'userid': userId,
      'employeename': employeeName,
      'shiftid': shiftId,
      'shiftname': shiftName,
      'date': date.toIso8601String(),
      'checkintime': checkInTime?.toIso8601String(),
      'checkouttime': checkOutTime?.toIso8601String(),
      'checkinphotopath': checkInPhotoPath,
      'checkoutphotopath': checkOutPhotoPath,
      'latitude': latitude,
      'longitude': longitude,
      'distancefromoffice': distanceFromOffice,
      'locationstatus': locationStatus.name,
      'attendancestatus': attendanceStatus.name,
      'createdat': createdAt.toIso8601String(),
    };
  }

  factory AttendanceModel.fromMap(Map<String, dynamic> map) {
    return AttendanceModel(
      id: map['id'] as String,
      userId: map['userid'] as String,
      employeeName: map['employeename'] as String,
      shiftId: map['shiftid'] as String? ?? 'SHF001',
      shiftName: map['shiftname'] as String? ?? 'Shift Pagi',
      date: DateTime.parse(map['date'] as String),
      checkInTime: map['checkintime'] != null
          ? DateTime.parse(map['checkintime'] as String)
          : null,
      checkOutTime: map['checkouttime'] != null
          ? DateTime.parse(map['checkouttime'] as String)
          : null,
      checkInPhotoPath: map['checkinphotopath'] as String?,
      checkOutPhotoPath: map['checkoutphotopath'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      distanceFromOffice: (map['distancefromoffice'] as num?)?.toDouble(),
      locationStatus: LocationStatus.values
          .firstWhere((e) => e.name == map['locationstatus']),
      attendanceStatus: AttendanceStatus.values
          .firstWhere((e) => e.name == map['attendancestatus']),
      createdAt: DateTime.parse(map['createdat'] as String),
    );
  }

  String toJson() => json.encode(toMap());

  factory AttendanceModel.fromJson(String source) =>
      AttendanceModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'AttendanceModel(id: $id, userId: $userId, employeeName: $employeeName, date: $date, status: ${attendanceStatus.name})';
}
