import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';

class AdminShellRouteScaffold extends StatelessWidget {
  final Widget child;
  final String location;

  const AdminShellRouteScaffold({
    super.key,
    required this.child,
    required this.location,
  });

  static const Color goldYellow = Color(0xFFFFD700);
  static const Color darkGrey = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    return Scaffold(
      backgroundColor: darkGrey,
      body: SafeArea(
        child: Row(
          children: [
            _AdminSidebar(location: location),
            Expanded(
              child: Column(
                children: [
                  Container(
                    height: 64,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      border: Border(
                        bottom: BorderSide(
                          color: goldYellow.withValues(alpha: 0.15),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _titleForLocation(location),
                          style: const TextStyle(
                            color: goldYellow,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: const Color(0x33FFD700),
                            border: Border.all(
                              color: goldYellow.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Text(
                            '${auth.user?.name ?? 'Admin'} (admin)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _titleForLocation(String value) {
    if (value.startsWith('/admin/orders')) return 'Orders';
    if (value.startsWith('/admin/menu')) return 'Menu';
    return 'Dashboard';
  }
}

class _AdminSidebar extends StatelessWidget {
  final String location;

  const _AdminSidebar({required this.location});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          right: BorderSide(
            color: AdminShellRouteScaffold.goldYellow.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 18),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => context.go('/'),
              child: const Text(
                'PAPICHULO',
                style: TextStyle(
                  color: AdminShellRouteScaffold.goldYellow,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.6,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          _SidebarItem(
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            active: location.startsWith('/admin/dashboard'),
            onTap: () => context.go('/admin/dashboard'),
          ),
          _SidebarItem(
            icon: Icons.receipt_long_outlined,
            label: 'Orders',
            active: location.startsWith('/admin/orders'),
            onTap: () => context.go('/admin/orders'),
          ),
          _SidebarItem(
            icon: Icons.restaurant_menu_outlined,
            label: 'Menu',
            active: location.startsWith('/admin/menu'),
            onTap: () => context.go('/admin/menu'),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFFFD700);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: active ? const Color(0x33FFD700) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: active ? gold : Colors.grey[300], size: 20),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    color: active ? gold : Colors.grey[300],
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
