import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/enums.dart';
import '../../core/theme.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';

class EmployeeManagementPage extends ConsumerStatefulWidget {
  const EmployeeManagementPage({super.key});

  @override
  ConsumerState<EmployeeManagementPage> createState() =>
      _EmployeeManagementPageState();
}

class _EmployeeManagementPageState
    extends ConsumerState<EmployeeManagementPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usersAsync = ref.watch(allUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Karyawan'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEmployeeDialog(context, null),
        backgroundColor: AppTheme.successGreen,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (users) {
          if (users.isEmpty) {
            return const Center(child: Text('Tidak ada karyawan.'));
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(allUsersProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(user.initials),
                    ),
                    title: Text(
                      user.fullName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text('${user.employeeCode} • ${user.role.label}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _showEmployeeDialog(context, user),
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

  void _showEmployeeDialog(BuildContext context, UserModel? existingUser) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _EmployeeForm(
          user: existingUser,
          onSave: (newUser, password) async {
            final repo = ref.read(userRepositoryProvider);
            try {
              if (existingUser == null) {
                if (password == null || password.isEmpty) {
                  throw Exception('Password wajib diisi untuk karyawan baru');
                }
                await repo.add(newUser, password: password);
              } else {
                // Run data update & password change in parallel for speed
                await Future.wait([
                  repo.update(newUser),
                  if (password != null && password.isNotEmpty)
                    repo.changeEmployeePassword(newUser, password),
                ]);
              }
              ref.invalidate(allUsersProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(existingUser == null 
                        ? 'Karyawan berhasil ditambahkan!' 
                        : 'Karyawan berhasil diedit!'),
                    backgroundColor: AppTheme.successGreen,
                  ),
                );
              }
            } catch (e) {
              rethrow;
            }
          },
          onDelete: existingUser == null
              ? null
              : () async {
                  final repo = ref.read(userRepositoryProvider);
                  await repo.delete(existingUser.id);
                  ref.invalidate(allUsersProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Karyawan berhasil dihapus!'),
                        backgroundColor: AppTheme.successGreen,
                      ),
                    );
                  }
                },
        );
      },
    );
  }
}

class _EmployeeForm extends StatefulWidget {
  final UserModel? user;
  final Future<void> Function(UserModel, String?) onSave;
  final Future<void> Function()? onDelete;

  const _EmployeeForm({
    super.key,
    this.user,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<_EmployeeForm> createState() => _EmployeeFormState();
}

class _EmployeeFormState extends State<_EmployeeForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _codeCtrl;
  late TextEditingController _passwordCtrl;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  UserRole _role = UserRole.employee;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user?.fullName ?? '');
    _emailCtrl = TextEditingController(text: widget.user?.email ?? '');
    _codeCtrl = TextEditingController(text: widget.user?.employeeCode ?? '');
    _passwordCtrl = TextEditingController();
    if (widget.user != null) {
      _role = widget.user!.role;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.user != null;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, bottomInset + 24),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(
              isEditing ? 'Edit Karyawan' : 'Tambah Karyawan',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nama Lengkap'),
              validator: (v) => v!.isEmpty ? 'Tidak boleh kosong' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _codeCtrl,
              decoration: const InputDecoration(labelText: 'Kode Karyawan'),
              validator: (v) => v!.isEmpty ? 'Tidak boleh kosong' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (v) => v!.isEmpty ? 'Tidak boleh kosong' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: isEditing ? 'Password Baru (Opsional)' : 'Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              validator: (v) {
                if (!isEditing && (v == null || v.isEmpty)) return 'Tidak boleh kosong';
                if (v != null && v.isNotEmpty && v.length < 6) return 'Minimal 6 karakter';
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<UserRole>(
              value: _role,
              decoration: const InputDecoration(labelText: 'Role'),
              items: UserRole.values.map((r) {
                return DropdownMenuItem(
                  value: r,
                  child: Text(r.label),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _role = v);
              },
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.errorRed.withOpacity(0.5)),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: AppTheme.errorRed, fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isLoading ? null : () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() {
                      _isLoading = true;
                      _errorMessage = null;
                    });
                    final user = UserModel(
                      id: isEditing
                          ? widget.user!.id
                          : '', // Firestore UID will be generated in repo
                      employeeCode: _codeCtrl.text.trim(),
                      fullName: _nameCtrl.text.trim(),
                      email: _emailCtrl.text.trim(),
                      role: _role,
                      createdAt: isEditing
                          ? widget.user!.createdAt
                          : DateTime.now(),
                    );
                    try {
                      final pass = _passwordCtrl.text.isNotEmpty ? _passwordCtrl.text : null;
                      await widget.onSave(user, pass);
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      if (mounted) {
                        setState(() {
                          _errorMessage = e.toString().replaceAll('Exception: ', '');
                        });
                      }
                    } finally {
                      if (mounted) setState(() => _isLoading = false);
                    }
                  }
                },
                child: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(isEditing ? 'Simpan Perubahan' : 'Tambah'),
              ),
            ),
            if (isEditing) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Hapus Karyawan'),
                        content: const Text('Apakah Anda yakin ingin menghapus data karyawan ini? Tindakan ini tidak dapat dibatalkan.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Batal'),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Hapus'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      setState(() => _isLoading = true);
                      try {
                        await widget.onDelete?.call();
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        if (mounted) {
                          setState(() {
                            _errorMessage = e.toString().replaceAll('Exception: ', '');
                          });
                        }
                      } finally {
                        if (mounted) setState(() => _isLoading = false);
                      }
                    }
                  },
                  child: _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.errorRed))
                      : const Text('Hapus Karyawan'),
                ),
              ),
            ]
          ],
        ),
      ),
      ),
    );
  }
}
