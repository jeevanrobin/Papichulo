import 'package:flutter/material.dart';

import 'package:flutter/material.dart';

import '../../models/order_record.dart';

/// Card widget displaying a single past order.
class ProfileOrderCard extends StatelessWidget {
  final OrderRecord order;
  final VoidCallback onReorder;
  final VoidCallback onHelp;

  const ProfileOrderCard({
    super.key,
    required this.order,
    required this.onReorder,
    required this.onHelp,
  });

  static const Color _gold = Color(0xFFF5C842);
  static const Color _border = Color(0x1AFFFFFF);

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(order.status);
    final dateText = _formatDate(context, order.createdAt.toLocal());
    final itemText = _itemsSummary(order.items);
    final location = _locationSummary(order.address);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF202020),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border),
                ),
                child: const Icon(Icons.lunch_dining, color: _gold, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Papichulo Kitchen',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      location,
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ORDER #${order.id} | $dateText',
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  _statusLabel(order.status),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: _border),
          const SizedBox(height: 12),
          Text(
            '$itemText | Total Paid: Rs ${order.totalAmount.toStringAsFixed(2)}',
            style: TextStyle(color: Colors.grey[300], fontSize: 13),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: onReorder,
                style: FilledButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: Colors.black,
                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                ),
                child: const Text('REORDER'),
              ),
              OutlinedButton(
                onPressed: onHelp,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Color(0x33FFFFFF)),
                ),
                child: const Text('HELP'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _statusLabel(String status) {
    switch (status) {
      case 'new':
        return 'New';
      case 'accepted':
        return 'Accepted';
      case 'preparing':
        return 'Preparing';
      case 'out_for_delivery':
        return 'Out for delivery';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
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

  static String _itemsSummary(List<OrderLineItem> items) {
    if (items.isEmpty) return 'Order items';
    final first = items
        .take(2)
        .map((item) {
          final quantity = item.quantity > 0 ? item.quantity : 1;
          return '${item.name} x $quantity';
        })
        .join(', ');
    if (items.length <= 2) return first;
    return '$first +${items.length - 2} more';
  }

  static String _locationSummary(String address) {
    final clean = address.trim();
    if (clean.isEmpty) return 'Delivery location';
    final parts = clean.split(',');
    return parts.first.trim().isNotEmpty ? parts.first.trim() : clean;
  }

  static String _formatDate(BuildContext context, DateTime dateTime) {
    final localizations = MaterialLocalizations.of(context);
    final date = localizations.formatMediumDate(dateTime);
    final time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(dateTime),
    );
    return '$date, $time';
  }
}
