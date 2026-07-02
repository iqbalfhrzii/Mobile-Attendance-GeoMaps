import '../core/enums.dart';
import '../models/attendance_model.dart';

/// Dummy repository for attendance records.
class AttendanceRepository {
  final List<AttendanceModel> _records = [];

  AttendanceRepository() {
    _seedDummyData();
  }

  void _seedDummyData() {
    final now = DateTime.now();

    final dummyRecords = [
      // ── USR001 (Admin — Ahmad Fauzi) ─────────────────────────────
      AttendanceModel(
        id: 'ATT001',
        userId: 'USR001',
        employeeName: 'Ahmad Fauzi',
        date: DateTime(now.year, now.month, now.day - 1),
        checkInTime: DateTime(now.year, now.month, now.day - 1, 7, 55),
        checkOutTime: DateTime(now.year, now.month, now.day - 1, 16, 5),
        latitude: -6.2088,
        longitude: 106.8456,
        distanceFromOffice: 15.3,
        locationStatus: LocationStatus.inside,
        attendanceStatus: AttendanceStatus.present,
        createdAt: DateTime(now.year, now.month, now.day - 1, 7, 55),
      ),
      AttendanceModel(
        id: 'ATT002',
        userId: 'USR001',
        employeeName: 'Ahmad Fauzi',
        date: DateTime(now.year, now.month, now.day - 2),
        checkInTime: DateTime(now.year, now.month, now.day - 2, 8, 20),
        checkOutTime: DateTime(now.year, now.month, now.day - 2, 16, 10),
        latitude: -6.2090,
        longitude: 106.8460,
        distanceFromOffice: 22.1,
        locationStatus: LocationStatus.inside,
        attendanceStatus: AttendanceStatus.late_,
        createdAt: DateTime(now.year, now.month, now.day - 2, 8, 20),
      ),

      // ── USR002 (Employee — Budi Santoso) ─────────────────────────
      AttendanceModel(
        id: 'ATT003',
        userId: 'USR002',
        employeeName: 'Budi Santoso',
        date: DateTime(now.year, now.month, now.day - 1),
        checkInTime: DateTime(now.year, now.month, now.day - 1, 7, 58),
        checkOutTime: DateTime(now.year, now.month, now.day - 1, 16, 2),
        latitude: -6.2085,
        longitude: 106.8452,
        distanceFromOffice: 10.5,
        locationStatus: LocationStatus.inside,
        attendanceStatus: AttendanceStatus.present,
        createdAt: DateTime(now.year, now.month, now.day - 1, 7, 58),
      ),
      AttendanceModel(
        id: 'ATT004',
        userId: 'USR002',
        employeeName: 'Budi Santoso',
        date: DateTime(now.year, now.month, now.day - 2),
        checkInTime: DateTime(now.year, now.month, now.day - 2, 8, 15),
        checkOutTime: DateTime(now.year, now.month, now.day - 2, 16, 0),
        latitude: -6.2092,
        longitude: 106.8458,
        distanceFromOffice: 18.7,
        locationStatus: LocationStatus.inside,
        attendanceStatus: AttendanceStatus.late_,
        createdAt: DateTime(now.year, now.month, now.day - 2, 8, 15),
      ),
      AttendanceModel(
        id: 'ATT005',
        userId: 'USR002',
        employeeName: 'Budi Santoso',
        date: DateTime(now.year, now.month, now.day - 3),
        checkInTime: null,
        checkOutTime: null,
        latitude: null,
        longitude: null,
        distanceFromOffice: null,
        locationStatus: LocationStatus.unknown,
        attendanceStatus: AttendanceStatus.permission,
        createdAt: DateTime(now.year, now.month, now.day - 3, 8, 0),
      ),

      // ── USR003 (Citra Dewi) ──────────────────────────────────────
      AttendanceModel(
        id: 'ATT006',
        userId: 'USR003',
        employeeName: 'Citra Dewi',
        date: DateTime(now.year, now.month, now.day - 1),
        checkInTime: DateTime(now.year, now.month, now.day - 1, 7, 50),
        checkOutTime: DateTime(now.year, now.month, now.day - 1, 16, 0),
        latitude: -6.2087,
        longitude: 106.8455,
        distanceFromOffice: 12.0,
        locationStatus: LocationStatus.inside,
        attendanceStatus: AttendanceStatus.present,
        createdAt: DateTime(now.year, now.month, now.day - 1, 7, 50),
      ),

      // ── USR004 (Dimas Prayoga) ───────────────────────────────────
      AttendanceModel(
        id: 'ATT007',
        userId: 'USR004',
        employeeName: 'Dimas Prayoga',
        date: DateTime(now.year, now.month, now.day - 1),
        checkInTime: DateTime(now.year, now.month, now.day - 1, 8, 30),
        checkOutTime: DateTime(now.year, now.month, now.day - 1, 16, 15),
        latitude: -6.2200,
        longitude: 106.8500,
        distanceFromOffice: 150.0,
        locationStatus: LocationStatus.outside,
        attendanceStatus: AttendanceStatus.late_,
        createdAt: DateTime(now.year, now.month, now.day - 1, 8, 30),
      ),

      // ── USR005 (Eka Putri) ───────────────────────────────────────
      AttendanceModel(
        id: 'ATT008',
        userId: 'USR005',
        employeeName: 'Eka Putri',
        date: DateTime(now.year, now.month, now.day - 1),
        checkInTime: null,
        checkOutTime: null,
        latitude: null,
        longitude: null,
        distanceFromOffice: null,
        locationStatus: LocationStatus.unknown,
        attendanceStatus: AttendanceStatus.sick,
        createdAt: DateTime(now.year, now.month, now.day - 1, 8, 0),
      ),

      // ── USR006 (Farhan Maulana) ──────────────────────────────────
      AttendanceModel(
        id: 'ATT009',
        userId: 'USR006',
        employeeName: 'Farhan Maulana',
        date: DateTime(now.year, now.month, now.day - 1),
        checkInTime: DateTime(now.year, now.month, now.day - 1, 7, 45),
        checkOutTime: DateTime(now.year, now.month, now.day - 1, 16, 0),
        latitude: -6.2086,
        longitude: 106.8454,
        distanceFromOffice: 8.2,
        locationStatus: LocationStatus.inside,
        attendanceStatus: AttendanceStatus.present,
        createdAt: DateTime(now.year, now.month, now.day - 1, 7, 45),
      ),
    ];

    _records.addAll(dummyRecords);
  }

