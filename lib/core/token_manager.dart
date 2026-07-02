/// Manages authentication tokens.
///
/// Currently in-memory only. When Firebase is integrated, this will
/// use `firebase_auth` for ID tokens and optionally `flutter_secure_storage`
/// for refresh tokens.
class TokenManager {
  TokenManager._();
  static final TokenManager instance = TokenManager._();

  String? _accessToken;
  String? _refreshToken;
  DateTime? _tokenExpiry;

  /// Current access token (Firebase ID token).
  String? get accessToken => _accessToken;

  /// Current refresh token.
  String? get refreshToken => _refreshToken;

  /// Whether the token is still valid.
  bool get isTokenValid {
    if (_accessToken == null || _tokenExpiry == null) return false;
    // Add 30-second buffer before actual expiry
    return DateTime.now().isBefore(
      _tokenExpiry!.subtract(const Duration(seconds: 30)),
    );
  }

  /// Whether we have any token at all (may be expired).
  bool get hasToken => _accessToken != null;

  /// Store tokens after login / token refresh.
  void setTokens({
    required String accessToken,
    String? refreshToken,
    Duration expiry = const Duration(hours: 1),
  }) {
    _accessToken = accessToken;
    _refreshToken = refreshToken ?? _refreshToken;
    _tokenExpiry = DateTime.now().add(expiry);
  }

  /// Clear all tokens on logout.
  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
    _tokenExpiry = null;
  }

  /// Returns the Authorization header value.
  /// Usage: `headers['Authorization'] = tokenManager.authHeader;`
  String? get authHeader {
    if (_accessToken == null) return null;
    return 'Bearer $_accessToken';
  }

  /// Returns a complete headers map ready for API calls.
  Map<String, String> get authHeaders {
    return {
      'Content-Type': 'application/json',
      if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
    };
  }
}
