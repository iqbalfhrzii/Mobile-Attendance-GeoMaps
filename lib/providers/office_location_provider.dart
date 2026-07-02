import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/office_location_model.dart';
import '../repositories/office_location_repository.dart';

/// Provides the [OfficeLocationRepository] singleton.
final officeLocationRepositoryProvider =
    Provider<OfficeLocationRepository>((ref) {
  return OfficeLocationRepository();
});

/// All office locations.
final officeLocationsProvider =
    FutureProvider<List<OfficeLocationModel>>((ref) async {
  final repo = ref.watch(officeLocationRepositoryProvider);
  return repo.getAll();
});

/// Primary office location.
final primaryOfficeProvider =
    FutureProvider<OfficeLocationModel>((ref) async {
  final repo = ref.watch(officeLocationRepositoryProvider);
  return repo.getPrimary();
});
