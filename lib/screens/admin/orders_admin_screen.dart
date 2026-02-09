import 'package:flutter/material.dart';

import '../../models/order_record.dart';
import '../../services/analytics_service.dart';
import '../../services/order_api_service.dart';

class OrdersAdminScreen extends StatefulWidget {
  const OrdersAdminScreen({super.key});

  @override
  State<OrdersAdminScreen> createState() => _OrdersAdminScreenState();
}

class _OrdersAdminScreenState extends State<OrdersAdminScreen> {
  static const Color goldYellow = Color(0xFFFFD700);
  static const Color black = Color(0xFF000000);
  static const Color darkGrey = Color(0xFF1A1A1A);

  final OrderApiService _api = OrderApiService();
  late Future<List<OrderRecord>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    AnalyticsService().track('page_view', params: {'screen': 'admin_orders'});
    _ordersFuture = _api.fetchOrders();
  }

  Future<void> _refresh() async {
    setState(() {
      _ordersFuture = _api.fetchOrders();
    });
    await _ordersFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incoming Orders'),
        backgroundColor: black,
        foregroundColor: goldYellow,
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      backgroundColor: darkGrey,
      body: FutureBuilder<List<OrderRecord>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 34),
                    const SizedBox(height: 10),
                    Text(
                      'Failed to load orders',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _refresh,
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final orders = snapshot.data ?? const <OrderRecord>[];
          if (orders.isEmpty) {
            return Center(
              child: Text(
                'No incoming orders yet.',
                style: TextStyle(color: Colors.grey[300], fontSize: 16),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final order = orders[index];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF222222),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: goldYellow.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Order ${order.id}',
                              style: const TextStyle(
                                color: goldYellow,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: goldYellow.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              order.status.toUpperCase(),
                              style: const TextStyle(
                                color: goldYellow,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Customer: ${order.customerName}', style: TextStyle(color: Colors.grey[200])),
                      Text('Phone: ${order.phone}', style: TextStyle(color: Colors.grey[200])),
                      Text('Address: ${order.address}', style: TextStyle(color: Colors.grey[300])),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'Items: ${order.itemCount}',
                            style: TextStyle(color: Colors.grey[300], fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Total: Rs ${order.totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(color: goldYellow, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Placed: ${order.createdAt.toLocal()}',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
