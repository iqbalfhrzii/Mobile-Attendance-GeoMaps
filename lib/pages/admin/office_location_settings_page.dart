import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../providers/office_location_provider.dart';
import 'package:geolocator/geolocator.dart';

class OfficeLocationSettingsPage extends ConsumerStatefulWidget {
  const OfficeLocationSettingsPage({super.key});

  @override
  ConsumerState<OfficeLocationSettingsPage> createState() =>
      _OfficeLocationSettingsPageState();
}

class _OfficeLocationSettingsPageState
    extends ConsumerState<OfficeLocationSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _latCtrl;
  late TextEditingController _lngCtrl;
  late TextEditingController _radiusCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _latCtrl = TextEditingController();
    _lngCtrl = TextEditingController();
    _radiusCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _radiusCtrl.dispose();
    super.dispose();
  }

  void _populateForm(office) {
    if (_nameCtrl.text.isEmpty) {
      _nameCtrl.text = office.name;
      _latCtrl.text = office.latitude.toString();
      _lngCtrl.text = office.longitude.toString();
      _radiusCtrl.text = office.radiusMeter.toString();
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Layanan lokasi tidak aktif')),
        );
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Izin lokasi ditolak')),
          );
        }
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin lokasi ditolak permanen, aktifkan dari pengaturan')),
        );
      }
      return;
    } 

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mengambil lokasi saat ini...')),
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _latCtrl.text = position.latitude.toString();
        _lngCtrl.text = position.longitude.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lokasi berhasil diperbarui!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil lokasi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final officeAsync = ref.watch(primaryOfficeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lokasi Kantor'),
      ),
      body: officeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (office) {
          _populateForm(office);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pengaturan Lokasi Absensi',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tentukan titik koordinat pusat kantor dan radius jangkauan yang diperbolehkan untuk absensi.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(140),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nama Kantor'),
                    validator: (v) => v!.isEmpty ? 'Tidak boleh kosong' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _latCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true, signed: true),
                          decoration:
                              const InputDecoration(labelText: 'Latitude'),
                          validator: (v) =>
                              v!.isEmpty ? 'Tidak boleh kosong' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _lngCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true, signed: true),
                          decoration:
                              const InputDecoration(labelText: 'Longitude'),
                          validator: (v) =>
                              v!.isEmpty ? 'Tidak boleh kosong' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _getCurrentLocation,
                      icon: const Icon(Icons.my_location_rounded, size: 18),
                      label: const Text('Pakai Lokasi Saat Ini'),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _radiusCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Radius Absensi (meter)',
                      suffixText: 'm',
                    ),
                    validator: (v) => v!.isEmpty ? 'Tidak boleh kosong' : null,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          final repo = ref.read(officeLocationRepositoryProvider);
                          final updated = office.copyWith(
                            name: _nameCtrl.text.trim(),
                            latitude: double.tryParse(_latCtrl.text) ?? office.latitude,
                            longitude: double.tryParse(_lngCtrl.text) ?? office.longitude,
                            radiusMeter: double.tryParse(_radiusCtrl.text) ?? office.radiusMeter,
                          );
                          await repo.update(updated);
                          ref.invalidate(primaryOfficeProvider);
                          
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Lokasi kantor berhasil disimpan!')),
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
