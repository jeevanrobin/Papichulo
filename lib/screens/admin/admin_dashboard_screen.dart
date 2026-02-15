import 'package:flutter/material.dart';

import '../../services/order_api_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final OrderApiService _api = OrderApiService();
  late Future<_AdminMetrics> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_AdminMetrics> _load() async {
    final orders = await _api.fetchOrders();
    final menu = await _api.fetchAdminMenu();
    final now = DateTime.now();
    final todayOrders = orders.where((o) {
      final d = o.createdAt.toLocal();
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).toList();

    final activeOrders = orders.where((o) {
      return o.status == 'new' ||
          o.status == 'accepted' ||
          o.status == 'preparing';
    }).length;

    final todayRevenue = todayOrders.fold<double>(
      0,
      (sum, o) => sum + o.totalAmount,
    );
    final menuCount = menu.length;
    final availableCount = menu.where((m) => m['available'] == true).length;
    return _AdminMetrics(
      totalOrders: orders.length,
      activeOrders: activeOrders,
      todayOrders: todayOrders.length,
      todayRevenue: todayRevenue,
      menuCount: menuCount,
      availableCount: availableCount,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AdminMetrics>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Center(
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _future = _load();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Reload'),
            ),
          );
        }
        final metrics = snapshot.data!;
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _MetricCard(
                    title: 'Total Orders',
                    value: '${metrics.totalOrders}',
                  ),
                  _MetricCard(
                    title: 'Active Orders',
                    value: '${metrics.activeOrders}',
                  ),
                  _MetricCard(
                    title: 'Today Orders',
                    value: '${metrics.todayOrders}',
                  ),
                  _MetricCard(
                    title: 'Today Revenue',
                    value: 'Rs ${metrics.todayRevenue.toStringAsFixed(2)}',
                  ),
                  _MetricCard(
                    title: 'Menu Items',
                    value: '${metrics.menuCount}',
                  ),
                  _MetricCard(
                    title: 'Available Items',
                    value: '${metrics.availableCount}',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;

  const _MetricCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF222222),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFFD700).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[300], fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFFFD700),
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminMetrics {
  final int totalOrders;
  final int activeOrders;
  final int todayOrders;
  final double todayRevenue;
  final int menuCount;
  final int availableCount;

  const _AdminMetrics({
    required this.totalOrders,
    required this.activeOrders,
    required this.todayOrders,
    required this.todayRevenue,
    required this.menuCount,
    required this.availableCount,
  });
}
