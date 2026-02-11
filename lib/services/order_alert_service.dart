import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/order_record.dart';
import 'order_api_service.dart';

class OrderAlertService {
  OrderAlertService._();

  static final OrderAlertService instance = OrderAlertService._();

  final OrderApiService _api = OrderApiService();
  final ValueNotifier<int> pendingNewOrderCount = ValueNotifier<int>(0);
  final StreamController<OrderRecord> _newOrderController =
      StreamController<OrderRecord>.broadcast();

  Stream<OrderRecord> get newOrderStream => _newOrderController.stream;

  final Set<String> _knownOrderIds = <String>{};
  final Set<String> _alertedOrderIds = <String>{};
  Timer? _pollTimer;
  bool _started = false;
  bool _seeded = false;
  bool _inFlight = false;

  void start() {
    if (_started) return;
    _started = true;
    refreshNow(silent: true);
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      refreshNow(silent: true);
    });
  }

  void stop() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _started = false;
  }

  Future<void> refreshNow({bool silent = false}) async {
    if (_inFlight) return;
    _inFlight = true;
    try {
      final orders = await _api.fetchOrders();
      final newOrders = orders.where((order) => order.status == 'new').toList();
      pendingNewOrderCount.value = newOrders.length;

      if (!_seeded) {
        _knownOrderIds.addAll(orders.map((order) => order.id));
        _seeded = true;
        return;
      }

      for (final order in newOrders) {
        if (_knownOrderIds.contains(order.id)) continue;
        _emitAlert(order);
      }
      _knownOrderIds.addAll(orders.map((order) => order.id));
    } catch (_) {
      if (!silent) rethrow;
    } finally {
      _inFlight = false;
    }
  }

  void registerPlacedOrder(OrderRecord order) {
    if (order.id.isEmpty || order.status != 'new') return;
    _knownOrderIds.add(order.id);
    pendingNewOrderCount.value = pendingNewOrderCount.value + 1;
    _emitAlert(order);
  }

  void markOrderHandled(String orderId) {
    _alertedOrderIds.remove(orderId);
  }

  void _emitAlert(OrderRecord order) {
    if (_alertedOrderIds.contains(order.id)) return;
    _alertedOrderIds.add(order.id);
    _newOrderController.add(order);
  }
}

