import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/enums.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/shift_provider.dart';
import '../widgets/status_badge.dart';

/// Home page — shows different dashboards based on role.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    if (user.role == UserRole.admin) {
      return const _AdminDashboard();
    }
    return const _EmployeeDashboard();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// EMPLOYEE DASHBOARD
// ═══════════════════════════════════════════════════════════════════════════

class _EmployeeDashboard extends ConsumerWidget {
  const _EmployeeDashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider)!;
    final todayAsync = ref.watch(todayAttendanceProvider);
    final shiftAsync = ref.watch(defaultShiftProvider);
    final historyAsync = ref.watch(attendanceHistoryProvider);
    final theme = Theme.of(context);
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(todayAttendanceProvider);
          ref.invalidate(attendanceHistoryProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Greeting ─────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppTheme.cardGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1A56DB).withAlpha(40),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.white.withAlpha(30),
                          child: Text(
                            user.initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Halo, ${user.fullName.split(' ').first}! 👋',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${user.role.label} • ${user.employeeCode}',
                                style: TextStyle(
                                  color: Colors.white.withAlpha(180),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Image.asset(
                          'assets/img/logoMahligai.png',
                          width: 48,
                          height: 48,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              color: Colors.white70, size: 14),
                          const SizedBox(width: 8),
                          Text(
                            dateStr,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Shift Info ──────────────────────────────────────
              shiftAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (shift) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.schedule_rounded,
                              color: theme.colorScheme.primary, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Shift Hari Ini',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withAlpha(140),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${shift.name} — ${shift.displayTime}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Status Absensi Hari Ini ─────────────────────────
              Text(
                'Status Absensi Hari Ini',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              todayAsync.when(
                loading: () =>
                    const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
                error: (_, __) => const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Gagal memuat data'),
                  ),
                ),
                data: (attendance) {
                  if (attendance == null) {
                    // Belum absen
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer
                                    .withAlpha(80),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.event_available_outlined,
                                size: 32,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Belum absen hari ini',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Silakan lakukan absen masuk',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withAlpha(100),
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: () =>
                                    context.go('/main/attendance'),
                                icon:
                                    const Icon(Icons.login_rounded, size: 20),
                                label: const Text('Absen Masuk'),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
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

                  final timeFormat = DateFormat('HH:mm');
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Status + location
                          Row(
                            children: [
                              StatusBadge(
                                status: attendance.attendanceStatus,
                                locationStatus: attendance.locationStatus,
                              ),
                              const SizedBox(width: 8),
                              if (attendance.locationStatus !=
                                  LocationStatus.unknown)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: attendance.locationStatus ==
                                            LocationStatus.inside
                                        ? AppTheme.successGreen.withAlpha(20)
                                        : AppTheme.errorRed.withAlpha(20),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.location_on_rounded,
                                        size: 12,
                                        color: attendance.locationStatus ==
                                                LocationStatus.inside
                                            ? AppTheme.successGreen
                                            : AppTheme.errorRed,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        attendance.locationStatus.label,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: attendance.locationStatus ==
                                                  LocationStatus.inside
                                              ? AppTheme.successGreen
                                              : AppTheme.errorRed,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Time tiles
                          Row(
                            children: [
                              _timeTile(
                                context,
                                'Jam Masuk',
                                attendance.checkInTime != null
                                    ? timeFormat
                                        .format(attendance.checkInTime!)
                                    : '-',
                                Icons.login_rounded,
                                AppTheme.successGreen,
                              ),
                              const SizedBox(width: 12),
                              _timeTile(
                                context,
                                'Jam Pulang',
                                attendance.checkOutTime != null
                                    ? timeFormat
                                        .format(attendance.checkOutTime!)
                                    : '-',
                                Icons.logout_rounded,
                                AppTheme.warningOrange,
                              ),
                              const SizedBox(width: 12),
                              _timeTile(
                                context,
                                'Durasi',
                                attendance.workDurationFormatted,
                                Icons.timer_outlined,
                                AppTheme.accentTeal,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Action button
                          if (!attendance.isComplete)
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: () =>
                                    context.go('/main/attendance'),
                                icon: Icon(
                                  attendance.hasCheckedIn
                                      ? Icons.logout_rounded
                                      : Icons.login_rounded,
                                  size: 20,
                                ),
                                label: Text(
                                  attendance.hasCheckedIn
                                      ? 'Absen Pulang'
                                      : 'Absen Masuk',
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: attendance.hasCheckedIn
                                      ? AppTheme.warningOrange
                                      : null,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
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
                },
              ),
              const SizedBox(height: 24),

              // ── Riwayat Terbaru ─────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Riwayat Terbaru',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/main/history'),
                    child: const Text('Lihat Semua'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              historyAsync.when(
                loading: () =>
                    const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
                error: (_, __) =>
                    const Text('Gagal memuat riwayat'),
                data: (records) {
                  if (records.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'Belum ada riwayat',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withAlpha(100),
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  // Show latest 3
                  final latest = records.take(3).toList();
                  return Column(
                    children: latest.map((r) {
                      final dateStr =
                          DateFormat('dd MMM', 'id_ID').format(r.date);
                      final timeStr = r.checkInTime != null
                          ? DateFormat('HH:mm').format(r.checkInTime!)
                          : '-';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: _statusColor(r.attendanceStatus)
                                  .withAlpha(20),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                r.attendanceStatus.icon,
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                          ),
                          title: Text(
                            dateStr,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            'Masuk: $timeStr • ${r.workDurationFormatted}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withAlpha(120),
                            ),
                          ),
                          trailing: StatusBadge(
                            status: r.attendanceStatus,
                            locationStatus: r.locationStatus,
                            showIcon: false,
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return AppTheme.successGreen;
      case AttendanceStatus.late_:
        return AppTheme.warningOrange;
      case AttendanceStatus.absent:
        return AppTheme.errorRed;
      case AttendanceStatus.permission:
        return AppTheme.accentTeal;
      case AttendanceStatus.sick:
        return AppTheme.accentAmber;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ADMIN DASHBOARD
// ═══════════════════════════════════════════════════════════════════════════

class _AdminDashboard extends ConsumerWidget {
  const _AdminDashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider)!;
    final todayAsync = ref.watch(todayAttendanceProvider);
    final statsAsync = ref.watch(todayStatsProvider);
    final shiftAsync = ref.watch(defaultShiftProvider);
    final theme = Theme.of(context);
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(todayAttendanceProvider);
          ref.invalidate(todayStatsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Greeting Header ────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withAlpha(50),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Halo, ${user.fullName.split(' ').first}! 🛡️',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444)
                                      .withAlpha(30),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'ADMIN',
                                  style: TextStyle(
                                    color: Color(0xFFEF4444),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Image.asset(
                          'assets/img/logoMahligai.png',
                          width: 48,
                          height: 48,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      dateStr,
                      style: TextStyle(
                        color: Colors.white.withAlpha(140),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Admin's Own Attendance ──────────────────────────
              Text(
                'Absensi Anda',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              todayAsync.when(
                loading: () =>
                    const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
                error: (_, __) => const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Gagal memuat data'),
                  ),
                ),
                data: (attendance) {
                  if (attendance == null) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.schedule_rounded,
                                  color: theme.colorScheme.primary),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Belum absen hari ini',
                                    style: theme.textTheme.titleSmall
                                        ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  shiftAsync.when(
                                    loading: () => const SizedBox.shrink(),
                                    error: (_, __) =>
                                        const SizedBox.shrink(),
                                    data: (shift) => Text(
                                      '${shift.name} (${shift.displayTime})',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        color: theme
                                            .colorScheme.onSurface
                                            .withAlpha(120),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            FilledButton.tonal(
                              onPressed: () =>
                                  context.go('/main/attendance'),
                              child: const Text('Absen'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final timeFormat = DateFormat('HH:mm');
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              StatusBadge(
                                status: attendance.attendanceStatus,
                                locationStatus: attendance.locationStatus,
                              ),
                              const Spacer(),
                              if (!attendance.isComplete)
                                FilledButton.tonal(
                                  onPressed: () =>
                                      context.go('/main/attendance'),
                                  child: Text(
                                    attendance.hasCheckedIn
                                        ? 'Absen Pulang'
                                        : 'Absen Masuk',
                                  ),
                                ),
                              if (attendance.isComplete)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppTheme.successGreen
                                        .withAlpha(20),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    '✅ Selesai',
                                    style: TextStyle(
                                      color: AppTheme.successGreen,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _miniTimeTile(
                                context,
                                'Masuk',
                                attendance.checkInTime != null
                                    ? timeFormat
                                        .format(attendance.checkInTime!)
                                    : '-',
                                AppTheme.successGreen,
                              ),
                              const SizedBox(width: 10),
                              _miniTimeTile(
                                context,
                                'Pulang',
                                attendance.checkOutTime != null
                                    ? timeFormat
                                        .format(attendance.checkOutTime!)
                                    : '-',
                                AppTheme.warningOrange,
                              ),
                              const SizedBox(width: 10),
                              _miniTimeTile(
                                context,
                                'Durasi',
                                attendance.workDurationFormatted,
                                AppTheme.accentTeal,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // ── Overview Stats ──────────────────────────────────
              Text(
                'Overview Hari Ini',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              statsAsync.when(
                loading: () =>
                    const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
                error: (_, __) =>
                    const Text('Gagal memuat statistik'),
                data: (stats) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          _statCard(
                            context,
                            'Total Karyawan',
                            '${stats['totalKaryawan']}',
                            Icons.groups_rounded,
                            const Color(0xFF1A56DB),
                          ),
                          const SizedBox(width: 12),
                          _statCard(
                            context,
                            'Hadir',
                            '${stats['hadir']}',
                            Icons.check_circle_rounded,
                            AppTheme.successGreen,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _statCard(
                            context,
                            'Belum Hadir',
                            '${stats['belumHadir']}',
                            Icons.person_off_rounded,
                            AppTheme.warningOrange,
                          ),
                          const SizedBox(width: 12),
                          _statCard(
                            context,
                            'Terlambat',
                            '${stats['terlambat']}',
                            Icons.schedule_rounded,
                            AppTheme.errorRed,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _statCard(
                            context,
                            'Di Luar Radius',
                            '${stats['diLuarRadius']}',
                            Icons.location_off_rounded,
                            const Color(0xFF8B5CF6),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(child: SizedBox()),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // ── Admin Shortcuts ─────────────────────────────────
              Text(
                'Menu Admin',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.95,
                children: [
                  _shortcut(
                    context,
                    'Kelola\nKaryawan',
                    Icons.people_rounded,
                    const Color(0xFF1A56DB),
                    () => context.go('/main/admin'),
                  ),
                  _shortcut(
                    context,
                    'Data\nAbsensi',
                    Icons.fact_check_rounded,
                    AppTheme.accentTeal,
                    () => context.go('/main/admin'),
                  ),
                  _shortcut(
                    context,
                    'Laporan\nBulanan',
                    Icons.assessment_rounded,
                    AppTheme.successGreen,
                    () => context.go('/main/admin'),
                  ),
                  _shortcut(
                    context,
                    'Lokasi\nKantor',
                    Icons.location_on_rounded,
                    AppTheme.errorRed,
                    () => context.go('/main/admin'),
                  ),
                  _shortcut(
                    context,
                    'Shift',
                    Icons.schedule_rounded,
                    AppTheme.accentAmber,
                    () => context.go('/main/admin'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SHARED HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

Widget _timeTile(
  BuildContext context,
  String label,
  String value,
  IconData icon,
  Color color,
) {
  final theme = Theme.of(context);
  return Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(100),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _miniTimeTile(
  BuildContext context,
  String label,
  String value,
  Color color,
) {
  final theme = Theme.of(context);
  return Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(100),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _statCard(
  BuildContext context,
  String label,
  String value,
  IconData icon,
  Color color,
) {
  final theme = Theme.of(context);
  return Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(60),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(120),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _shortcut(
  BuildContext context,
  String label,
  IconData icon,
  Color color,
  VoidCallback onTap,
) {
  final theme = Theme.of(context);
  return InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withAlpha(12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(25)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
              height: 1.2,
            ),
          ),
        ],
      ),
    ),
  );
}
