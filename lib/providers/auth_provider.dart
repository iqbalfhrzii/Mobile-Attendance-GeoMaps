import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/token_manager.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

/// Provides the [AuthRepository] singleton.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Provides the [TokenManager] singleton.
final tokenManagerProvider = Provider<TokenManager>((ref) {
  return TokenManager.instance;
});

/// Auth state — holds the currently logged-in user (or null).
final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AsyncValue<UserModel?>>(
  (ref) => AuthStateNotifier(ref.watch(authRepositoryProvider)),
);

/// Convenience provider for the current user.
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

/// Current access token.
final currentTokenProvider = Provider<String?>((ref) {
  return ref.watch(currentUserProvider)?.token;
});

/// Whether a user is logged in.
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});

/// Whether the current token is still valid.
final isTokenValidProvider = Provider<bool>((ref) {
  final tokenManager = ref.watch(tokenManagerProvider);
  return tokenManager.isTokenValid;
});

// ─── State Notifier ────────────────────────────────────────────────────────

class AuthStateNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthRepository _repository;

  AuthStateNotifier(this._repository)
      : super(const AsyncValue.data(null));

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.login(email, password);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AsyncValue.data(null);
  }

  /// Refresh the access token and update user state.
  Future<void> refreshToken() async {
    try {
      final newToken = await _repository.refreshToken();
      final currentUser = state.valueOrNull;
      if (currentUser != null && newToken != null) {
        state = AsyncValue.data(currentUser.copyWith(token: newToken));
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
