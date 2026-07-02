import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/attendance_model.dart';
import '../repositories/attendance_repository.dart';
import 'auth_provider.dart';

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
    FutureProvider<List<AttendanceModel>>((ref) async {
  final repo = ref.watch(attendanceRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return repo.getHistory(user.id);
});

/// All attendances (admin only).
final allAttendancesProvider =
    FutureProvider<List<AttendanceModel>>((ref) async {
  final repo = ref.watch(attendanceRepositoryProvider);
  return repo.getAll();
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

  Future<void> checkIn() async {
    if (_userId == null || _userName == null) return;
    state = const AsyncValue.loading();
    try {
      final record = await _repo.checkIn(
        userId: _userId,
        employeeName: _userName,
      );
      state = AsyncValue.data(record);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> checkOut(String attendanceId) async {
    state = const AsyncValue.loading();
    try {
      final record = await _repo.checkOut(attendanceId: attendanceId);
      state = AsyncValue.data(record);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
