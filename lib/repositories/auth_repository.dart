import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/token_manager.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthRepository implements AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TokenManager _tokenManager = TokenManager.instance;
  
  UserModel? _currentUser;

  @override
  Future<UserModel?> login(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Login gagal. Coba lagi.');
      }

      // Fetch user data from Firestore
      final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      if (!doc.exists) {
        throw Exception('Data pengguna tidak ditemukan di database.');
      }

      final userData = doc.data()!;
      _currentUser = UserModel.fromMap(userData);

      // We can also refresh/get token from Firebase
      final token = await firebaseUser.getIdToken();
      if (token != null) {
        _tokenManager.setTokens(
          accessToken: token,
          expiry: const Duration(hours: 1), // Optional depending on Firebase
        );
        _currentUser = _currentUser?.copyWith(token: token);
      }

      return _currentUser;
    } on FirebaseAuthException catch (e) {
      throw Exception('Autentikasi gagal: ${e.message}');
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  @override
  Future<void> logout() async {
    await _auth.signOut();
    _tokenManager.clearTokens();
    _currentUser = null;
  }

  @override
  UserModel? get currentUser => _currentUser;

  Future<String?> refreshToken() async {
    final user = _auth.currentUser;
    if (user != null) {
      final token = await user.getIdToken(true);
      if (token != null) {
        _tokenManager.setTokens(accessToken: token, expiry: const Duration(hours: 1));
        _currentUser = _currentUser?.copyWith(token: token);
        return token;
      }
    }
    return null;
  }
}
