import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';

class SupabaseStorageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Uploads a selfie image to Supabase Storage and returns the file path.
  /// Folder structure: `attendance-selfies/userId/yyyy-MM-dd/attendanceType_timestamp.jpg`
  Future<String> uploadAttendanceSelfie(
      File imageFile, String userId, String attendanceType) async {
    try {
      final now = DateTime.now();
      final dateStr = DateFormat('yyyy-MM-dd').format(now);
      final timestamp = now.millisecondsSinceEpoch.toString();
      final fileName = '${attendanceType}_$timestamp.jpg';

      final path = '$userId/$dateStr/$fileName';

      await _supabase.storage
          .from(AppConstants.supabaseBucketName)
          .upload(path, imageFile,
              fileOptions: const FileOptions(cacheControl: '3600', upsert: false));

      return path;
    } catch (e) {
      throw Exception('Failed to upload selfie: $e');
    }
  }

  /// Retrieves the public URL for a given storage path.
  String getPublicUrl(String path) {
    return _supabase.storage
        .from(AppConstants.supabaseBucketName)
        .getPublicUrl(path);
  }
}
