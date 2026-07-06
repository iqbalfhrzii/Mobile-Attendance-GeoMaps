import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/office_location_model.dart';

/// Repository for managing office locations in Supabase.
class OfficeLocationRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final String _tableName = 'office_locations';

  /// Get all office locations.
  Future<List<OfficeLocationModel>> getAll() async {
    final data = await _supabase.from(_tableName).select()
        .timeout(const Duration(seconds: 15), onTimeout: () => throw Exception('Koneksi lambat saat mengambil lokasi kantor.'));
    return data
        .map((map) => OfficeLocationModel.fromMap(map))
        .toList();
  }

  /// Get location by ID.
  Future<OfficeLocationModel?> getById(String id) async {
    final data = await _supabase.from(_tableName).select().eq('id', id).maybeSingle()
        .timeout(const Duration(seconds: 15), onTimeout: () => throw Exception('Koneksi lambat saat mengambil lokasi kantor.'));
    if (data == null) return null;
    return OfficeLocationModel.fromMap(data);
  }

  /// Get the primary / default office location.
  /// If there are no locations, it creates a default one.
  Future<OfficeLocationModel> getPrimary() async {
    final data = await _supabase.from(_tableName).select().limit(1).maybeSingle()
        .timeout(const Duration(seconds: 15), onTimeout: () => throw Exception('Koneksi lambat saat mengambil lokasi kantor utama.'));
        
    if (data != null) {
      return OfficeLocationModel.fromMap(data);
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
    await _supabase.from(_tableName).insert(location.toMap())
        .timeout(const Duration(seconds: 15), onTimeout: () => throw Exception('Gagal menyimpan lokasi kantor karena internet lambat.'));
    return location;
  }

  /// Update an existing office location.
  Future<OfficeLocationModel> update(OfficeLocationModel location) async {
    await _supabase.from(_tableName).update(location.toMap()).eq('id', location.id)
        .timeout(const Duration(seconds: 15), onTimeout: () => throw Exception('Gagal memperbarui lokasi kantor karena internet lambat.'));
    return location;
  }

  /// Delete an office location.
  Future<void> delete(String id) async {
    await _supabase.from(_tableName).delete().eq('id', id)
        .timeout(const Duration(seconds: 15), onTimeout: () => throw Exception('Gagal menghapus lokasi kantor karena internet lambat.'));
  }
}
