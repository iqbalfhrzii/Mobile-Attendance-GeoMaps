import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import '../repositories/user_repository.dart';

/// Provides the [UserRepository] singleton.
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

/// All users.
final allUsersProvider = FutureProvider<List<UserModel>>((ref) async {
  final repo = ref.watch(userRepositoryProvider);
  return repo.getAll();
});

/// Employees only.
final employeesProvider = FutureProvider<List<UserModel>>((ref) async {
  final repo = ref.watch(userRepositoryProvider);
  return repo.getEmployees();
});

/// Employee count.
final employeeCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(userRepositoryProvider);
  return repo.employeeCount();
});
