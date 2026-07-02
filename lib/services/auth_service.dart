import '../models/user_model.dart';

/// Abstract interface for authentication operations.
abstract class AuthService {
  Future<UserModel?> login(String email, String password);
  Future<void> logout();
  UserModel? get currentUser;
}
