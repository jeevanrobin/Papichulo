import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/order_record.dart';
import 'api_config.dart';
import 'auth_service.dart';
import 'order_api_service.dart';

class OrderAlertService {
  OrderAlertService._();

  static final OrderAlertService instance = OrderAlertService._();

  final OrderApiService _api = OrderApiService();
  final ValueNotifier<int> pendingNewOrderCount = ValueNotifier<int>(0);
  final StreamController<OrderRecord> _newOrderController =
      StreamController<OrderRecord>.broadcast();

  Stream<OrderRecord> get newOrderStream => _newOrderController.stream;

  final Map<String, String> _orderStatuses = <String, String>{};
  final Set<String> _alertedOrderIds = <String>{};
  final Set<String> _knownOrderIds = <String>{};
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _channelSubscription;
  Timer? _reconnectTimer;
  bool _started = false;
  bool _connecting = false;
  bool _inFlight = false;

  void start() {
    if (_started) return;
    _started = true;
    refreshNow(silent: true);
    _connectWebSocket();
  }

  void stop() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _channelSubscription?.cancel();
    _channelSubscription = null;
    _channel?.sink.close();
    _channel = null;
    _connecting = false;
    _started = false;
    _knownOrderIds.clear();
    _orderStatuses.clear();
    pendingNewOrderCount.value = 0;
  }

  Future<void> refreshNow({bool silent = false}) async {
    if (!AuthService.instance.isAdmin) {
      pendingNewOrderCount.value = 0;
      return;
    }
    if (_inFlight) return;
    _inFlight = true;
    try {
      final orders = await _api.fetchOrders();
      _knownOrderIds
        ..clear()
        ..addAll(orders.map((order) => order.id));
      _orderStatuses
        ..clear()
        ..addEntries(orders.map((order) => MapEntry(order.id, order.status)));
      _recomputePending();
    } catch (_) {
      if (!silent) rethrow;
    } finally {
      _inFlight = false;
    }
  }

  void registerPlacedOrder(OrderRecord order) {
    if (order.id.isEmpty || order.status != 'new') return;
    _knownOrderIds.add(order.id);
    _orderStatuses[order.id] = order.status;
    _recomputePending();
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

  void _recomputePending() {
    final pending = _orderStatuses.values.where((status) => status == 'new');
    pendingNewOrderCount.value = pending.length;
  }

  void _connectWebSocket() {
    if (!_started || _connecting || !AuthService.instance.isAdmin) return;
    _connecting = true;
    _reconnectTimer?.cancel();

    final uri = _buildWsUri();
    try {
      final channel = WebSocketChannel.connect(uri);
      _channel = channel;
      _channelSubscription = channel.stream.listen(
        _onSocketMessage,
        onError: (_) => _scheduleReconnect(),
        onDone: _scheduleReconnect,
      );
    } catch (_) {
      _scheduleReconnect();
    } finally {
      _connecting = false;
    }
  }

  Uri _buildWsUri() {
    final baseUri = Uri.parse(ApiConfig.baseUrl);
    final wsScheme = baseUri.scheme == 'https' ? 'wss' : 'ws';
    final query = <String, String>{};

    final token = AuthService.instance.authToken;
    if (token != null && token.isNotEmpty) {
      query['token'] = token;
    }
    if (ApiConfig.adminKey.isNotEmpty) {
      query['adminKey'] = ApiConfig.adminKey;
    }

    return Uri(
      scheme: wsScheme,
      host: baseUri.host,
      port: baseUri.hasPort ? baseUri.port : null,
      path: '/ws/orders',
      queryParameters: query.isEmpty ? null : query,
    );
  }

  void _onSocketMessage(dynamic raw) {
    Map<String, dynamic> payload;
    try {
      final decoded = jsonDecode(raw.toString());
      if (decoded is! Map<String, dynamic>) return;
      payload = decoded;
    } catch (_) {
      return;
    }

    final type = (payload['type'] ?? '').toString();
    final orderRaw = payload['order'];
    if (orderRaw is! Map<String, dynamic>) return;

    final order = OrderRecord.fromJson(orderRaw);
    _knownOrderIds.add(order.id);
    _orderStatuses[order.id] = order.status;
    _recomputePending();

    if (type == 'order:new' && order.status == 'new') {
      _emitAlert(order);
    }
  }

  void _scheduleReconnect() {
    _channelSubscription?.cancel();
    _channelSubscription = null;
    _channel = null;
    if (!_started) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 2), _connectWebSocket);
  }
}
