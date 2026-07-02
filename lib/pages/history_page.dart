import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/attendance_provider.dart';
import '../widgets/attendance_card.dart';

/// History page showing past attendance records.
class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(attendanceHistoryProvider);
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Text(
              'Riwayat Absensi',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Daftar absensi anda sebelumnya',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(140),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // List
          Expanded(
            child: historyAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline_rounded,
                        size: 48,
                        color: theme.colorScheme.error),
                    const SizedBox(height: 12),
                    Text('Gagal memuat riwayat: $e'),
                  ],
                ),
              ),
              data: (records) {
                if (records.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history_rounded,
                            size: 64,
                            color: theme.colorScheme.onSurface
                                .withAlpha(60)),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada riwayat absensi',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withAlpha(100),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => ref.refresh(attendanceHistoryProvider.future),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: records.length,
                    itemBuilder: (context, index) {
                      return AttendanceCard(attendance: records[index]);
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
}
