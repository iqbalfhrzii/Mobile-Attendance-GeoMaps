import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/shift_provider.dart';
import '../widgets/status_badge.dart';

/// Home / dashboard page.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final todayAsync = ref.watch(todayAttendanceProvider);
    final shiftAsync = ref.watch(defaultShiftProvider);
    final theme = Theme.of(context);
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now);

    if (user == null) return const SizedBox.shrink();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Greeting Header ──────────────────────────────────────
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
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
            const SizedBox(height: 24),

            // ── Shift Info ───────────────────────────────────────────
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
                              'Jam Kerja Hari Ini',
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.accentTeal.withAlpha(20),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          shift.name,
                          style: const TextStyle(
                            color: AppTheme.accentTeal,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Today's Status ───────────────────────────────────────
            Text(
              'Status Hari Ini',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            todayAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Gagal memuat data'),
                ),
              ),
              data: (attendance) {
                if (attendance == null) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(Icons.event_available_outlined,
                              size: 48,
                              color: theme.colorScheme.onSurface
                                  .withAlpha(80)),
                          const SizedBox(height: 12),
                          Text(
                            'Belum absen hari ini',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withAlpha(120),
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () => context.go('/main/attendance'),
                            icon: const Icon(Icons.fingerprint_rounded),
                            label: const Text('Absen Sekarang'),
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
                            Text('Status:', style: theme.textTheme.bodyMedium),
                            const SizedBox(width: 8),
                            StatusBadge(status: attendance.attendanceStatus),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _statusTile(
                              context,
                              'Masuk',
                              attendance.checkInTime != null
                                  ? timeFormat.format(attendance.checkInTime!)
                                  : '-',
                              Icons.login_rounded,
                              AppTheme.successGreen,
                            ),
                            const SizedBox(width: 12),
                            _statusTile(
                              context,
                              'Pulang',
                              attendance.checkOutTime != null
                                  ? timeFormat.format(attendance.checkOutTime!)
                                  : '-',
                              Icons.logout_rounded,
                              AppTheme.warningOrange,
                            ),
                            const SizedBox(width: 12),
                            _statusTile(
                              context,
                              'Durasi',
                              attendance.workDurationFormatted,
                              Icons.timer_outlined,
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

            // ── Quick Actions ────────────────────────────────────────
            Text(
              'Menu Cepat',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _quickAction(
                  context,
                  'Absensi',
                  Icons.fingerprint_rounded,
                  const Color(0xFF1A56DB),
                  () => context.go('/main/attendance'),
                ),
                const SizedBox(width: 12),
                _quickAction(
                  context,
                  'Riwayat',
                  Icons.history_rounded,
                  AppTheme.accentTeal,
                  () => context.go('/main/history'),
                ),
                const SizedBox(width: 12),
                _quickAction(
                  context,
                  'Profil',
                  Icons.person_rounded,
                  AppTheme.accentAmber,
                  () => context.go('/main/profile'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusTile(
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

  Widget _quickAction(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: color.withAlpha(15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withAlpha(30)),
          ),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
