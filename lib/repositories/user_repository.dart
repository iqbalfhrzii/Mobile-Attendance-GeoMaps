import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';
import '../core/enums.dart';
import '../models/user_model.dart';

/// Repository for managing employee/user data in Supabase.
class UserRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final String _tableName = 'users';

  /// Get all users.
  Future<List<UserModel>> getAll() async {
    final data = await _supabase.from(_tableName).select()
        .timeout(const Duration(seconds: 15), onTimeout: () => throw Exception('Koneksi lambat saat mengambil data pengguna.'));
    return data.map((map) => UserModel.fromMap(map)).toList();
  }

  /// Get all employees only (excluding admin).
  Future<List<UserModel>> getEmployees() async {
    final data = await _supabase
        .from(_tableName)
        .select()
        .eq('role', UserRole.employee.name)
        .timeout(const Duration(seconds: 15), onTimeout: () => throw Exception('Koneksi lambat saat mengambil data karyawan.'));
    return data.map((map) => UserModel.fromMap(map)).toList();
  }

  /// Get a user by ID.
  Future<UserModel?> getById(String id) async {
    final data = await _supabase.from(_tableName).select().eq('id', id).maybeSingle()
        .timeout(const Duration(seconds: 15), onTimeout: () => throw Exception('Koneksi lambat saat mengambil profil.'));
    if (data == null) return null;
    return UserModel.fromMap(data);
  }

  /// Get a user by employee code.
  Future<UserModel?> getByEmployeeCode(String code) async {
    final data = await _supabase
        .from(_tableName)
        .select()
        .eq('employeeCode', code)
        .maybeSingle()
        .timeout(const Duration(seconds: 15), onTimeout: () => throw Exception('Koneksi lambat saat mencari karyawan.'));
    if (data == null) return null;
    return UserModel.fromMap(data);
  }

  /// Add a new user (admin functionality).
  Future<UserModel> add(UserModel user, {required String password}) async {
    final secondaryClient = SupabaseClient(
      AppConstants.supabaseUrl,
      AppConstants.supabaseAnonKey,
    );

    try {
      final authResponse = await secondaryClient.auth.signUp(
        email: user.email,
        password: password,
      );

      final uid = authResponse.user!.id;
      final newUser = user.copyWith(id: uid);

      // Insert into public users table using the main client
      final userMap = newUser.toMap();
      userMap['password'] = password; // Save plain-text password for admin view
      
      await _supabase.from(_tableName).insert(userMap)
          .timeout(const Duration(seconds: 15), onTimeout: () => throw Exception('Gagal menyimpan data pengguna karena internet lambat.'));
      
      secondaryClient.dispose();
      return newUser;
    } catch (e) {
      secondaryClient.dispose();
      throw Exception('Gagal membuat user: $e');
    }
  }

  /// Update an existing user.
  Future<UserModel> update(UserModel user) async {
    await _supabase.from(_tableName).update(user.toMap()).eq('id', user.id)
        .timeout(const Duration(seconds: 15), onTimeout: () => throw Exception('Gagal memperbarui data pengguna karena internet lambat.'));
    return user;
  }

  /// Delete a user by ID.
  Future<void> delete(String id) async {
    // Delete from public table
    await _supabase.from(_tableName).delete().eq('id', id)
        .timeout(const Duration(seconds: 15), onTimeout: () => throw Exception('Gagal menghapus data pengguna karena internet lambat.'));
        
    // Optionally delete from auth using admin API
    try {
      await _supabase.auth.admin.deleteUser(id);
    } catch (_) {
      // ignore
    }
  }

  /// Get total user count.
  Future<int> count() async {
    final response = await _supabase.from(_tableName).select('id').count(CountOption.exact)
        .timeout(const Duration(seconds: 15));
    return response.count;
  }

  /// Get employee count only.
  Future<int> employeeCount() async {
    final response = await _supabase
        .from(_tableName)
        .select('id')
        .eq('role', UserRole.employee.name)
        .count(CountOption.exact)
        .timeout(const Duration(seconds: 15));
    return response.count;
  }
}
