import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';

/// Admin panel page — grid of management features.
class AdminPage extends ConsumerWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final menuItems = [
      _MenuItem(
        'Kelola Karyawan',
        Icons.people_outline_rounded,
        const Color(0xFF1A56DB),
        'Tambah, edit, hapus data karyawan',
        '/admin/employees',
      ),
      _MenuItem(
        'Laporan Absensi',
        Icons.assessment_outlined,
        AppTheme.accentTeal,
        'Lihat rekap absensi semua karyawan',
        '/admin/attendances',
      ),
      _MenuItem(
        'Laporan Bulanan',
        Icons.bar_chart_rounded,
        AppTheme.warningOrange,
        'Lihat rekapitulasi per bulan',
        '/admin/reports',
      ),
      _MenuItem(
        'Kelola Shift',
        Icons.schedule_outlined,
        AppTheme.accentAmber,
        'Atur jadwal shift karyawan',
        '/admin/shift',
      ),
      _MenuItem(
        'Lokasi Kantor',
        Icons.location_on_outlined,
        AppTheme.errorRed,
        'Atur titik lokasi absensi',
        '/admin/location',
      ),
      _MenuItem(
        'Notifikasi',
        Icons.notifications_outlined,
        AppTheme.successGreen,
        'Pengaturan pengingat',
        '',
      ),
    ];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Panel Admin',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Kelola data dan konfigurasi',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(140),
              ),
            ),
            const SizedBox(height: 24),

            // Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.05,
              ),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                return _AdminCard(item: item);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final String title;
  final IconData icon;
  final Color color;
  final String subtitle;
  final String path;

  const _MenuItem(this.title, this.icon, this.color, this.subtitle, this.path);
}

class _AdminCard extends StatelessWidget {
  final _MenuItem item;

  const _AdminCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (item.path.isNotEmpty) {
            context.push(item.path);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${item.title} — Coming Soon'),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                duration: const Duration(seconds: 1),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: item.color.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.color, size: 22),
              ),
              const Spacer(),
              Text(
                item.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                item.subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(100),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
