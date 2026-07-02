import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/enums.dart';
import '../models/attendance_model.dart';
import '../services/supabase_storage_service.dart';

class AttendanceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SupabaseStorageService _storageService = SupabaseStorageService();
  
  // Using a single collection for attendances
  CollectionReference get _collection => _firestore.collection('attendances');

  /// Get today's attendance for a user.
  Future<AttendanceModel?> getTodayAttendance(String userId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();

    try {
      final snapshot = await _collection
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: startOfDay)
          .where('date', isLessThanOrEqualTo: endOfDay)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      return AttendanceModel.fromMap(doc.data() as Map<String, dynamic>);
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
    final existing = await getTodayAttendance(userId);
    if (existing != null) {
      throw Exception('Anda sudah melakukan absen masuk hari ini.');
    }

    final now = DateTime.now();
    String? publicPhotoUrl;

    if (photoPath != null) {
      final file = File(photoPath);
      final storagePath = await _storageService.uploadAttendanceSelfie(file, userId, 'checkin');
      publicPhotoUrl = _storageService.getPublicUrl(storagePath);
    }

    final docRef = _collection.doc();
    final record = AttendanceModel(
      id: docRef.id,
      userId: userId,
      employeeName: employeeName,
      date: DateTime(now.year, now.month, now.day),
      checkInTime: now,
      checkInPhotoPath: publicPhotoUrl,
      latitude: latitude,
      longitude: longitude,
      distanceFromOffice: distanceFromOffice,
      locationStatus: locationStatus,
      attendanceStatus: attendanceStatus,
      createdAt: now,
    );

    await docRef.set(record.toMap());
    return record;
  }

  /// Check out — update existing attendance record.
  Future<AttendanceModel> checkOut({
    required String attendanceId,
    String? photoPath,
  }) async {
    final docRef = _collection.doc(attendanceId);
    final doc = await docRef.get();

    if (!doc.exists) {
      throw Exception('Record absensi tidak ditemukan');
    }

    final currentRecord = AttendanceModel.fromMap(doc.data() as Map<String, dynamic>);

    if (!currentRecord.hasCheckedIn) {
      throw Exception('Anda belum melakukan absen masuk.');
    }

    if (currentRecord.hasCheckedOut) {
      throw Exception('Anda sudah melakukan absen pulang hari ini.');
    }

    String? publicPhotoUrl;
    if (photoPath != null) {
      final file = File(photoPath);
      final storagePath = await _storageService.uploadAttendanceSelfie(file, currentRecord.userId, 'checkout');
      publicPhotoUrl = _storageService.getPublicUrl(storagePath);
    }

    final updated = currentRecord.copyWith(
      checkOutTime: DateTime.now(),
      checkOutPhotoPath: publicPhotoUrl ?? currentRecord.checkOutPhotoPath,
    );

    await docRef.update(updated.toMap());
    return updated;
  }

  /// Get attendance history for a user.
  Future<List<AttendanceModel>> getHistory(String userId) async {
    final snapshot = await _collection
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => AttendanceModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  /// Get all attendance records (admin).
  Future<List<AttendanceModel>> getAll() async {
    final snapshot = await _collection.orderBy('date', descending: true).get();
    return snapshot.docs
        .map((doc) => AttendanceModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  /// Get attendance records by date range.
  Future<List<AttendanceModel>> getByDateRange(
    DateTime start,
    DateTime end, {
    String? userId,
  }) async {
    final startStr = start.toIso8601String();
    final endStr = end.toIso8601String();

    Query query = _collection
        .where('date', isGreaterThanOrEqualTo: startStr)
        .where('date', isLessThanOrEqualTo: endStr);

    if (userId != null) {
      query = query.where('userId', isEqualTo: userId);
    }

    final snapshot = await query.get();
    
    final list = snapshot.docs
        .map((doc) => AttendanceModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
    
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }
}