  /// Get today's attendance for a user.
  Future<AttendanceModel?> getTodayAttendance(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final now = DateTime.now();
    try {
      return _records.firstWhere(
        (r) =>
            r.userId == userId &&
            r.date.year == now.year &&
            r.date.month == now.month &&
            r.date.day == now.day,
      );
    } catch (_) {
      return null;
    }
  }

  /// Check in — create new attendance record.
  Future<AttendanceModel> checkIn({
    required String userId,
    required String employeeName,
    double? latitude,
    double? longitude,
    double? distanceFromOffice,
    LocationStatus locationStatus = LocationStatus.unknown,
    AttendanceStatus attendanceStatus = AttendanceStatus.present,
    String? photoPath,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final now = DateTime.now();

    final record = AttendanceModel(
      id: 'ATT${now.millisecondsSinceEpoch}',
      userId: userId,
      employeeName: employeeName,
      date: DateTime(now.year, now.month, now.day),
      checkInTime: now,
      checkInPhotoPath: photoPath,
      latitude: latitude,
      longitude: longitude,
      distanceFromOffice: distanceFromOffice,
      locationStatus: locationStatus,
      attendanceStatus: attendanceStatus,
      createdAt: now,
    );

    _records.add(record);
    return record;
  }

  /// Check out — update existing attendance record.
  Future<AttendanceModel> checkOut({
    required String attendanceId,
    String? photoPath,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _records.indexWhere((r) => r.id == attendanceId);
    if (index == -1) throw Exception('Record tidak ditemukan');

    final updated = _records[index].copyWith(
      checkOutTime: DateTime.now(),
      checkOutPhotoPath: photoPath,
    );
    _records[index] = updated;
    return updated;
  }

  /// Get attendance history for a user.
  Future<List<AttendanceModel>> getHistory(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _records.where((r) => r.userId == userId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Get all attendance records (admin).
  Future<List<AttendanceModel>> getAll() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_records)..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Get attendance records by date range.
  Future<List<AttendanceModel>> getByDateRange(
    DateTime start,
    DateTime end, {
    String? userId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _records.where((r) {
      final inRange = !r.date.isBefore(start) && !r.date.isAfter(end);
      if (userId != null) return inRange && r.userId == userId;
      return inRange;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }
}
