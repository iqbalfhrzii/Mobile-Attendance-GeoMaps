import 'package:flutter/material.dart';

import '../core/enums.dart';
import '../core/theme.dart';

/// A small colored badge showing attendance status.
class StatusBadge extends StatelessWidget {
  final AttendanceStatus status;
  final LocationStatus? locationStatus;
  final bool showIcon;

  const StatusBadge({
    super.key,
    required this.status,
    this.locationStatus,
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
      case AttendanceStatus.earlyLeave:
        return AppTheme.warningOrange.withAlpha(30);
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
      case AttendanceStatus.earlyLeave:
        return AppTheme.warningOrange;
    }
  }

  String get _displayLabel {
    String base = status.label;
    if (locationStatus != null && 
        (status == AttendanceStatus.present || status == AttendanceStatus.late_)) {
      if (locationStatus == LocationStatus.inside) {
        base += ' (Di Lokasi)';
      } else if (locationStatus == LocationStatus.outside) {
        base += ' (Luar Lokasi)';
      }
    }
    return base;
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
            _displayLabel,
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
