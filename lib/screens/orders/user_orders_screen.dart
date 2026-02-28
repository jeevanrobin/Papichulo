import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/menu_data.dart';
import '../../models/order_record.dart';
import '../../providers/cart_provider.dart';
import '../../services/order_api_service.dart';

class UserOrdersScreen extends StatefulWidget {
  const UserOrdersScreen({super.key});

  @override
  State<UserOrdersScreen> createState() => _UserOrdersScreenState();
}

class _UserOrdersScreenState extends State<UserOrdersScreen> {
  static const Color goldYellow = Color(0xFFFFD700);
  final OrderApiService _api = OrderApiService();
  List<OrderRecord> _orders = const <OrderRecord>[];
  bool _isLoading = true;
  String? _error;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _loadOrders(silent: true),
    );
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOrders({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final orders = await _api.fetchMyOrders();
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _isLoading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      if (!silent) {
        setState(() {
          _isLoading = false;
          _error = error.toString();
        });
      }
    }
  }

  void _reorder(OrderRecord order) {
    final cart = context.read<CartProvider>().cartService;
    int addedCount = 0;
    for (final lineItem in order.items) {
      final match = papichuloMenu.where(
        (f) => f.name.toLowerCase() == lineItem.name.toLowerCase(),
      );
      if (match.isNotEmpty) {
        for (int i = 0; i < lineItem.quantity; i++) {
          cart.addItem(match.first);
        }
        addedCount += lineItem.quantity;
      }
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          addedCount > 0
              ? '$addedCount item${addedCount > 1 ? 's' : ''} added to cart'
              : 'Could not find items in current menu',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: goldYellow,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
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
            onPressed: _loadOrders,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      backgroundColor: const Color(0xFF151515),
      body: _isLoading && _orders.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _orders.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.redAccent, size: 36),
                        const SizedBox(height: 10),
                        Text(
                          'Failed to load your orders',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Text(_error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[400])),
                        const SizedBox(height: 16),
                        ElevatedButton(
                            onPressed: _loadOrders,
                            child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : _orders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('📦',
                              style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 12),
                          Text('No orders yet',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: Colors.white)),
                          const SizedBox(height: 6),
                          Text('Your order history will show up here.',
                              style: TextStyle(color: Colors.grey[400])),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadOrders,
                      color: goldYellow,
                      backgroundColor: const Color(0xFF222222),
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: _orders.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final order = _orders[index];
                          return _OrderCard(
                            order: order,
                            onReorder: () => _reorder(order),
                          );
                        },
                      ),
                    ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderRecord order;
  final VoidCallback onReorder;
  static const Color goldYellow = Color(0xFFFFD700);

  const _OrderCard({required this.order, required this.onReorder});

  @override
  Widget build(BuildContext context) {
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
                    color: goldYellow, fontWeight: FontWeight.bold),
              ),
              _statusChip(order.status),
            ],
          ),
          const SizedBox(height: 10),
          _StatusTracker(status: order.status),
          const SizedBox(height: 10),
          Text(
            'Items: ${order.itemCount}   Total: Rs ${order.totalAmount.toStringAsFixed(2)}',
            style: TextStyle(
                color: Colors.grey[100], fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text('Address: ${order.address}',
              style: TextStyle(color: Colors.grey[300])),
          const SizedBox(height: 4),
          Text('Placed: ${order.createdAt}',
              style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          // Order Again button for delivered / cancelled orders
          if (order.status == 'delivered' || order.status == 'cancelled') ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onReorder,
                icon: const Icon(Icons.replay_rounded, size: 16),
                label: const Text('Order Again'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: goldYellow,
                  side: BorderSide(color: goldYellow.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    final text = status.toUpperCase();
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }

  static Color _statusColor(String status) {
    return switch (status) {
      'new' => Colors.orangeAccent,
      'accepted' => Colors.lightBlueAccent,
      'preparing' => Colors.deepPurpleAccent,
      'out_for_delivery' => Colors.amber,
      'delivered' => Colors.green,
      'cancelled' => Colors.redAccent,
      _ => Colors.grey,
    };
  }
}

class _StatusTracker extends StatelessWidget {
  final String status;
  const _StatusTracker({required this.status});

  static const _steps = [
    'new', 'accepted', 'preparing', 'out_for_delivery', 'delivered'
  ];
  static const _labels = [
    'Placed', 'Accepted', 'Preparing', 'On the way', 'Delivered'
  ];

  int get _currentIndex {
    if (status == 'cancelled') return -1;
    final idx = _steps.indexOf(status);
    return idx >= 0 ? idx : 0;
  }

  @override
  Widget build(BuildContext context) {
    if (status == 'cancelled') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 16),
            SizedBox(width: 6),
            Text('Order Cancelled',
                style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w600,
                    fontSize: 12)),
          ],
        ),
      );
    }

    final currentIndex = _currentIndex;
    return Row(
      children: List.generate(_steps.length, (i) {
        final isDone = i <= currentIndex;
        final isCurrent = i == currentIndex;
        final color =
            isDone ? _OrderCard._statusColor(_steps[i]) : Colors.grey[700]!;

        return Expanded(
          child: Row(
            children: [
              Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    width: isCurrent ? 18 : 14,
                    height: isCurrent ? 18 : 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone ? color : Colors.transparent,
                      border: Border.all(
                          color: color, width: isCurrent ? 2.5 : 1.5),
                      boxShadow: isCurrent
                          ? [BoxShadow(
                              color: color.withOpacity(0.5), blurRadius: 8)]
                          : null,
                    ),
                    child: isDone
                        ? const Icon(Icons.check,
                            size: 10, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _labels[i],
                    style: TextStyle(
                      color: isDone ? Colors.white : Colors.grey[600],
                      fontSize: 9,
                      fontWeight:
                          isCurrent ? FontWeight.w700 : FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              if (i < _steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    color: i < currentIndex ? color : Colors.grey[800],
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}
