import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/admin_shell_route_scaffold.dart';
import '../screens/admin/menu_admin_screen.dart';
import '../screens/admin/orders_admin_page.dart';
import '../screens/auth/otp_verify_screen.dart';
import '../screens/auth/phone_login_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/menu/menu_screen.dart';
import '../screens/orders/user_orders_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../services/auth_service.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: AuthService.instance,
    redirect: (context, state) {
      final auth = AuthService.instance;
      final isAdmin = auth.isAdmin;
      final location = state.matchedLocation;
      final isAdminRoute = location.startsWith('/admin');

      if (location == '/splash') {
        return '/';
      }

      if (isAdminRoute && !isAdmin) {
        return '/';
      }

      if (location.startsWith('/auth/') && auth.isAuthenticated) {
        return isAdmin ? '/admin/dashboard' : '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/menu', builder: (context, state) => const MenuScreen()),
      GoRoute(
        path: '/auth/phone',
        builder: (context, state) => const PhoneLoginScreen(),
      ),
      GoRoute(
        path: '/auth/otp',
        builder: (context, state) {
          final phone = state.uri.queryParameters['phone'] ?? '';
          return OtpVerifyScreen(phone: phone);
        },
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const UserOrdersScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return AdminShellRouteScaffold(
            location: state.matchedLocation,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/admin/dashboard',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/orders',
            builder: (context, state) => const OrdersAdminPage(),
          ),
          GoRoute(
            path: '/admin/menu',
            builder: (context, state) => const MenuAdminScreen(),
          ),
        ],
      ),
    ],
  );
}
