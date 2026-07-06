import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/theme.dart';
import '../models/shift_model.dart';
import '../providers/auth_provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/office_location_provider.dart';
import '../providers/shift_provider.dart';
import '../services/location_service.dart';
import '../widgets/gradient_button.dart';
import 'attendance/location_confirm_page.dart';

/// Attendance check-in / check-out page with live clock.
///
/// When user taps Check In / Check Out:
/// 1. GPS permission + location fetch
/// 2. Distance calculation from office
/// 3. Navigate to LocationConfirmPage → CameraPage → PreviewPage → save
class AttendancePage extends ConsumerStatefulWidget {
  const AttendancePage({super.key});

  @override
  ConsumerState<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends ConsumerState<AttendancePage> {
  late Timer _clockTimer;
  DateTime _now = DateTime.now();
  bool _isLoadingLocation = false;
  ShiftModel? _selectedShift;

  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  /// Start the attendance flow: GPS → location confirm → camera → preview.
  Future<void> _startAttendanceFlow({
    required bool isCheckIn,
    String? attendanceId,
    String? shiftId,
    String? shiftName,
  }) async {
    if (_isLoadingLocation) return;
    
    if (isCheckIn && (shiftId == null || shiftName == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Silakan pilih jadwal shift terlebih dahulu.'),
          backgroundColor: AppTheme.warningOrange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isLoadingLocation = true);

    try {
      // Get office location
      final office = await ref.read(primaryOfficeProvider.future);

      // Check permission + get GPS + calculate distance
      final locationResult = await _locationService.getLocationAndDistance(
        officeLat: office.latitude,
        officeLng: office.longitude,
        radiusMeter: office.radiusMeter,
      );

      if (!mounted) return;

      // Navigate to location confirmation page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LocationConfirmPage(
            locationResult: locationResult,
            isCheckIn: isCheckIn,
            attendanceId: attendanceId,
            shiftId: shiftId,
            shiftName: shiftName,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      final errorMsg = e.toString().replaceAll('Exception: ', '');

      // Show permission dialog for denied/disabled
      if (errorMsg.contains('ditolak permanen') ||
          errorMsg.contains('pengaturan')) {
        _showPermissionDialog(errorMsg);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  void _showPermissionDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.warningOrange),
            SizedBox(width: 8),
            Text('Izin Diperlukan'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final todayAsync = ref.watch(todayAttendanceProvider);
    final allShiftsAsync = ref.watch(allShiftsProvider);
    final theme = Theme.of(context);

    if (user == null) return const SizedBox.shrink();

    final timeStr = DateFormat('HH:mm:ss').format(_now);
    final dateStr = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_now);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────
            Text(
              'Absensi',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dateStr,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(140),
              ),
            ),
            const SizedBox(height: 32),

            // ── Live Clock ───────────────────────────────────────────
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1A56DB).withAlpha(50),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timeStr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'WIB',
                      style: TextStyle(
                        color: Colors.white.withAlpha(160),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── Shift Selection ───────────────────────────────────────
            todayAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (attendance) {
                // If user has not checked in, show shift selector
                if (attendance == null) {
                  return allShiftsAsync.when(
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => const Text('Gagal memuat jadwal'),
                    data: (shifts) {
                      if (_selectedShift == null && shifts.isNotEmpty) {
                        // Automatically select the first shift as default
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) setState(() => _selectedShift = shifts.first);
                        });
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.colorScheme.outline.withAlpha(50)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(5),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<ShiftModel>(
                            value: _selectedShift,
                            isExpanded: true,
                            icon: const Icon(Icons.expand_more_rounded),
                            hint: const Text('Pilih Jadwal Shift'),
                            items: shifts.map((shift) {
                              return DropdownMenuItem<ShiftModel>(
                                value: shift,
                                child: Row(
                                  children: [
                                    Icon(Icons.schedule_rounded, size: 18, color: theme.colorScheme.primary),
                                    const SizedBox(width: 10),
                                    Text(
                                      '${shift.name} (${shift.displayTime})',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedShift = val);
                            },
                          ),
                        ),
                      );
                    },
                  );
                }
                
                // If user has already checked in, show the shift they selected
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.work_outline_rounded,
                            color: theme.colorScheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          attendance.shiftName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // ── Loading overlay for GPS ──────────────────────────────
            if (_isLoadingLocation)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Mengambil lokasi GPS...',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha(140),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pastikan GPS aktif',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha(100),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Action ───────────────────────────────────────────────
            if (!_isLoadingLocation)
              todayAsync.when(
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('Error: $e'),
                data: (attendance) {
                  if (attendance == null) {
                    return Column(
                      children: [
                        Icon(
                          Icons.login_rounded,
                          size: 48,
                          color: theme.colorScheme.onSurface.withAlpha(60),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Anda belum absen masuk hari ini',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color:
                                theme.colorScheme.onSurface.withAlpha(120),
                          ),
                        ),
                        const SizedBox(height: 24),
                        GradientButton(
                          label: 'Check In',
                          icon: Icons.login_rounded,
                          onPressed: () => _startAttendanceFlow(
                            isCheckIn: true,
                          ),
                        ),
                      ],
                    );
                  }

                  if (!attendance.hasCheckedOut) {
                    final checkInTimeStr =
                        DateFormat('HH:mm').format(attendance.checkInTime!);
                    return Column(
                      children: [
                        _infoTile(
                          context,
                          'Check In',
                          checkInTimeStr,
                          Icons.login_rounded,
                          AppTheme.successGreen,
                        ),
                        const SizedBox(height: 20),
                        GradientButton(
                          label: 'Check Out',
                          icon: Icons.logout_rounded,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF97316), Color(0xFFEF4444)],
                          ),
                          onPressed: () => _startAttendanceFlow(
                            isCheckIn: false,
                            attendanceId: attendance.id,
                          ),
                        ),
                      ],
                    );
                  }

                  // Complete
                  final checkInTimeStr =
                      DateFormat('HH:mm').format(attendance.checkInTime!);
                  final checkOutTimeStr =
                      DateFormat('HH:mm').format(attendance.checkOutTime!);
                  return Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppTheme.successGreen.withAlpha(20),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          color: AppTheme.successGreen,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Absensi Selesai',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.successGreen,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _infoTile(
                              context,
                              'Masuk',
                              checkInTimeStr,
                              Icons.login_rounded,
                              AppTheme.successGreen,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _infoTile(
                              context,
                              'Pulang',
                              checkOutTimeStr,
                              Icons.logout_rounded,
                              AppTheme.warningOrange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _infoTile(
                        context,
                        'Durasi Kerja',
                        attendance.workDurationFormatted,
                        Icons.timer_outlined,
                        AppTheme.accentTeal,
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(30)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(120),
                ),
              ),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
