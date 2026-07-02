import 'package:geolocator/geolocator.dart';

/// Data class holding the result of a location check.
class LocationResult {
  final double latitude;
  final double longitude;
  final double officeLatitude;
  final double officeLongitude;
  final double distanceFromOffice;
  final bool isInsideRadius;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    required this.officeLatitude,
    required this.officeLongitude,
    required this.distanceFromOffice,
    required this.isInsideRadius,
  });
}

/// Service for GPS location operations.
class LocationService {
  /// Check if location services are enabled and permission is granted.
  /// Returns `true` if ready, throws descriptive error otherwise.
  Future<bool> checkPermission() async {
    // Check if location services are enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Layanan lokasi tidak aktif. Aktifkan GPS di pengaturan.');
    }

    // Check permission
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Izin lokasi ditolak.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Izin lokasi ditolak permanen. Buka pengaturan untuk mengizinkan.',
      );
    }

    return true;
  }

  /// Get the current GPS position.
  Future<Position> getCurrentPosition() async {
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }

  /// Calculate distance (in meters) between user position and office.
  double calculateDistance({
    required double userLat,
    required double userLng,
    required double officeLat,
    required double officeLng,
  }) {
    return Geolocator.distanceBetween(
      userLat,
      userLng,
      officeLat,
      officeLng,
    );
  }

  /// Full flow: check permission → get position → calculate distance.
  Future<LocationResult> getLocationAndDistance({
    required double officeLat,
    required double officeLng,
    required double radiusMeter,
  }) async {
    await checkPermission();
    final position = await getCurrentPosition();

    final distance = calculateDistance(
      userLat: position.latitude,
      userLng: position.longitude,
      officeLat: officeLat,
      officeLng: officeLng,
    );

    return LocationResult(
      latitude: position.latitude,
      longitude: position.longitude,
      officeLatitude: officeLat,
      officeLongitude: officeLng,
      distanceFromOffice: distance,
      isInsideRadius: distance <= radiusMeter,
    );
  }
}
