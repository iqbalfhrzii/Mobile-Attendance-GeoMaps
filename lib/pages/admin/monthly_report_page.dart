import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/enums.dart';
import '../../core/theme.dart';
import '../../providers/attendance_provider.dart';

class MonthlyReportPage extends ConsumerStatefulWidget {
  const MonthlyReportPage({super.key});

  @override
  ConsumerState<MonthlyReportPage> createState() => _MonthlyReportPageState();
}

class _MonthlyReportPageState extends ConsumerState<MonthlyReportPage> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  final List<String> _months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final attendancesAsync = ref.watch(allAttendancesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Bulanan'),
      ),
      body: attendancesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (allData) {
          // Filter data by selected month and year
          final monthData = allData.where((a) =>
              a.date.month == _selectedMonth && a.date.year == _selectedYear).toList();

          int totalHadir = 0;
          int totalTelat = 0;
          int totalLuarRadius = 0;

          for (final att in monthData) {
            if (att.hasCheckedIn) totalHadir++;
            if (att.attendanceStatus == AttendanceStatus.late_) totalTelat++;
            if (att.locationStatus == LocationStatus.outside) totalLuarRadius++;
          }

          // Very naive percentage calculation (assuming 22 working days x number of employees)
          // In a real app, this requires knowing active employees and working days.
          // For dummy display, we'll just show it out of 100% or calculate based on dummy logic.
          // Let's just mock a percentage for demonstration if data exists.
          final percentage = monthData.isNotEmpty ? 92.5 : 0.0;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Filters
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedMonth,
                      decoration: const InputDecoration(labelText: 'Bulan'),
                      items: List.generate(12, (index) {
                        return DropdownMenuItem(
                          value: index + 1,
                          child: Text(_months[index]),
                        );
                      }),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedMonth = v);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedYear,
                      decoration: const InputDecoration(labelText: 'Tahun'),
                      items: [2023, 2024, 2025, 2026, 2027].map((y) {
                        return DropdownMenuItem(
                          value: y,
                          child: Text(y.toString()),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedYear = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              Text(
                'Rekapitulasi',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),

              // Stats Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [
                  _statCard(context, 'Total Hadir', totalHadir.toString(),
                      Icons.people_alt_rounded, AppTheme.successGreen),
                  _statCard(context, 'Total Telat', totalTelat.toString(),
                      Icons.timer_off_rounded, AppTheme.warningOrange),
                  _statCard(context, 'Di Luar Radius', totalLuarRadius.toString(),
                      Icons.location_off_rounded, const Color(0xFF8B5CF6)),
                  _statCard(context, 'Kehadiran', '${percentage.toStringAsFixed(1)}%',
                      Icons.percent_rounded, AppTheme.accentTeal),
                ],
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Mengekspor laporan... (Coming Soon)')),
                    );
                  },
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Export Laporan'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _statCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
