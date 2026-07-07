import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../models/shift_model.dart';
import '../../providers/shift_provider.dart';

class ShiftSettingsPage extends ConsumerStatefulWidget {
  const ShiftSettingsPage({super.key});

  @override
  ConsumerState<ShiftSettingsPage> createState() => _ShiftSettingsPageState();
}

class _ShiftSettingsPageState extends ConsumerState<ShiftSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _toleranceCtrl;
  
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _toleranceCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _toleranceCtrl.dispose();
    super.dispose();
  }

  void _clearForm() {
    _nameCtrl.clear();
    _toleranceCtrl.clear();
    _startTime = null;
    _endTime = null;
  }

  void _populateForm(ShiftModel shift) {
    _nameCtrl.text = shift.name;
    _toleranceCtrl.text = shift.lateToleranceMinutes.toString();
    _startTime = TimeOfDay(hour: shift.checkInHour, minute: shift.checkInMinute);
    _endTime = TimeOfDay(hour: shift.checkOutHour, minute: shift.checkOutMinute);
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return '--:--';
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('HH:mm').format(dt);
  }

  void _showShiftForm({ShiftModel? shift}) {
    if (shift != null) {
      _populateForm(shift);
    } else {
      _clearForm();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shift == null ? 'Tambah Shift Baru' : 'Edit Shift',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(labelText: 'Nama Shift'),
                      validator: (v) => v!.isEmpty ? 'Tidak boleh kosong' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final initialTime = _startTime ?? TimeOfDay.now();
                              final time = await showTimePicker(
                                context: context,
                                initialTime: initialTime,
                              );
                              if (time != null) {
                                setModalState(() {
                                  _startTime = time;
                                });
                                setState(() {
                                  _startTime = time;
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'Jam Masuk'),
                              child: Text(
                                _formatTime(_startTime),
                                style: theme.textTheme.bodyLarge,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final initialTime = _endTime ?? TimeOfDay.now();
                              final time = await showTimePicker(
                                context: context,
                                initialTime: initialTime,
                              );
                              if (time != null) {
                                setModalState(() {
                                  _endTime = time;
                                });
                                setState(() {
                                  _endTime = time;
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'Jam Pulang'),
                              child: Text(
                                _formatTime(_endTime),
                                style: theme.textTheme.bodyLarge,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _toleranceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Toleransi Keterlambatan',
                        suffixText: 'menit',
                      ),
                      validator: (v) => v!.isEmpty ? 'Tidak boleh kosong' : null,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate() && _startTime != null && _endTime != null) {
                            final notifier = ref.read(shiftNotifierProvider.notifier);
                            
                            final checkInTimeStr = '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}';
                            final checkOutTimeStr = '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}';
                            final tolerance = int.tryParse(_toleranceCtrl.text) ?? 0;

                            if (shift == null) {
                              // Add new shift
                              final newShift = ShiftModel(
                                id: DateTime.now().millisecondsSinceEpoch.toString(), // Temp ID, maybe ignored by DB if auto generated
                                name: _nameCtrl.text.trim(),
                                checkInTime: checkInTimeStr,
                                checkOutTime: checkOutTimeStr,
                                lateToleranceMinutes: tolerance,
                              );
                              await notifier.addShift(newShift);
                            } else {
                              // Update existing
                              final updated = shift.copyWith(
                                name: _nameCtrl.text.trim(),
                                checkInTime: checkInTimeStr,
                                checkOutTime: checkOutTimeStr,
                                lateToleranceMinutes: tolerance,
                              );
                              await notifier.updateShift(updated);
                            }
                            
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(shift == null ? 'Shift ditambahkan!' : 'Shift diperbarui!')),
                              );
                            }
                          } else if (_startTime == null || _endTime == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Jam Masuk dan Jam Pulang harus diisi')),
                            );
                          }
                        },
                        child: const Text('Simpan'),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(ShiftModel shift) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Shift'),
        content: Text('Apakah Anda yakin ingin menghapus shift "${shift.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final notifier = ref.read(shiftNotifierProvider.notifier);
      await notifier.deleteShift(shift.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shift dihapus!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shiftsAsync = ref.watch(allShiftsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Shift'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showShiftForm(),
        child: const Icon(Icons.add),
      ),
      body: shiftsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (shifts) {
          if (shifts.isEmpty) {
            return const Center(child: Text('Belum ada data shift.'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(allShiftsProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: shifts.length,
              itemBuilder: (context, index) {
                final shift = shifts[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.schedule_rounded, color: theme.colorScheme.primary),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                shift.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${shift.displayTime} • Toleransi: ${shift.lateToleranceMinutes} mnt',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withAlpha(150),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Actions
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded),
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showShiftForm(shift: shift);
                            } else if (value == 'delete') {
                              _confirmDelete(shift);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_rounded, size: 20),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_rounded, size: 20, color: AppTheme.errorRed),
                                  SizedBox(width: 8),
                                  Text('Hapus', style: TextStyle(color: AppTheme.errorRed)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
