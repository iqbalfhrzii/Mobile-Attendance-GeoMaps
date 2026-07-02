import '../models/attendance_model.dart';
import '../core/enums.dart';

/// Abstract interface for attendance operations.
abstract class AttendanceService {
  Future<AttendanceModel?> getTodayAttendance(String userId);
  Future<AttendanceModel> checkIn({
    required String userId,
    required String employeeName,
    double? latitude,
    double? longitude,
    double? distanceFromOffice,
    LocationStatus locationStatus,
    AttendanceStatus attendanceStatus,
    String? photoPath,
  });
  Future<AttendanceModel> checkOut({
    required String attendanceId,
    String? photoPath,
  });
  Future<List<AttendanceModel>> getHistory(String userId);
  Future<List<AttendanceModel>> getAll();
}
