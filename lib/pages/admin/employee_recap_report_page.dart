import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/enums.dart';
import '../../core/theme.dart';
import '../../models/user_model.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/user_provider.dart';

import '../../services/export_service.dart';

class EmployeeRecapReportPage extends ConsumerStatefulWidget {
  const EmployeeRecapReportPage({super.key});

  @override
  ConsumerState<EmployeeRecapReportPage> createState() =>
      _EmployeeRecapReportPageState();
}

class _EmployeeRecapReportPageState
    extends ConsumerState<EmployeeRecapReportPage> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  bool _isExporting = false;

  final List<String> _months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final attendancesAsync = ref.watch(allAttendancesProvider);
    final usersAsync = ref.watch(allUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekap Karyawan'),
        actions: [
          if (_isExporting)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.file_download_outlined),
              tooltip: 'Export ke Excel',
              onPressed: () async {
                final allAtt = attendancesAsync.valueOrNull;
                final allUsers = usersAsync.valueOrNull;
                
                if (allAtt == null || allUsers == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Data belum siap.')),
                  );
                  return;
                }
                
                setState(() => _isExporting = true);
                try {
                  await ExportService.exportRecapToExcel(
                    allUsers,
                    allAtt,
                    _selectedMonth,
                    _selectedYear,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Berhasil export ke Excel!')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal export: $e')),
                    );
                  }
                } finally {
                  if (context.mounted) {
                    setState(() => _isExporting = false);
                  }
                }
              },
            ),
        ],
      ),
      body: attendancesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (allAttendances) {
          return usersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
            data: (allUsers) {
              // Filter data by selected month and year
              final monthData = allAttendances
                  .where((a) =>
                      a.date.month == _selectedMonth &&
                      a.date.year == _selectedYear)
                  .toList();

              // Hitung hari berjalan di bulan terpilih (atau total hari jika bulan lalu)
              final now = DateTime.now();
              int totalDaysInMonth;
              if (_selectedYear == now.year && _selectedMonth == now.month) {
                totalDaysInMonth = now.day;
              } else {
                totalDaysInMonth =
                    DateTime(_selectedYear, _selectedMonth + 1, 0).day;
              }

              return Column(
                children: [
                  // ── Filters ──────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      border: Border(
                        bottom: BorderSide(
                          color: theme.colorScheme.outline.withAlpha(40),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _selectedMonth,
                            decoration: InputDecoration(
                              labelText: 'Bulan',
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: List.generate(12, (index) {
                              return DropdownMenuItem(
                                value: index + 1,
                                child: Text(_months[index]),
                              );
                            }),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedMonth = val);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _selectedYear,
                            decoration: InputDecoration(
                              labelText: 'Tahun',
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: [
                              for (int i = 2024; i <= DateTime.now().year + 20; i++)
                                DropdownMenuItem(
                                  value: i,
                                  child: Text(i.toString()),
                                )
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedYear = val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── List ─────────────────────────────────────────────
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: allUsers.length,
                      itemBuilder: (context, index) {
                        final user = allUsers[index];
                        if (user.role == UserRole.admin) return const SizedBox.shrink();

                        // Hitung rekap per user
                        final userAttendances = monthData
                            .where((a) => a.userId == user.id)
                            .toList();

                        int hadir = 0;
                        int terlambat = 0;
                        int pulangAwal = 0;

                        for (final att in userAttendances) {
                          if (att.hasCheckedIn) hadir++;
                          if (att.attendanceStatus == AttendanceStatus.late_) terlambat++;
                          if (att.attendanceStatus == AttendanceStatus.earlyLeave) pulangAwal++;
                        }

                        // Tidak hadir = total hari berjalan dikurangi total absen masuk
                        int tidakHadir = totalDaysInMonth - hadir;
                        if (tidakHadir < 0) tidakHadir = 0;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: theme
                                          .colorScheme.primaryContainer,
                                      child: Text(
                                        user.initials,
                                        style: TextStyle(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            user.fullName,
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${user.employeeCode} • ${user.role.label}',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: theme.colorScheme.onSurface
                                                  .withAlpha(140),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.download_rounded),
                                      color: theme.colorScheme.primary,
                                      tooltip: 'Export data ${user.fullName}',
                                      onPressed: () async {
                                        setState(() => _isExporting = true);
                                        try {
                                          await ExportService.exportRecapToExcel(
                                            [user], // Hanya kirim 1 user
                                            monthData, // Data bulan ini
                                            _selectedMonth,
                                            _selectedYear,
                                          );
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Berhasil export rekap ${user.fullName}')),
                                            );
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Gagal export: $e')),
                                            );
                                          }
                                        } finally {
                                          if (context.mounted) {
                                            setState(() => _isExporting = false);
                                          }
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    _statItem(context, 'Hadir', hadir.toString(),
                                        AppTheme.successGreen),
                                    _statItem(context, 'Terlambat',
                                        terlambat.toString(), AppTheme.warningOrange),
                                    _statItem(context, 'Pulang Awal',
                                        pulangAwal.toString(), AppTheme.accentTeal),
                                    _statItem(context, 'Tidak Hadir',
                                        tidakHadir.toString(), AppTheme.errorRed),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _statItem(BuildContext context, String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(140),
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
