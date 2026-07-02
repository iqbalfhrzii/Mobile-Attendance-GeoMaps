import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../core/enums.dart';
import '../models/user_model.dart';

/// Repository for managing employee/user data in Firestore.
class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'users';

  /// Get all users.
  Future<List<UserModel>> getAll() async {
    final snapshot = await _firestore.collection(_collectionPath).get();
    return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
  }

  /// Get all employees only (excluding admin).
  Future<List<UserModel>> getEmployees() async {
    final snapshot = await _firestore
        .collection(_collectionPath)
        .where('role', isEqualTo: UserRole.employee.name)
        .get();
    return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
  }

  /// Get a user by ID.
  Future<UserModel?> getById(String id) async {
    final doc = await _firestore.collection(_collectionPath).doc(id).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!);
  }

  /// Get a user by employee code.
  Future<UserModel?> getByEmployeeCode(String code) async {
    final snapshot = await _firestore
        .collection(_collectionPath)
        .where('employeeCode', isEqualTo: code)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return UserModel.fromMap(snapshot.docs.first.data());
  }

  /// Add a new user (Creates Firebase Auth account and Firestore document).
  Future<UserModel> add(UserModel user, {required String password}) async {
    // We use a secondary Firebase app to create the user so the current admin doesn't get logged out
    FirebaseApp secondaryApp = await Firebase.initializeApp(
      name: 'SecondaryApp',
      options: Firebase.app().options,
    );

    try {
      final userCredential = await FirebaseAuth.instanceFor(app: secondaryApp)
          .createUserWithEmailAndPassword(
        email: user.email,
        password: password,
      );

      final uid = userCredential.user!.uid;
      final newUser = user.copyWith(id: uid);

      await _firestore.collection(_collectionPath).doc(uid).set(newUser.toMap());
      
      await secondaryApp.delete();
      return newUser;
    } catch (e) {
      await secondaryApp.delete();
      throw Exception('Gagal membuat user: $e');
    }
  }

  /// Update an existing user.
  Future<UserModel> update(UserModel user) async {
    await _firestore.collection(_collectionPath).doc(user.id).update(user.toMap());
    return user;
  }

  /// Delete a user by ID.
  Future<void> delete(String id) async {
    // Note: This only deletes the Firestore document.
    // Deleting the Firebase Auth user requires Admin SDK or Cloud Functions,
    // so we'll just remove their data for now.
    await _firestore.collection(_collectionPath).doc(id).delete();
  }

  /// Get total user count.
  Future<int> count() async {
    final snapshot = await _firestore.collection(_collectionPath).count().get();
    return snapshot.count ?? 0;
  }

  /// Get employee count only.
  Future<int> employeeCount() async {
    final snapshot = await _firestore
        .collection(_collectionPath)
        .where('role', isEqualTo: UserRole.employee.name)
        .count()
        .get();
    return snapshot.count ?? 0;
  }
}
