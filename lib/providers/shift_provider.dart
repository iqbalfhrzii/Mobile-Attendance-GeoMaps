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
