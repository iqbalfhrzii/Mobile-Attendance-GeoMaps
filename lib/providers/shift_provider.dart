import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/shift_model.dart';
import '../repositories/shift_repository.dart';

/// Provides the [ShiftRepository] singleton.
final shiftRepositoryProvider = Provider<ShiftRepository>((ref) {
  return ShiftRepository();
});

/// All shifts.
final allShiftsProvider = FutureProvider<List<ShiftModel>>((ref) async {
  final repo = ref.watch(shiftRepositoryProvider);
  return repo.getAll();
});

/// Default / primary shift.
final defaultShiftProvider = FutureProvider<ShiftModel>((ref) async {
  final repo = ref.watch(shiftRepositoryProvider);
  return repo.getDefault();
});

/// Globally selected shift ID for the UI
final selectedShiftIdProvider = StateProvider<String?>((ref) => null);

class ShiftNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> addShift(ShiftModel shift) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(shiftRepositoryProvider);
      await repo.add(shift);
      ref.invalidate(allShiftsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateShift(ShiftModel shift) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(shiftRepositoryProvider);
      await repo.update(shift);
      ref.invalidate(allShiftsProvider);
      ref.invalidate(defaultShiftProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteShift(String id) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(shiftRepositoryProvider);
      await repo.delete(id);
      ref.invalidate(allShiftsProvider);
      ref.invalidate(defaultShiftProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final shiftNotifierProvider = AsyncNotifierProvider<ShiftNotifier, void>(() {
  return ShiftNotifier();
});
