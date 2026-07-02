import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../pages/admin_page.dart';
import '../pages/attendance_page.dart';
import '../pages/history_page.dart';
import '../pages/home_page.dart';
import '../pages/login_page.dart';
import '../pages/main_layout.dart';
import '../pages/profile_page.dart';
import '../pages/splash_page.dart';
import '../providers/auth_provider.dart';

/// GoRouter configuration provider.
final routerProvider = Provider<GoRouter>((ref) {
  final isLoggedIn = ref.watch(isLoggedInProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final path = state.uri.path;

      // Allow splash always
      if (path == '/splash') return null;

      // If not logged in and trying to access protected routes
      if (!isLoggedIn && path != '/login') return '/login';

      // If logged in and trying to access login
      if (isLoggedIn && path == '/login') return '/main/home';

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
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
