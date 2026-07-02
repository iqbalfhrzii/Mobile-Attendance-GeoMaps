import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/shift_provider.dart';
import '../widgets/gradient_button.dart';

/// Attendance check-in / check-out page with live clock.
class AttendancePage extends ConsumerStatefulWidget {
  const AttendancePage({super.key});

  @override
  ConsumerState<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends ConsumerState<AttendancePage> {
  late Timer _clockTimer;
  DateTime _now = DateTime.now();

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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final todayAsync = ref.watch(todayAttendanceProvider);
    final shiftAsync = ref.watch(defaultShiftProvider);
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

            // ── Shift Info ───────────────────────────────────────────
            shiftAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (shift) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.work_outline_rounded,
                          color: theme.colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${shift.name} — ${shift.displayTime}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Action ───────────────────────────────────────────────
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
                        onPressed: () {
                          ref
                              .read(todayAttendanceProvider.notifier)
                              .checkIn();
                        },
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
                        onPressed: () {
                          ref
                              .read(todayAttendanceProvider.notifier)
                              .checkOut(attendance.id);
                        },
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
