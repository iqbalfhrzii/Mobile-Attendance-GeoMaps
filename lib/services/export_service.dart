import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart' as syspaths;
import 'package:share_plus/share_plus.dart';

import '../models/attendance_model.dart';
import '../models/user_model.dart';
import '../core/enums.dart';

class ExportService {
  static Future<void> exportAttendancesToCSV(
    List<AttendanceModel> attendances,
    List<UserModel> employees,
  ) async {
    try {
      // 1. Prepare data rows
      List<List<dynamic>> rows = [];
      
      // Headers
      rows.add([
        'Tanggal',
        'Nama Karyawan',
        'Status',
        'Jam Masuk',
        'Jam Pulang',
        'Lokasi Masuk',
        'Lokasi Pulang',
        'Durasi (Jam)',
      ]);

      final dateFormat = DateFormat('dd-MM-yyyy', 'id_ID');
      final timeFormat = DateFormat('HH:mm');

      // Populate data
      for (var att in attendances) {
        // Find employee name
        final employee = employees.firstWhere(
          (e) => e.id == att.userId,
          orElse: () => UserModel(
            id: att.userId,
            employeeCode: '',
            fullName: 'Unknown User (${att.userId})',
            email: '',
            role: UserRole.employee,
            createdAt: DateTime.now(),
          ),
        );

        String jamMasuk = att.checkInTime != null ? timeFormat.format(att.checkInTime!) : '-';
        String jamPulang = att.checkOutTime != null ? timeFormat.format(att.checkOutTime!) : '-';
        
        String durasi = '-';
        if (att.checkInTime != null && att.checkOutTime != null) {
          final diff = att.checkOutTime!.difference(att.checkInTime!);
          durasi = (diff.inMinutes / 60.0).toStringAsFixed(2); // e.g. 8.50
        }

        rows.add([
          dateFormat.format(att.date),
          employee.fullName,
          att.attendanceStatus.name,
          jamMasuk,
          jamPulang,
          att.latitude != null && att.longitude != null ? '${att.latitude}, ${att.longitude}' : '-',
          '-',
          durasi,
        ]);
      }

      // 2. Convert to CSV string
      String csv = const ListToCsvConverter().convert(rows);

      // 3. Save to temporary directory
      final dir = await syspaths.getTemporaryDirectory();
      final now = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final path = '${dir.path}/Laporan_Absensi_$now.csv';
      
      final file = File(path);
      await file.writeAsString(csv);

      // 4. Share file
      await Share.shareXFiles(
        [XFile(path)],
        text: 'Laporan Absensi Karyawan',
      );
    } catch (e) {
      throw Exception('Gagal export CSV: $e');
    }
  }
}
