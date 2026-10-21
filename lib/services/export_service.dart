import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:file_saver/file_saver.dart';
import 'package:share_plus/share_plus.dart';

import '../models/attendance_model.dart';
import '../models/user_model.dart';
import '../core/enums.dart';
import '../core/wita_time.dart';

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
            createdAt: WitaTime.now(),
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
        final now = DateFormat('yyyyMMdd_HHmmss').format(WitaTime.now());
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

  static Future<void> exportRecapToExcel(
    List<UserModel> employees,
    List<AttendanceModel> attendances,
    int month,
    int year,
  ) async {
    try {
      var excel = Excel.createExcel();
      
      String defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
      bool defaultSheetUsed = false;

      final monthData = attendances
          .where((a) => a.date.month == month && a.date.year == year)
          .toList();

      final now = WitaTime.now();
      int totalDaysInMonth;
      if (year == now.year && month == now.month) {
        totalDaysInMonth = now.day;
      } else {
        totalDaysInMonth = DateTime(year, month + 1, 0).day;
      }

      final timeFormat = DateFormat('HH:mm');

      for (var user in employees) {
        if (user.role == UserRole.admin) continue;

        String sheetName = user.fullName.replaceAll(RegExp(r'[\\/?*\[\]]'), ' ');
        if (sheetName.length > 31) sheetName = sheetName.substring(0, 31);
        
        Sheet sheetObject;
        if (!defaultSheetUsed) {
          excel.rename(defaultSheet, sheetName);
          sheetObject = excel[sheetName];
          defaultSheetUsed = true;
        } else {
          sheetObject = excel[sheetName];
        }

        // Identitas
        sheetObject.appendRow([TextCellValue('Nama Karyawan'), TextCellValue(user.fullName)]);
        sheetObject.appendRow([TextCellValue('Kode Karyawan'), TextCellValue(user.employeeCode)]);
        sheetObject.appendRow([TextCellValue('Role'), TextCellValue(user.role.label)]);
        sheetObject.appendRow([TextCellValue('')]);

        // Header Tabel Harian
        sheetObject.appendRow([
          TextCellValue('Tanggal'),
          TextCellValue('Hari'),
          TextCellValue('Shift'),
          TextCellValue('Jam Masuk'),
          TextCellValue('Jam Pulang'),
          TextCellValue('Status'),
        ]);

        final userAttendances = monthData.where((a) => a.userId == user.id).toList();

        int hadir = 0;
        int terlambat = 0;
        int pulangAwal = 0;
        int libur = 0;
        int alpha = 0;

        List<int> absencePerWeek = List.filled(6, 0);

        for (int day = 1; day <= totalDaysInMonth; day++) {
          final currentDate = DateTime(year, month, day);
          
          final att = userAttendances.where((a) => a.date.day == day).firstOrNull;
          
          // Indeks minggu untuk mendeteksi batas Senin-Minggu.
          int weekIndex = (day - 1 + DateTime(year, month, 1).weekday - 1) ~/ 7;

          String jamMasuk = '-';
          String jamPulang = '-';
          String status = 'Tidak Hadir';
          String shift = '-';

          if (att != null) {
            if (att.hasCheckedIn) hadir++;
            if (att.attendanceStatus == AttendanceStatus.late_) terlambat++;
            if (att.attendanceStatus == AttendanceStatus.earlyLeave) pulangAwal++;
            
            jamMasuk = att.checkInTime != null ? timeFormat.format(att.checkInTime!) : '-';
            jamPulang = att.checkOutTime != null ? timeFormat.format(att.checkOutTime!) : '-';
            status = att.attendanceStatus.label;
            shift = att.shiftName ?? '-';
          } else {
            absencePerWeek[weekIndex]++;
          }

          sheetObject.appendRow([
            TextCellValue(DateFormat('dd-MM-yyyy').format(currentDate)),
            TextCellValue(DateFormat('EEEE', 'id_ID').format(currentDate)),
            TextCellValue(shift),
            TextCellValue(jamMasuk),
            TextCellValue(jamPulang),
            TextCellValue(status),
          ]);
        }
        
        // Kalkulasi libur mingguan (max 1 hari per minggu, sisanya Alpha)
        for (int absenceCount in absencePerWeek) {
           if (absenceCount > 0) {
              libur += 1;
              alpha += (absenceCount - 1);
           }
        }

        sheetObject.appendRow([TextCellValue('')]);
        sheetObject.appendRow([TextCellValue('RINGKASAN BULANAN')]);
        sheetObject.appendRow([TextCellValue('Total Hadir'), IntCellValue(hadir)]);
        sheetObject.appendRow([TextCellValue('Terlambat'), IntCellValue(terlambat)]);
        sheetObject.appendRow([TextCellValue('Pulang Awal'), IntCellValue(pulangAwal)]);
        sheetObject.appendRow([TextCellValue('Total Libur (Max 1 / Minggu)'), IntCellValue(libur)]);
        sheetObject.appendRow([TextCellValue('Total Alpha (Tanpa Keterangan)'), IntCellValue(alpha)]);
      }

      final fileBytes = excel.save();
      if (fileBytes != null) {
        final fileName =
            'Rekap_Karyawan_${year}_${month.toString().padLeft(2, '0')}';

        await FileSaver.instance.saveAs(
          name: fileName,
          bytes: Uint8List.fromList(fileBytes),
          ext: 'xlsx',
          mimeType: MimeType.microsoftExcel,
        );
      } else {
        throw Exception('Gagal men-generate file Excel.');
      }
    } catch (e) {
      throw Exception('Gagal export Excel: $e');
    }
  }
}
