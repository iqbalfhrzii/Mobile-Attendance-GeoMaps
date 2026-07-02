import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/enums.dart';
import '../models/attendance_model.dart';
import 'status_badge.dart';

/// A card displaying a single attendance record.
class AttendanceCard extends StatelessWidget {
  final AttendanceModel attendance;

  const AttendanceCard({super.key, required this.attendance});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('EEEE, d MMM yyyy', 'id_ID');
    final timeFormat = DateFormat('HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row — date + status
            Row(
              children: [
                Expanded(
                  child: Text(
                    dateFormat.format(attendance.date),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                StatusBadge(status: attendance.attendanceStatus),
              ],
            ),
            const SizedBox(height: 12),
            // Location status
            if (attendance.locationStatus != LocationStatus.unknown)
              _infoRow(
                context,
                Icons.location_on_outlined,
                '${attendance.locationStatus.label} '
                    '${attendance.distanceFromOffice != null ? '(${attendance.distanceFromOffice!.toStringAsFixed(1)}m)' : ''}',
              ),
            if (attendance.locationStatus != LocationStatus.unknown)
              const SizedBox(height: 8),
            // Check in / out times
            Row(
              children: [
                Expanded(
                  child: _timeBlock(
                    context,
                    'Masuk',
                    attendance.checkInTime != null
                        ? timeFormat.format(attendance.checkInTime!)
                        : '-',
                    Icons.login_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _timeBlock(
                    context,
                    'Pulang',
                    attendance.checkOutTime != null
                        ? timeFormat.format(attendance.checkOutTime!)
                        : '-',
                    Icons.logout_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _timeBlock(
                    context,
                    'Durasi',
                    attendance.workDurationFormatted,
                    Icons.timer_outlined,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _timeBlock(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon,
              size: 18,
              color: theme.colorScheme.onSurface.withAlpha(120)),
          const SizedBox(height: 4),
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
              color: theme.colorScheme.onSurface.withAlpha(120),
            ),
          ),
        ],
      ),
    );
  }
}
