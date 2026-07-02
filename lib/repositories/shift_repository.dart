import '../models/shift_model.dart';

/// Dummy repository for managing work shifts.
class ShiftRepository {
  final List<ShiftModel> _shifts = [
    const ShiftModel(
      id: 'SHF001',
      name: 'Shift Pagi',
      checkInTime: '08:00',
      checkOutTime: '16:00',
      lateToleranceMinutes: 15,
    ),
  ];

  /// Get all shifts.
  Future<List<ShiftModel>> getAll() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.from(_shifts);
  }

  /// Get shift by ID.
  Future<ShiftModel?> getById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _shifts.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get the default / primary shift.
  Future<ShiftModel> getDefault() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _shifts.first;
  }

  /// Add a new shift.
  Future<ShiftModel> add(ShiftModel shift) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _shifts.add(shift);
    return shift;
  }

  /// Update an existing shift.
  Future<ShiftModel> update(ShiftModel shift) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _shifts.indexWhere((s) => s.id == shift.id);
    if (index == -1) throw Exception('Shift tidak ditemukan');
    _shifts[index] = shift;
    return shift;
  }

  /// Delete a shift.
  Future<void> delete(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _shifts.removeWhere((s) => s.id == id);
  }
}
