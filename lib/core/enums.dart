/// User role in the application.
enum UserRole {
  admin('Admin'),
  employee('Karyawan');

  final String label;
  const UserRole(this.label);
}

/// Attendance status.
enum AttendanceStatus {
  present('Hadir', '✅'),
  late_('Terlambat', '⏰'),
  absent('Tidak Hadir', '❌'),
  permission('Izin', '📋'),
  sick('Sakit', '🤒');

  final String label;
  final String icon;
  const AttendanceStatus(this.label, this.icon);
}

/// Location status relative to office radius.
enum LocationStatus {
  inside('Di Dalam Area'),
  outside('Di Luar Area'),
  unknown('Tidak Diketahui');

  final String label;
  const LocationStatus(this.label);
}
