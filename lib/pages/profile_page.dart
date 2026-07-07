import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../providers/auth_provider.dart';

/// Profile page showing user info and logout.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

    if (user == null) return const SizedBox.shrink();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await ref.read(authStateProvider.notifier).refreshUser();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            children: [
              // ── Avatar + Name ─────────────────────────────────────
              const SizedBox(height: 12),
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1A56DB).withAlpha(40),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  user.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.fullName,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                user.role.label,
                style: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── Info Cards ────────────────────────────────────────
            _infoTile(context, 'ID Karyawan', user.employeeCode,
                Icons.badge_outlined),
            _infoTile(context, 'Email', user.email, Icons.email_outlined),
            const SizedBox(height: 32),

            // ── Actions ──────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () => _showChangePasswordDialog(context, ref),
                icon: const Icon(Icons.lock_reset_rounded),
                label: const Text('Ganti Password'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Logout ────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text(
                          'Apakah anda yakin ingin keluar?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Batal'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Keluar'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await ref.read(authStateProvider.notifier).logout();
                    if (context.mounted) context.go('/login');
                  }
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Logout'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.errorRed,
                  side: const BorderSide(color: AppTheme.errorRed),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'AbsensiGeo v1.0.0',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(80),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _infoTile(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon,
                    size: 20, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(120),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ChangePasswordDialog(ref: ref),
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  final WidgetRef ref;
  const _ChangePasswordDialog({required this.ref});

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  
  String? _errorMessage;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);

    final current = _currentController.text.trim();
    final newPass = _newController.text.trim();
    final confirm = _confirmController.text.trim();

    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      setState(() => _errorMessage = 'Harap isi semua kolom password terlebih dahulu.');
      return;
    }
    
    if (newPass.length < 6) {
      setState(() => _errorMessage = 'Password baru harus terdiri dari minimal 6 karakter.');
      return;
    }
    
    if (newPass != confirm) {
      setState(() => _errorMessage = 'Konfirmasi password tidak cocok dengan password baru.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authRepo = widget.ref.read(authRepositoryProvider);
      await authRepo.changePassword(
        currentPassword: current,
        newPassword: newPass,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password berhasil diubah.'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ─────────────────────────────────────────
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_reset_rounded, size: 28, color: AppTheme.primaryBlue),
              ),
              const SizedBox(height: 16),
              const Text(
                'Ganti Password',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Pastikan password barumu aman\ndan mudah diingat.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(140),
                ),
              ),
              const SizedBox(height: 24),

              // ── Error Banner ───────────────────────────────────
              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorRed.withAlpha(15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.errorRed.withAlpha(40)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppTheme.errorRed, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: AppTheme.errorRed,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Inputs ─────────────────────────────────────────
              _buildInput(
                controller: _currentController,
                label: 'Password Saat Ini',
                obscure: _obscureCurrent,
                onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
              ),
              const SizedBox(height: 16),
              _buildInput(
                controller: _newController,
                label: 'Password Baru',
                obscure: _obscureNew,
                onToggle: () => setState(() => _obscureNew = !_obscureNew),
              ),
              const SizedBox(height: 16),
              _buildInput(
                controller: _confirmController,
                label: 'Konfirmasi Password Baru',
                obscure: _obscureConfirm,
                onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              const SizedBox(height: 32),

              // ── Actions ────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: BorderSide(color: Theme.of(context).colorScheme.outline.withAlpha(50)),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isLoading ? null : _submit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _isLoading 
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Simpan'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withAlpha(120)),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(80),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
          color: Theme.of(context).colorScheme.onSurface.withAlpha(120),
          onPressed: onToggle,
        ),
      ),
    );
  }
}
