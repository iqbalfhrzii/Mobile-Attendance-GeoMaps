import '../models/office_location_model.dart';

/// Dummy repository for managing office locations.
class OfficeLocationRepository {
  final List<OfficeLocationModel> _locations = [
    const OfficeLocationModel(
      id: 'LOC001',
      name: 'Kantor Pusat Jakarta',
      latitude: -6.2088,
      longitude: 106.8456,
      radiusMeter: 100.0,
    ),
  ];

  /// Get all office locations.
  Future<List<OfficeLocationModel>> getAll() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.from(_locations);
  }

  /// Get location by ID.
  Future<OfficeLocationModel?> getById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _locations.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get the primary / default office location.
  Future<OfficeLocationModel> getPrimary() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _locations.first;
  }

  /// Add a new office location.
  Future<OfficeLocationModel> add(OfficeLocationModel location) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _locations.add(location);
    return location;
  }

  /// Update an existing office location.
  Future<OfficeLocationModel> update(OfficeLocationModel location) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _locations.indexWhere((l) => l.id == location.id);
    if (index == -1) throw Exception('Lokasi tidak ditemukan');
    _locations[index] = location;
    return location;
  }

  /// Delete an office location.
  Future<void> delete(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _locations.removeWhere((l) => l.id == id);
  }
}
