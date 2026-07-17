import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/enums.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../providers/attendance_provider.dart';
import '../services/location_service.dart';

/// Main layout with role-based bottom navigation.
class MainLayout extends ConsumerStatefulWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    // Check permission immediately when entering the main app
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLocationOnStartup();
    });
  }

  Future<void> _checkLocationOnStartup() async {
    try {
      await _locationService.checkPermission();
    } catch (e) {
      if (!mounted) return;
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppTheme.warningOrange),
              SizedBox(width: 8),
              Text('Izin Lokasi'),
            ],
          ),
          content: Text(errorMsg),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tutup'),
            ),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    }
  }

  int _calculateIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final user = ref.read(currentUserProvider);
    final isAdmin = user?.role == UserRole.admin;

    if (location.startsWith('/main/attendance')) return 1;
    if (location.startsWith('/main/history')) return 2;
    if (isAdmin && location.startsWith('/main/admin')) return 3;
    if (isAdmin && location.startsWith('/main/profile')) return 4;
    if (!isAdmin && location.startsWith('/main/profile')) return 3;
    return 0; // home
  }

  void _onTap(int index) {
    final user = ref.read(currentUserProvider);
    final isAdmin = user?.role == UserRole.admin;
    
    if (index != 1) {
      ref.read(overrideAttendanceProvider.notifier).state = null;
    }

    switch (index) {
      case 0:
        context.go('/main/home');
        break;
      case 1:
        context.go('/main/attendance');
        break;
      case 2:
        context.go('/main/history');
        break;
      case 3:
        if (isAdmin) {
          context.go('/main/admin');
        } else {
          context.go('/main/profile');
        }
        break;
      case 4:
        if (isAdmin) {
          context.go('/main/profile');
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isAdmin = user?.role == UserRole.admin;
    final currentIndex = _calculateIndex(context);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: _onTap,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.fingerprint_outlined),
            selectedIcon: Icon(Icons.fingerprint_rounded),
            label: 'Absensi',
          ),
          const NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'Riwayat',
          ),
          if (isAdmin)
            const NavigationDestination(
              icon: Icon(Icons.admin_panel_settings_outlined),
              selectedIcon: Icon(Icons.admin_panel_settings_rounded),
              label: 'Admin',
            ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
