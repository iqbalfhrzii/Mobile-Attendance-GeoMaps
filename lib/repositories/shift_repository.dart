import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/shift_model.dart';

/// Repository for managing work shifts in Supabase.
class ShiftRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final String _tableName = 'shifts';

  /// Get all shifts.
  Future<List<ShiftModel>> getAll() async {
    final data = await _supabase.from(_tableName).select().order('name');
    return data.map((map) => ShiftModel.fromMap(map)).toList();
  }

  /// Get shift by ID.
  Future<ShiftModel?> getById(String id) async {
    try {
      final data = await _supabase
          .from(_tableName)
          .select()
          .eq('id', id)
          .maybeSingle();
      if (data == null) return null;
      return ShiftModel.fromMap(data);
    } catch (_) {
      return null;
    }
  }

  /// Get the default / primary shift.
  Future<ShiftModel> getDefault() async {
    final data = await _supabase
        .from(_tableName)
        .select()
        .limit(1)
        .maybeSingle();
        
    if (data == null) {
      // Fallback if no shift exists in DB yet
      return const ShiftModel(
        id: 'SHF001',
        name: 'Shift Pagi',
        checkInTime: '08:00',
        checkOutTime: '16:00',
        lateToleranceMinutes: 15,
      );
    }
    return ShiftModel.fromMap(data);
  }

  /// Add a new shift.
  Future<ShiftModel> add(ShiftModel shift) async {
    final data = await _supabase
        .from(_tableName)
        .insert(shift.toMap())
        .select()
        .single();
    return ShiftModel.fromMap(data);
  }

  /// Update an existing shift.
  Future<ShiftModel> update(ShiftModel shift) async {
    final data = await _supabase
        .from(_tableName)
        .update(shift.toMap())
        .eq('id', shift.id)
        .select()
        .single();
    return ShiftModel.fromMap(data);
  }

  /// Delete a shift.
  Future<void> delete(String id) async {
    await _supabase.from(_tableName).delete().eq('id', id);
  }
}
