import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/enums.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/shift_provider.dart';
import '../../services/location_service.dart';
import '../../services/notification_service.dart';

/// Preview page showing selfie + location data before saving attendance.
class AttendancePreviewPage extends ConsumerStatefulWidget {
  final String photoPath;
  final LocationResult locationResult;
  final bool isCheckIn;
  final String? attendanceId;
  final String? shiftId;
  final String? shiftName;
  final bool isEarlyLeave;

  const AttendancePreviewPage({
    super.key,
    required this.photoPath,
    required this.locationResult,
    required this.isCheckIn,
    this.attendanceId,
    this.shiftId,
    this.shiftName,
    this.isEarlyLeave = false,
  });

  @override
  ConsumerState<AttendancePreviewPage> createState() =>
      _AttendancePreviewPageState();
}

class _AttendancePreviewPageState extends ConsumerState<AttendancePreviewPage> {
  bool _isSaving = false;

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final notifier = ref.read(todayAttendanceProvider.notifier);
      final loc = widget.locationResult;

      if (widget.isCheckIn) {
        // Cek status keterlambatan
        final shifts = await ref.read(allShiftsProvider.future);
        final shift = shifts.firstWhere((s) => s.id == widget.shiftId, orElse: () => shifts.first);
        final isLate = shift.isLate(DateTime.now());
        final status = isLate ? AttendanceStatus.late_ : AttendanceStatus.present;

        await notifier.checkIn(
          shiftId: widget.shiftId!,
          shiftName: widget.shiftName!,
          latitude: loc.latitude,
          longitude: loc.longitude,
          distanceFromOffice: loc.distanceFromOffice,
          locationStatus: loc.isInsideRadius
              ? LocationStatus.inside
              : LocationStatus.outside,
          attendanceStatus: status,
          photoPath: widget.photoPath,
        );

        // Schedule notification for end of shift
        if (!shift.isCasual) {
           final now = DateTime.now();
           DateTime targetTime = DateTime(now.year, now.month, now.day, shift.checkOutHour, shift.checkOutMinute);
           
           final checkInMinutes = shift.checkInHour * 60 + shift.checkInMinute;
           final checkOutMinutes = shift.checkOutHour * 60 + shift.checkOutMinute;
           
           if (checkInMinutes > checkOutMinutes) {
             final nowMinutes = now.hour * 60 + now.minute;
             if (nowMinutes >= checkInMinutes) {
                targetTime = targetTime.add(const Duration(days: 1));
             }
           }
           
           await NotificationService().scheduleCheckoutReminder(targetTime);
        }
      } else {
        await notifier.checkOut(
          widget.attendanceId!,
          photoPath: widget.photoPath,
          attendanceStatus: widget.isEarlyLeave ? AttendanceStatus.earlyLeave : null,
        );
        await NotificationService().cancelCheckoutReminder();
      }

      if (!mounted) return;
      
      // Clear override attendance so AttendancePage resets to today's state
      ref.read(overrideAttendanceProvider.notifier).state = null;

      // Pop all the way back to the attendance page
      Navigator.of(context).popUntil((route) => route.isFirst);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isCheckIn
                ? '✅ Absen masuk berhasil disimpan'
                : '✅ Absen pulang berhasil disimpan',
          ),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan: $e'),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final loc = widget.locationResult;
    final now = DateTime.now();
    final dateStr = DateFormat('dd MMMM yyyy', 'id_ID').format(now);
    final timeStr = DateFormat('HH:mm:ss').format(now);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isCheckIn
            ? 'Preview Absen Masuk'
            : 'Preview Absen Pulang'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Selfie photo
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: double.infinity,
                height: 280,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(30),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Image.file(
                  File(widget.photoPath),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Detail card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // User info
                    _infoRow(
                      context,
                      'Nama',
                      user?.fullName ?? '-',
                      Icons.person_outline_rounded,
                    ),
                    if (widget.isCheckIn && widget.shiftName != null) ...[
                      const Divider(height: 20),
                      _infoRow(
                        context,
                        'Jadwal Shift',
                        widget.shiftName!,
                        Icons.schedule_rounded,
                      ),
                    ],
                    const Divider(height: 20),
                    _infoRow(
                      context,
                      'Tanggal',
                      dateStr,
                      Icons.calendar_today_rounded,
                    ),
                    const Divider(height: 20),
                    _infoRow(
                      context,
                      'Jam',
                      timeStr,
                      Icons.access_time_rounded,
                    ),
                    const Divider(height: 20),
                    _infoRow(
                      context,
                      'Latitude',
                      loc.latitude.toStringAsFixed(6),
                      Icons.my_location_rounded,
                    ),
                    const Divider(height: 20),
                    _infoRow(
                      context,
                      'Longitude',
                      loc.longitude.toStringAsFixed(6),
                      Icons.my_location_rounded,
                    ),
                    const Divider(height: 20),
                    _infoRow(
                      context,
                      'Jarak',
                      '${loc.distanceFromOffice.toStringAsFixed(1)} meter',
                      Icons.straighten_rounded,
                    ),
                    const Divider(height: 20),
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.shield_rounded,
                              color: theme.colorScheme.primary, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Status Lokasi',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withAlpha(100),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: loc.isInsideRadius
                                    ? AppTheme.successGreen.withAlpha(15)
                                    : AppTheme.errorRed.withAlpha(15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                loc.isInsideRadius
                                    ? '✅ Di Dalam Radius'
                                    : '⚠️ Di Luar Radius',
                                style: TextStyle(
                                  color: loc.isInsideRadius
                                      ? AppTheme.successGreen
                                      : AppTheme.errorRed,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Buttons
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_rounded, size: 20),
                label: Text(_isSaving ? 'Menyimpan...' : 'Simpan Absensi'),
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
              child: OutlinedButton.icon(
                onPressed: _isSaving ? null : () => Navigator.pop(context),
                icon: const Icon(Icons.camera_alt_rounded, size: 18),
                label: const Text('Ulangi Foto'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(100),
                ),
              ),
              Text(
                value,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
