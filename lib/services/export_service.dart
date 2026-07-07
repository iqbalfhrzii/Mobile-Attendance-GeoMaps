import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:file_saver/file_saver.dart';
import 'package:share_plus/share_plus.dart';

import '../models/attendance_model.dart';
import '../models/user_model.dart';
import '../core/enums.dart';

class ExportService {
  static Future<void> exportAttendancesToExcel(
    List<AttendanceModel> attendances,
    List<UserModel> employees,
  ) async {
    try {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Laporan Absensi'];
      excel.setDefaultSheet('Laporan Absensi');

      // Headers
      sheetObject.appendRow([
        TextCellValue('Tanggal'),
        TextCellValue('Nama Karyawan'),
        TextCellValue('Shift'),
        TextCellValue('Status Kehadiran'),
        TextCellValue('Status Lokasi'),
        TextCellValue('Jam Masuk'),
        TextCellValue('Jam Pulang'),
        TextCellValue('Durasi (Jam)'),
        TextCellValue('Jarak dari Kantor (meter)'),
        TextCellValue('Latitude'),
        TextCellValue('Longitude'),
      ]);

      final dateFormat = DateFormat('dd-MM-yyyy', 'id_ID');
      final timeFormat = DateFormat('HH:mm');

      // Populate data
      for (var att in attendances) {
        final employee = employees.firstWhere(
          (e) => e.id == att.userId,
          orElse: () => UserModel(
            id: att.userId,
            employeeCode: '',
            fullName: att.employeeName.isNotEmpty ? att.employeeName : 'Unknown User',
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
          durasi = (diff.inMinutes / 60.0).toStringAsFixed(2);
        }

        sheetObject.appendRow([
          TextCellValue(dateFormat.format(att.date)),
          TextCellValue(employee.fullName),
          TextCellValue(att.shiftName ?? '-'),
          TextCellValue(att.attendanceStatus.label),
          TextCellValue(att.locationStatus.label),
          TextCellValue(jamMasuk),
          TextCellValue(jamPulang),
          TextCellValue(durasi),
          TextCellValue(att.distanceFromOffice != null ? att.distanceFromOffice!.toStringAsFixed(2) : '-'),
          TextCellValue(att.latitude != null ? att.latitude.toString() : '-'),
          TextCellValue(att.longitude != null ? att.longitude.toString() : '-'),
        ]);
      }

      // Save the file using file_saver
      final fileBytes = excel.save();
      if (fileBytes != null) {
        final now = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        final fileName = 'Laporan_Absensi_$now';
        
        await FileSaver.instance.saveAs(
          name: fileName,
          bytes: Uint8List.fromList(fileBytes),
          ext: 'xlsx',
          mimeType: MimeType.microsoftExcel,
        );

        // Success - completes normally
      } else {
        throw Exception('Gagal men-generate file Excel.');
      }
    } catch (e) {
      throw Exception('Gagal export Excel: $e');
    }
  }
}
