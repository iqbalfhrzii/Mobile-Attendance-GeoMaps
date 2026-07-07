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
              child: RefreshIndicator(
                onRefresh: () => ref.refresh(attendanceHistoryProvider.future),
                child: historyAsync.when(
                  loading: () => ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                    ],
                  ),
                  error: (e, _) => ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline_rounded,
                                  size: 48,
                                  color: theme.colorScheme.error),
                              const SizedBox(height: 12),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Text(
                                  'Gagal memuat riwayat: $e',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: () => ref.refresh(attendanceHistoryProvider.future),
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Coba Lagi'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  data: (records) {
                    if (records.isEmpty) {
                      return LayoutBuilder(
                        builder: (context, constraints) => SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: constraints.maxHeight),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.history_rounded,
                                      size: 64,
                                      color: theme.colorScheme.onSurface.withAlpha(60)),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Belum ada riwayat absensi',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: theme.colorScheme.onSurface.withAlpha(100),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: records.length,
                      itemBuilder: (context, index) {
                        return AttendanceCard(attendance: records[index]);
                      },
                    );
                  },
                ),
              ),
          ),
        ],
      ),
    );
  }
}
