import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/enums.dart';
import '../../core/theme.dart';
import '../../models/attendance_model.dart';
import '../../models/shift_model.dart';
import '../../models/user_model.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/shift_provider.dart';
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
  ShiftModel? _selectedShift;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final attendancesAsync = ref.watch(allAttendancesProvider);
    final employeesAsync = ref.watch(employeesProvider);
    final shiftsAsync = ref.watch(allShiftsProvider);

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
          if (_selectedShift != null) {
            filtered = filtered
                .where((a) => a.shiftId == _selectedShift!.id)
                .toList();
          }

          if (filtered.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tidak ada data untuk diexport')),
            );
            return;
          }

          try {
            await ExportService.exportAttendancesToExcel(filtered, allEmployees);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('File Excel berhasil disimpan.'),
                  backgroundColor: AppTheme.successGreen,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
              );
            }
          }
        },
        icon: const Icon(Icons.file_download_outlined),
        label: const Text('Export Excel'),
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
          // Shift Filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(5),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule_rounded, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: shiftsAsync.when(
                    data: (shifts) => DropdownButtonHideUnderline(
                      child: DropdownButton<ShiftModel?>(
                        isExpanded: true,
                        value: _selectedShift,
                        hint: const Text('Semua Shift'),
                        items: [
                          const DropdownMenuItem<ShiftModel?>(
                            value: null,
                            child: Text('Semua Shift'),
                          ),
                          ...shifts.map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(
                                  s.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )),
                        ],
                        onChanged: (v) => setState(() => _selectedShift = v),
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
                if (_selectedShift != null) {
                  filtered = filtered
                      .where((a) => a.shiftId == _selectedShift!.id)
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
                                      Wrap(
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          const Icon(Icons.schedule_rounded, size: 14, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(att.shiftName,
                                              style: const TextStyle(fontWeight: FontWeight.w500, color: AppTheme.primaryBlue)),
                                          const SizedBox(width: 8),
                                          Text('•  $dateStr',
                                              style: theme.textTheme.bodySmall),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          Text('Masuk: ${att.checkInTime != null ? timeFormat.format(att.checkInTime!) : '-'}', style: theme.textTheme.bodySmall),
                                          const SizedBox(width: 8),
                                          Text('•  Pulang: ${att.checkOutTime != null ? timeFormat.format(att.checkOutTime!) : '-'}', style: theme.textTheme.bodySmall),
                                        ],
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
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Detail Absensi',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Pegawai Info
                  _buildSectionTitle(theme, 'Informasi Karyawan', Icons.person_outline_rounded),
                  const SizedBox(height: 12),
                  _detailRow('Nama', att.employeeName),
                  _detailRow('Tanggal', dateFormat.format(att.date)),
                  const SizedBox(height: 16),
                  
                  // Kehadiran
                  _buildSectionTitle(theme, 'Data Kehadiran', Icons.access_time_rounded),
                  const SizedBox(height: 12),
                  _detailRow('Status', att.attendanceStatus.label),
                  const SizedBox(height: 8),
                  
                  // Waktu Masuk & Foto
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withAlpha(100),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _detailRow('Jam Masuk',
                            att.checkInTime != null ? timeFormat.format(att.checkInTime!) : '-'),
                        if (att.checkInPhotoPath != null) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _showPhotoDialog(context, 'Foto Masuk', att.checkInPhotoPath!),
                              icon: const Icon(Icons.image_outlined, size: 18),
                              label: const Text('Lihat Foto Masuk'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Waktu Pulang & Foto
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withAlpha(100),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _detailRow('Jam Pulang',
                            att.checkOutTime != null ? timeFormat.format(att.checkOutTime!) : '-'),
                        if (att.checkOutPhotoPath != null) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _showPhotoDialog(context, 'Foto Pulang', att.checkOutPhotoPath!),
                              icon: const Icon(Icons.image_outlined, size: 18),
                              label: const Text('Lihat Foto Pulang'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _detailRow('Durasi Kerja', att.workDurationFormatted),
                  const SizedBox(height: 16),
                  
                  // Lokasi
                  _buildSectionTitle(theme, 'Lokasi GPS', Icons.location_on_outlined),
                  const SizedBox(height: 12),
                  _detailRow('Status Lokasi', att.locationStatus.label),
                  if (att.distanceFromOffice != null)
                    _detailRow('Jarak', '${att.distanceFromOffice!.toStringAsFixed(0)} meter dari kantor'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
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
                fontSize: 14,
              ),
            ),
          ),
          const Text(': ', style: TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
                fadeInDuration: const Duration(milliseconds: 300),
                placeholder: (context, url) => const Padding(
                  padding: EdgeInsets.all(64.0),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Memuat foto...', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => const Padding(
                  padding: EdgeInsets.all(48.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.broken_image_rounded, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Gagal memuat foto', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

