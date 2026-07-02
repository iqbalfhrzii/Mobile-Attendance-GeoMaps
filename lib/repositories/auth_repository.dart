import '../core/constants.dart';
import '../core/enums.dart';
import '../core/token_manager.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

/// Dummy implementation of [AuthService] for development.
class AuthRepository implements AuthService {
  UserModel? _currentUser;
  final TokenManager _tokenManager = TokenManager.instance;

  // Dummy credentials map: email → password
  static final Map<String, String> _dummyPasswords = {
    AppConstants.adminEmail: AppConstants.adminPassword,
    AppConstants.employeeEmail: AppConstants.employeePassword,
  };

  // All dummy users (admin + employees)
  static final List<UserModel> _allUsers = [
    UserModel(
      id: 'USR001',
      employeeCode: 'ADM-001',
      fullName: 'Ahmad Fauzi',
      email: AppConstants.adminEmail,
      role: UserRole.admin,
      createdAt: DateTime(2024, 1, 1),
    ),
    UserModel(
      id: 'USR002',
      employeeCode: 'EMP-001',
      fullName: 'Budi Santoso',
      email: AppConstants.employeeEmail,
      role: UserRole.employee,
      createdAt: DateTime(2024, 2, 15),
    ),
    UserModel(
      id: 'USR003',
      employeeCode: 'EMP-002',
      fullName: 'Citra Dewi',
      email: 'citra@demo.com',
      role: UserRole.employee,
      createdAt: DateTime(2024, 3, 10),
    ),
    UserModel(
      id: 'USR004',
      employeeCode: 'EMP-003',
      fullName: 'Dimas Prayoga',
      email: 'dimas@demo.com',
      role: UserRole.employee,
      createdAt: DateTime(2024, 4, 5),
    ),
    UserModel(
      id: 'USR005',
      employeeCode: 'EMP-004',
      fullName: 'Eka Putri',
      email: 'eka@demo.com',
      role: UserRole.employee,
      createdAt: DateTime(2024, 5, 20),
    ),
    UserModel(
      id: 'USR006',
      employeeCode: 'EMP-005',
      fullName: 'Farhan Maulana',
      email: 'farhan@demo.com',
      role: UserRole.employee,
      createdAt: DateTime(2024, 6, 1),
    ),
  ];

  @override
  Future<UserModel?> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final storedPassword = _dummyPasswords[email];
    if (storedPassword == null || storedPassword != password) {
      throw Exception('Email atau password salah');
    }

    final dummyToken = 'token_${DateTime.now().millisecondsSinceEpoch}';
    _tokenManager.setTokens(
      accessToken: dummyToken,
      expiry: const Duration(hours: 1),
    );

    final user = _allUsers.firstWhere(
      (u) => u.email == email,
      orElse: () => throw Exception('User tidak ditemukan'),
    );

    _currentUser = user.copyWith(token: dummyToken);
    return _currentUser;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _tokenManager.clearTokens();
    _currentUser = null;
  }

  @override
  UserModel? get currentUser => _currentUser;

  Future<String?> refreshToken() async {
    if (_tokenManager.isTokenValid) return _tokenManager.accessToken;
    final newToken = 'token_${DateTime.now().millisecondsSinceEpoch}';
    _tokenManager.setTokens(accessToken: newToken, expiry: const Duration(hours: 1));
    _currentUser = _currentUser?.copyWith(token: newToken);
    return newToken;
  }
}
