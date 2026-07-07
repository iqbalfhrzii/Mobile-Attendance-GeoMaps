import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../services/location_service.dart';
import 'camera_page.dart';

/// Confirmation page showing GPS location details before proceeding to camera.
class LocationConfirmPage extends StatelessWidget {
  final LocationResult locationResult;
  final bool isCheckIn;
  final String? attendanceId; // needed for check-out
  final String? shiftId;
  final String? shiftName;
  final bool isEarlyLeave;

  const LocationConfirmPage({
    super.key,
    required this.locationResult,
    required this.isCheckIn,
    this.attendanceId,
    this.shiftId,
    this.shiftName,
    this.isEarlyLeave = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = locationResult;
    final isInside = loc.isInsideRadius;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Konfirmasi Lokasi'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Status indicator
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: isInside
                    ? AppTheme.successGreen.withAlpha(20)
                    : AppTheme.errorRed.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isInside
                    ? Icons.location_on_rounded
                    : Icons.location_off_rounded,
                size: 44,
                color: isInside ? AppTheme.successGreen : AppTheme.errorRed,
              ),
            ),
            const SizedBox(height: 20),

            // Status text
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isInside
                    ? AppTheme.successGreen.withAlpha(15)
                    : AppTheme.errorRed.withAlpha(15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isInside
                      ? AppTheme.successGreen.withAlpha(40)
                      : AppTheme.errorRed.withAlpha(40),
                ),
              ),
              child: Text(
                isInside ? '✅ Di Dalam Area Kantor' : '⚠️ Di Luar Area Kantor',
                style: TextStyle(
                  color: isInside ? AppTheme.successGreen : AppTheme.errorRed,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Location details card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _detailRow(
                      context,
                      'Lokasi Anda',
                      '${loc.latitude.toStringAsFixed(5)}, ${loc.longitude.toStringAsFixed(5)}',
                      Icons.person_pin_circle_rounded,
                    ),
                    const Divider(height: 16),
                    _detailRow(
                      context,
                      'Lokasi Kantor',
                      '${loc.officeLatitude.toStringAsFixed(5)}, ${loc.officeLongitude.toStringAsFixed(5)}',
                      Icons.business_rounded,
                    ),
                    const Divider(height: 16),
                    _detailRow(
                      context,
                      'Jarak dari Kantor',
                      '${loc.distanceFromOffice.toStringAsFixed(1)} meter',
                      Icons.straighten_rounded,
                    ),
                    const Divider(height: 24),
                    _detailRow(
                      context,
                      'Status',
                      isInside ? 'Di Dalam Radius' : 'Di Luar Radius',
                      Icons.shield_rounded,
                      valueColor:
                          isInside ? AppTheme.successGreen : AppTheme.errorRed,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Warning for outside radius
            if (!isInside)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.warningOrange.withAlpha(12),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppTheme.warningOrange.withAlpha(30)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: AppTheme.warningOrange, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Anda berada di luar radius kantor. Absensi tetap bisa dilakukan tetapi akan tercatat.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.warningOrange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 32),

            // Buttons
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CameraPage(
                        locationResult: locationResult,
                        isCheckIn: isCheckIn,
                        attendanceId: attendanceId,
                        shiftId: shiftId,
                        shiftName: shiftName,
                        isEarlyLeave: isEarlyLeave,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.camera_alt_rounded, size: 20),
                label: const Text('Lanjutkan — Ambil Selfie'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Batal'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(120),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
