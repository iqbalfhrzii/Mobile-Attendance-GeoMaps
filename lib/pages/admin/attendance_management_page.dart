import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/enums.dart';
import '../../core/theme.dart';
import '../../models/attendance_model.dart';
import '../../models/user_model.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/export_service.dart';
import '../../widgets/status_badge.dart';

class AttendanceManagementPage extends ConsumerStatefulWidget {
  const AttendanceManagementPage({super.key});

  @override
  ConsumerState<AttendanceManagementPage> createState() =>
      _AttendanceManagementPageState();
}

class _AttendanceManagementPageState
    extends ConsumerState<AttendanceManagementPage> {
  DateTime? _selectedDate;
  UserModel? _selectedEmployee;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final attendancesAsync = ref.watch(allAttendancesProvider);
    final employeesAsync = ref.watch(employeesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Absensi'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final allData = ref.read(allAttendancesProvider).value;
          final allEmployees = ref.read(employeesProvider).value;
          if (allData == null || allEmployees == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Data belum siap diexport')),
            );
            return;
          }

          var filtered = allData;
          if (_selectedDate != null) {
            filtered = filtered.where((a) {
              return a.date.year == _selectedDate!.year &&
                  a.date.month == _selectedDate!.month &&
                  a.date.day == _selectedDate!.day;
            }).toList();
          }
          if (_selectedEmployee != null) {
            filtered = filtered
                .where((a) => a.userId == _selectedEmployee!.id)
                .toList();
          }

          if (filtered.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tidak ada data untuk diexport')),
            );
            return;
          }

          try {
            await ExportService.exportAttendancesToCSV(filtered, allEmployees);
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(e.toString())),
              );
            }
          }
        },
        icon: const Icon(Icons.file_download_outlined),
        label: const Text('Export CSV'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Date filter
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _selectedDate = date);
                      }
                    },
                    icon: const Icon(Icons.calendar_today_rounded, size: 18),
                    label: Text(
                      _selectedDate == null
                          ? 'Semua Tanggal'
                          : DateFormat('dd MMM yyyy', 'id_ID')
                              .format(_selectedDate!),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (_selectedDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _selectedDate = null),
                  ),
                const SizedBox(width: 8),

                // Employee filter
                Expanded(
                  child: employeesAsync.when(
                    data: (employees) => DropdownButtonHideUnderline(
                      child: DropdownButton<UserModel?>(
                        isExpanded: true,
                        value: _selectedEmployee,
                        hint: const Text('Semua Karyawan'),
                        items: [
                          const DropdownMenuItem<UserModel?>(
                            value: null,
                            child: Text('Semua Karyawan'),
                          ),
                          ...employees.map((e) => DropdownMenuItem(
                                value: e,
                                child: Text(
                                  e.fullName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )),
                        ],
                        onChanged: (v) => setState(() => _selectedEmployee = v),
                      ),
                    ),
                    loading: () => const Center(
                        child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))),
                    error: (_, __) => const Text('Error'),
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: attendancesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (allData) {
                // Apply filters
                var filtered = allData;
                if (_selectedDate != null) {
                  filtered = filtered.where((a) {
                    return a.date.year == _selectedDate!.year &&
                        a.date.month == _selectedDate!.month &&
                        a.date.day == _selectedDate!.day;
                  }).toList();
                }
                if (_selectedEmployee != null) {
                  filtered = filtered
                      .where((a) => a.userId == _selectedEmployee!.id)
                      .toList();
                }

                if (filtered.isEmpty) {
                  return const Center(child: Text('Tidak ada data absensi.'));
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(allAttendancesProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final att = filtered[index];
                      final timeFormat = DateFormat('HH:mm');
                      final dateStr =
                          DateFormat('dd MMM yyyy', 'id_ID').format(att.date);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => _showDetailDialog(context, att),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        att.employeeName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(dateStr,
                                          style: theme.textTheme.bodySmall),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Masuk: ${att.checkInTime != null ? timeFormat.format(att.checkInTime!) : '-'} • Pulang: ${att.checkOutTime != null ? timeFormat.format(att.checkOutTime!) : '-'}',
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                StatusBadge(
                                  status: att.attendanceStatus,
                                  locationStatus: att.locationStatus,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailDialog(BuildContext context, AttendanceModel att) {
    final timeFormat = DateFormat('HH:mm');
    final dateFormat = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Detail Absensi'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow('Nama', att.employeeName),
                _detailRow('Tanggal', dateFormat.format(att.date)),
                _detailRow('Status', att.attendanceStatus.label),
                const Divider(),
                _detailRow(
                    'Jam Masuk',
                    att.checkInTime != null
                        ? timeFormat.format(att.checkInTime!)
                        : '-'),
                if (att.checkInPhotoPath != null) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _showPhotoDialog(context, 'Foto Masuk', att.checkInPhotoPath!),
                    icon: const Icon(Icons.image_outlined, size: 18),
                    label: const Text('Lihat Foto Masuk'),
                  ),
                  const SizedBox(height: 8),
                ],
                _detailRow(
                    'Jam Pulang',
                    att.checkOutTime != null
                        ? timeFormat.format(att.checkOutTime!)
                        : '-'),
                if (att.checkOutPhotoPath != null) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _showPhotoDialog(context, 'Foto Pulang', att.checkOutPhotoPath!),
                    icon: const Icon(Icons.image_outlined, size: 18),
                    label: const Text('Lihat Foto Pulang'),
                  ),
                  const SizedBox(height: 8),
                ],
                _detailRow('Durasi', att.workDurationFormatted),
                const Divider(),
                _detailRow('Status Lokasi', att.locationStatus.label),
                if (att.distanceFromOffice != null)
                  _detailRow('Jarak dari Kantor',
                      '${att.distanceFromOffice!.toStringAsFixed(0)} meter'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showPhotoDialog(BuildContext context, String title, String url) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

