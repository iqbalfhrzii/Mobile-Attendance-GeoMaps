import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
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

  void _populateForm(shift) {
    if (_nameCtrl.text.isEmpty && _startTime == null) {
      _nameCtrl.text = shift.name;
      _toleranceCtrl.text = shift.lateToleranceMinutes.toString();
      _startTime = TimeOfDay(hour: shift.checkInHour, minute: shift.checkInMinute);
      _endTime = TimeOfDay(hour: shift.checkOutHour, minute: shift.checkOutMinute);
    }
  }

  Future<void> _selectTime(bool isStart) async {
    final initialTime = isStart ? _startTime : _endTime;
    final time = await showTimePicker(
      context: context,
      initialTime: initialTime ?? TimeOfDay.now(),
    );
    if (time != null) {
      setState(() {
        if (isStart) _startTime = time;
        else _endTime = time;
      });
    }
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return '--:--';
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shiftAsync = ref.watch(defaultShiftProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Shift'),
      ),
      body: shiftAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (shift) {
          _populateForm(shift);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pengaturan Shift Kerja',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tentukan jam kerja operasional standar untuk seluruh karyawan.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(140),
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
                          onTap: () => _selectTime(true),
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
                          onTap: () => _selectTime(false),
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
                          final repo = ref.read(shiftRepositoryProvider);
                          final now = DateTime.now();
                          final updated = shift.copyWith(
                            name: _nameCtrl.text.trim(),
                            checkInTime: '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}',
                            checkOutTime: '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}',
                            lateToleranceMinutes: int.tryParse(_toleranceCtrl.text) ?? shift.lateToleranceMinutes,
                          );
                          await repo.update(updated);
                          ref.invalidate(defaultShiftProvider);
                          
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Shift berhasil disimpan!')),
                            );
                            Navigator.pop(context);
                          }
                        }
                      },
                      child: const Text('Simpan Pengaturan'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
