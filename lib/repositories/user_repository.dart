import '../core/enums.dart';
import '../models/user_model.dart';

/// Dummy repository for managing employee/user data.
class UserRepository {
  final List<UserModel> _users = [
    UserModel(
      id: 'USR001',
      employeeCode: 'ADM-001',
      fullName: 'Ahmad Fauzi',
      email: 'admin@demo.com',
      role: UserRole.admin,
      createdAt: DateTime(2024, 1, 1),
    ),
    UserModel(
      id: 'USR002',
      employeeCode: 'EMP-001',
      fullName: 'Budi Santoso',
      email: 'employee@demo.com',
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

  /// Get all users.
  Future<List<UserModel>> getAll() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_users);
  }

  /// Get all employees only (excluding admin).
  Future<List<UserModel>> getEmployees() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _users.where((u) => u.role == UserRole.employee).toList();
  }

  /// Get a user by ID.
  Future<UserModel?> getById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _users.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get a user by employee code.
  Future<UserModel?> getByEmployeeCode(String code) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _users.firstWhere((u) => u.employeeCode == code);
    } catch (_) {
      return null;
    }
  }

  /// Add a new user.
  Future<UserModel> add(UserModel user) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _users.add(user);
    return user;
  }

  /// Update an existing user.
  Future<UserModel> update(UserModel user) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _users.indexWhere((u) => u.id == user.id);
    if (index == -1) throw Exception('User tidak ditemukan');
    _users[index] = user;
    return user;
  }

  /// Delete a user by ID.
  Future<void> delete(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _users.removeWhere((u) => u.id == id);
  }

  /// Get total user count.
  Future<int> count() async {
    return _users.length;
  }

  /// Get employee count only.
  Future<int> employeeCount() async {
    return _users.where((u) => u.role == UserRole.employee).length;
  }
}
