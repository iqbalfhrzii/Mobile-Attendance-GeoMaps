import 'package:flutter/material.dart';

import '../core/enums.dart';
import '../core/theme.dart';

/// A small colored badge showing attendance status.
class StatusBadge extends StatelessWidget {
  final AttendanceStatus status;
  final bool showIcon;

  const StatusBadge({
    super.key,
    required this.status,
    this.showIcon = true,
  });

  Color get _backgroundColor {
    switch (status) {
      case AttendanceStatus.present:
        return AppTheme.successGreen.withAlpha(30);
      case AttendanceStatus.late_:
        return AppTheme.warningOrange.withAlpha(30);
      case AttendanceStatus.absent:
        return AppTheme.errorRed.withAlpha(30);
      case AttendanceStatus.permission:
        return AppTheme.accentTeal.withAlpha(30);
      case AttendanceStatus.sick:
        return AppTheme.accentAmber.withAlpha(30);
    }
  }

  Color get _foregroundColor {
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Text(status.icon, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
          ],
          Text(
            status.label,
            style: TextStyle(
              color: _foregroundColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
