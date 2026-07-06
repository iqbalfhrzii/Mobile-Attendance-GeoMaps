import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/enums.dart';
import '../models/user_model.dart';
import '../pages/admin_page.dart';
import '../pages/attendance_page.dart';
import '../pages/history_page.dart';
import '../pages/home_page.dart';
import '../pages/login_page.dart';
import '../pages/main_layout.dart';
import '../pages/profile_page.dart';
import '../pages/splash_page.dart';
import '../providers/auth_provider.dart';

import '../pages/admin/employee_management_page.dart';
import '../pages/admin/attendance_management_page.dart';
import '../pages/admin/monthly_report_page.dart';
import '../pages/admin/office_location_settings_page.dart';
import '../pages/admin/shift_settings_page.dart';

/// A simple listenable to trigger GoRouter refreshes
class RouterNotifier extends ChangeNotifier {
  RouterNotifier(Ref ref) {
    ref.listen<AsyncValue<UserModel?>>(authStateProvider, (_, __) => notifyListeners());
    ref.listen<bool>(initialAuthLoadingProvider, (_, __) => notifyListeners());
  }
}

/// GoRouter configuration provider with route protection.
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/loading',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isInitialLoading = ref.read(initialAuthLoadingProvider);
      final currentUser = authState.valueOrNull;
      final isLoggedIn = currentUser != null;
      final path = state.uri.path;

      // ─── Initial App Loading State ───────────────────────────────
      // ONLY redirect to /loading when the app is booting up and checking session.
      if (isInitialLoading) {
        if (path != '/loading') return '/loading';
        return null;
      }
      
      // If done loading but still on the loading page, route them appropriately.
      if (!isInitialLoading && path == '/loading') {
        return isLoggedIn ? '/main/home' : '/login';
      }

      // If not logged in and trying to access protected routes → login
      if (!isLoggedIn && path != '/login') return '/login';

      // If logged in and trying to access login → redirect to home
      if (isLoggedIn && path == '/login') return '/main/home';

      // ─── Admin route protection ────────────────────────────────
      // If employee tries to access /main/admin or /admin → redirect to home
      if (isLoggedIn &&
          (path.startsWith('/main/admin') || path.startsWith('/admin')) &&
          currentUser?.role != UserRole.admin) {
        return '/main/home';
      }

      return null;
    },
    routes: [
// Splash route removed as per user request
// ...

      GoRoute(
        path: '/loading',
        builder: (context, state) => Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          body: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/admin/employees',
        builder: (context, state) => const EmployeeManagementPage(),
      ),
      GoRoute(
        path: '/admin/attendances',
        builder: (context, state) => const AttendanceManagementPage(),
      ),
      GoRoute(
        path: '/admin/reports',
        builder: (context, state) => const MonthlyReportPage(),
      ),
      GoRoute(
        path: '/admin/location',
        builder: (context, state) => const OfficeLocationSettingsPage(),
      ),
      GoRoute(
        path: '/admin/shift',
        builder: (context, state) => const ShiftSettingsPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          GoRoute(
            path: '/main/home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomePage(),
            ),
          ),
          GoRoute(
            path: '/main/attendance',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AttendancePage(),
            ),
          ),
          GoRoute(
            path: '/main/history',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HistoryPage(),
            ),
          ),
          GoRoute(
            path: '/main/admin',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AdminPage(),
            ),
          ),
          GoRoute(
            path: '/main/profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfilePage(),
            ),
          ),
        ],
      ),
      // Redirect bare /main to /main/home
      GoRoute(
        path: '/main',
        redirect: (_, __) => '/main/home',
      ),
    ],
  );
});
