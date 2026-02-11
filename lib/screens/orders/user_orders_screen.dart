import 'package:flutter/material.dart';

import '../../models/order_record.dart';
import '../../services/order_api_service.dart';

class UserOrdersScreen extends StatefulWidget {
  const UserOrdersScreen({super.key});

  @override
  State<UserOrdersScreen> createState() => _UserOrdersScreenState();
}

class _UserOrdersScreenState extends State<UserOrdersScreen> {
  static const Color goldYellow = Color(0xFFFFD700);
  final OrderApiService _api = OrderApiService();
  late Future<List<OrderRecord>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _api.fetchMyOrders();
  }

  Future<void> _refresh() async {
    setState(() {
      _ordersFuture = _api.fetchMyOrders();
    });
    await _ordersFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: Colors.black,
        foregroundColor: goldYellow,
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      backgroundColor: const Color(0xFF151515),
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
                    const Icon(
                      Icons.error_outline,
                      color: Colors.redAccent,
                      size: 36,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Failed to load your orders',
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[400]),
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
                'No orders yet.',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.grey[300]),
              ),
            );
          }

          return ListView.separated(
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Order ${order.id}',
                          style: const TextStyle(
                            color: goldYellow,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        _statusChip(order.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Items: ${order.itemCount}   Total: Rs ${order.totalAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.grey[100],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Address: ${order.address}',
                      style: TextStyle(color: Colors.grey[300]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Placed: ${order.createdAt}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _statusChip(String status) {
    final text = status.toUpperCase();
    final color = switch (status) {
      'new' => Colors.orangeAccent,
      'accepted' => Colors.lightBlueAccent,
      'preparing' => Colors.deepPurpleAccent,
      'out_for_delivery' => Colors.amber,
      'delivered' => Colors.green,
      'cancelled' => Colors.redAccent,
      _ => Colors.grey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
