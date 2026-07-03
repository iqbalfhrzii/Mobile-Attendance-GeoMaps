import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/enums.dart';
import '../models/attendance_model.dart';
import '../repositories/attendance_repository.dart';
import 'auth_provider.dart';
import 'user_provider.dart';

/// Provides the [AttendanceRepository] singleton.
final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository();
});

/// Today's attendance for the current user.
final todayAttendanceProvider =
    StateNotifierProvider<TodayAttendanceNotifier, AsyncValue<AttendanceModel?>>(
  (ref) {
    final repo = ref.watch(attendanceRepositoryProvider);
    final user = ref.watch(currentUserProvider);
    return TodayAttendanceNotifier(repo, user?.id, user?.fullName);
  },
);

/// Attendance history for the current user.
final attendanceHistoryProvider =
    FutureProvider.autoDispose<List<AttendanceModel>>((ref) async {
  final repo = ref.watch(attendanceRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return repo.getHistory(user.id);
});

/// All attendances (admin only).
final allAttendancesProvider =
    FutureProvider.autoDispose<List<AttendanceModel>>((ref) async {
  final repo = ref.watch(attendanceRepositoryProvider);
  return repo.getAll();
});

/// All attendance records for today (admin overview).
final todayAllAttendancesProvider =
    FutureProvider.autoDispose<List<AttendanceModel>>((ref) async {
  final repo = ref.watch(attendanceRepositoryProvider);
  final all = await repo.getAll();
  final now = DateTime.now();
  return all.where((r) =>
      r.date.year == now.year &&
      r.date.month == now.month &&
      r.date.day == now.day).toList();
});

/// Computed stats for admin dashboard.
final todayStatsProvider =
    FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final todayRecords = await ref.watch(todayAllAttendancesProvider.future);
  final userRepo = ref.watch(userRepositoryProvider);
  final employeeCount = await userRepo.employeeCount();

  int late_ = 0;
  int outsideRadius = 0;

  for (final r in todayRecords) {
    if (r.attendanceStatus == AttendanceStatus.late_) late_++;
    if (r.locationStatus == LocationStatus.outside) outsideRadius++;
  }

  final totalCheckedIn = todayRecords.where((r) => r.hasCheckedIn).length;
  final belumHadir = employeeCount - totalCheckedIn;

  return {
    'totalKaryawan': employeeCount,
    'hadir': totalCheckedIn,
    'belumHadir': belumHadir < 0 ? 0 : belumHadir,
    'terlambat': late_,
    'diLuarRadius': outsideRadius,
  };
});

// ─── State Notifier ────────────────────────────────────────────────────────

class TodayAttendanceNotifier
    extends StateNotifier<AsyncValue<AttendanceModel?>> {
  final AttendanceRepository _repo;
  final String? _userId;
  final String? _userName;

  TodayAttendanceNotifier(this._repo, this._userId, this._userName)
      : super(const AsyncValue.loading()) {
    if (_userId != null) load();
  }

  Future<void> load() async {
    if (_userId == null) return;
    state = const AsyncValue.loading();
    try {
      final record = await _repo.getTodayAttendance(_userId);
      state = AsyncValue.data(record);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> checkIn({
    double? latitude,
    double? longitude,
    double? distanceFromOffice,
    LocationStatus locationStatus = LocationStatus.unknown,
    AttendanceStatus attendanceStatus = AttendanceStatus.present,
    String? photoPath,
  }) async {
    if (_userId == null || _userName == null) return;
    state = const AsyncValue.loading();
    try {
      final record = await _repo.checkIn(
        userId: _userId,
        employeeName: _userName,
        latitude: latitude,
        longitude: longitude,
        distanceFromOffice: distanceFromOffice,
        locationStatus: locationStatus,
        attendanceStatus: attendanceStatus,
        photoPath: photoPath,
      );
      state = AsyncValue.data(record);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> checkOut(String attendanceId, {String? photoPath}) async {
    state = const AsyncValue.loading();
    try {
      final record = await _repo.checkOut(
        attendanceId: attendanceId,
        photoPath: photoPath,
      );
      state = AsyncValue.data(record);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
