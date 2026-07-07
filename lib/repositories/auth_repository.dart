import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/token_manager.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthRepository implements AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TokenManager _tokenManager = TokenManager.instance;
  
  UserModel? _currentUser;

  @override
  Future<UserModel?> login(String email, String password) async {
    try {
      final authResponse = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      ).timeout(const Duration(seconds: 30), onTimeout: () {
        throw Exception('Koneksi internet lambat saat memverifikasi akun.');
      });

      final user = authResponse.user;
      final session = authResponse.session;

      if (user == null || session == null) {
        throw Exception('Login gagal. Coba lagi.');
      }

      // Fetch user data from Supabase 'users' table
      final data = await _supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle()
          .timeout(const Duration(seconds: 15), onTimeout: () {
            throw Exception('Koneksi lambat saat mengambil profil pengguna.');
          });
      
      if (data == null) {
        throw Exception('Data pengguna tidak ditemukan di database.');
      }

      _currentUser = UserModel.fromMap(data);

      final token = session.accessToken;
      _tokenManager.setTokens(
        accessToken: token,
        expiry: const Duration(hours: 1),
      );
      _currentUser = _currentUser?.copyWith(token: token);

      return _currentUser;
    } on AuthException catch (e) {
      if (e.message.contains('Invalid login credentials')) {
        throw Exception('Email atau password salah.');
      }
      throw Exception('Autentikasi gagal: ${e.message}');
    } catch (e) {
      if (e.toString().contains('Koneksi')) rethrow; // keep timeout messages
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  @override
  Future<void> logout() async {
    await _supabase.auth.signOut();
    _tokenManager.clearTokens();
    _currentUser = null;
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('Sesi tidak ditemukan. Silakan login ulang.');
    }
    try {
      // In Supabase, to change password securely, you can either just update it if the user is logged in
      // but to strictly require the current password, we can try to sign in with it first to verify.
      await _supabase.auth.signInWithPassword(
        email: user.email!,
        password: currentPassword,
      ).timeout(const Duration(seconds: 15), onTimeout: () {
        throw Exception('Koneksi internet lambat saat memverifikasi password.');
      });
      
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      ).timeout(const Duration(seconds: 15), onTimeout: () {
        throw Exception('Koneksi internet lambat saat menyimpan password.');
      });

      // Update plain-text password in users table
      await _supabase.from('users').update({'password': newPassword}).eq('id', user.id)
          .timeout(const Duration(seconds: 15));

    } on AuthException catch (e) {
      if (e.message.contains('Invalid login credentials')) {
        throw Exception('Password saat ini salah.');
      }
      throw Exception('Gagal mengganti password: ${e.message}');
    } catch (e) {
      if (e is TimeoutException || e.toString().contains('Timeout')) {
        throw Exception('Koneksi internet lambat. Permintaan kehabisan waktu.');
      }
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  @override
  UserModel? get currentUser => _currentUser;

  Future<UserModel?> checkAuthStatus() async {
    final session = _supabase.auth.currentSession;
    if (session != null && session.user != null) {
      try {
        final data = await _supabase
            .from('users')
            .select()
            .eq('id', session.user.id)
            .maybeSingle()
            .timeout(const Duration(seconds: 15));
            
        if (data != null) {
          _currentUser = UserModel.fromMap(data);
          final token = session.accessToken;
          _tokenManager.setTokens(accessToken: token, expiry: const Duration(hours: 1));
          _currentUser = _currentUser?.copyWith(token: token);
          return _currentUser;
        }
      } catch (e) {
        await logout();
      }
    }
    return null;
  }

  Future<String?> refreshToken() async {
    final session = _supabase.auth.currentSession;
    if (session != null) {
      try {
        final response = await _supabase.auth.refreshSession();
        final newToken = response.session?.accessToken;
        if (newToken != null) {
          _tokenManager.setTokens(accessToken: newToken, expiry: const Duration(hours: 1));
          _currentUser = _currentUser?.copyWith(token: newToken);
          return newToken;
        }
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}
