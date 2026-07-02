import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/office_location_model.dart';

/// Repository for managing office locations in Firestore.
class OfficeLocationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'office_locations';

  /// Get all office locations.
  Future<List<OfficeLocationModel>> getAll() async {
    final snapshot = await _firestore.collection(_collectionPath).get();
    return snapshot.docs
        .map((doc) => OfficeLocationModel.fromMap(doc.data()))
        .toList();
  }

  /// Get location by ID.
  Future<OfficeLocationModel?> getById(String id) async {
    final doc = await _firestore.collection(_collectionPath).doc(id).get();
    if (!doc.exists) return null;
    return OfficeLocationModel.fromMap(doc.data()!);
  }

  /// Get the primary / default office location.
  /// If there are no locations in Firestore, it creates a default one.
  Future<OfficeLocationModel> getPrimary() async {
    final snapshot = await _firestore.collection(_collectionPath).limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      return OfficeLocationModel.fromMap(snapshot.docs.first.data());
    } else {
      // Create a default location if none exists
      final defaultLoc = const OfficeLocationModel(
        id: 'LOC001',
        name: 'Kantor Pusat',
        latitude: -7.9338,
        longitude: 112.6099,
        radiusMeter: 50.0,
      );
      await add(defaultLoc);
      return defaultLoc;
    }
  }

  /// Add a new office location.
  Future<OfficeLocationModel> add(OfficeLocationModel location) async {
    await _firestore
        .collection(_collectionPath)
        .doc(location.id)
        .set(location.toMap());
    return location;
  }

  /// Update an existing office location.
  Future<OfficeLocationModel> update(OfficeLocationModel location) async {
    await _firestore
        .collection(_collectionPath)
        .doc(location.id)
        .update(location.toMap());
    return location;
  }

  /// Delete an office location.
  Future<void> delete(String id) async {
    await _firestore.collection(_collectionPath).doc(id).delete();
  }
}
