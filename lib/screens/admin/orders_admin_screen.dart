import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/delivery_config.dart';
import '../../models/order_record.dart';
import '../../services/analytics_service.dart';
import '../../services/order_api_service.dart';

class OrdersAdminScreen extends StatefulWidget {
  final bool showScaffold;

  const OrdersAdminScreen({super.key}) : showScaffold = true;

  const OrdersAdminScreen.embedded({super.key}) : showScaffold = false;

  @override
  State<OrdersAdminScreen> createState() => _OrdersAdminScreenState();
}

class _OrdersAdminScreenState extends State<OrdersAdminScreen> {
  static const Color goldYellow = Color(0xFFFFD700);
  static const Color black = Color(0xFF000000);
  static const Color darkGrey = Color(0xFF1A1A1A);

  final OrderApiService _api = OrderApiService();
  late Future<List<OrderRecord>> _ordersFuture;
  late Future<DeliveryConfig> _configFuture;
  final TextEditingController _radiusController = TextEditingController();
  double? _storeLatitude;
  double? _storeLongitude;
  bool _savingConfig = false;
  bool _detectingStoreLocation = false;
  Timer? _pollTimer;
  _OrderListView _selectedView = _OrderListView.incoming;
  String _storeAreaLabel = '';

  @override
  void initState() {
    super.initState();
    AnalyticsService().track('page_view', params: {'screen': 'admin_orders'});
    _ordersFuture = _fetchOrdersWithAlerts();
    _configFuture = _api.fetchDeliveryConfig();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _refresh(silent: true);
    });
  }

  Future<void> _refresh({bool silent = false}) async {
    setState(() {
      _ordersFuture = _fetchOrdersWithAlerts();
      _configFuture = _api.fetchDeliveryConfig();
    });
    try {
      await Future.wait([_ordersFuture, _configFuture]);
    } catch (_) {
      if (!silent) rethrow;
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _radiusController.dispose();
    super.dispose();
  }

  Future<List<OrderRecord>> _fetchOrdersWithAlerts() async {
    return _api.fetchOrders();
  }

  Future<void> _saveDeliveryConfig() async {
    final radius = double.tryParse(_radiusController.text.trim());
    final storeLat = _storeLatitude;
    final storeLng = _storeLongitude;

    if (radius == null ||
        radius <= 0 ||
        radius > 50 ||
        storeLat == null ||
        storeLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Detect store location and set radius (1-50 km).'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _savingConfig = true);
    try {
      final updated = await _api.updateDeliveryConfig(
        storeLatitude: storeLat,
        storeLongitude: storeLng,
        radiusKm: radius,
      );
      if (!mounted) return;
      setState(() {
        _configFuture = Future.value(updated);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Delivery settings updated.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save delivery settings: $error'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _savingConfig = false);
      }
    }
  }

  Future<void> _moveOrderToNextStage(OrderRecord order) async {
    final nextStatus = _nextStatus(order.status);
    if (nextStatus == null) return;
    try {
      await _api.updateOrderStatus(orderId: order.id, status: nextStatus);
      if (!mounted) return;
      await _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order ${order.id} moved to ${_labelForStatus(nextStatus)}.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update order status: $error'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  String? _nextStatus(String status) {
    switch (status) {
      case 'new':
        return 'accepted';
      case 'accepted':
        return 'preparing';
      case 'preparing':
        return 'out_for_delivery';
      default:
        return null;
    }
  }

  String _labelForStatus(String status) {
    switch (status) {
      case 'new':
        return 'New';
      case 'accepted':
        return 'Accepted';
      case 'preparing':
        return 'Preparing';
      case 'out_for_delivery':
        return 'Sent to Delivery';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.toUpperCase();
    }
  }

  String _nextActionLabel(String status) {
    switch (status) {
      case 'new':
        return 'Accept Order';
      case 'accepted':
        return 'Mark Preparing';
      case 'preparing':
        return 'Send to Delivery';
      default:
        return '';
    }
  }

  Future<void> _useCurrentLocationForStore() async {
    setState(() => _detectingStoreLocation = true);
    try {
      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        throw Exception('Location services are disabled.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied.');
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permission permanently denied. Enable it in browser/system settings.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final areaName = await _api.reverseGeocode(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (!mounted) return;
      setState(() {
        _storeLatitude = position.latitude;
        _storeLongitude = position.longitude;
        _storeAreaLabel = areaName;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Store location updated: $_storeAreaLabel'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not detect current location: $error'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _detectingStoreLocation = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildBody();
    if (!widget.showScaffold) {
      return content;
    }

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
      body: content,
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: FutureBuilder<DeliveryConfig>(
            future: _configFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LinearProgressIndicator();
              }
              if (snapshot.hasError || snapshot.data == null) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF222222),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.redAccent.withOpacity(0.35),
                    ),
                  ),
                  child: Text(
                    'Could not load delivery config: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }

              final config = snapshot.data!;
              if (_radiusController.text.isEmpty) {
                _radiusController.text = config.radiusKm.toStringAsFixed(1);
              }
              if (_storeLatitude == null || _storeLongitude == null) {
                _storeLatitude = config.storeLatitude;
                _storeLongitude = config.storeLongitude;
              }
              if (_storeAreaLabel.isEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  try {
                    final label = await _api.reverseGeocode(
                      latitude: config.storeLatitude,
                      longitude: config.storeLongitude,
                    );
                    if (!mounted) return;
                    setState(() => _storeAreaLabel = label);
                  } catch (_) {}
                });
              }

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF222222),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: goldYellow.withOpacity(0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Delivery Settings',
                      style: TextStyle(
                        color: goldYellow,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            _radiusController,
                            'Radius (km)',
                            const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            onPressed: _savingConfig
                                ? null
                                : _saveDeliveryConfig,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: goldYellow,
                              foregroundColor: Colors.black,
                            ),
                            child: _savingConfig
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Save'),
                          ),
                        ),
                      ],
                    ),
                    if (_storeAreaLabel.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Store area: $_storeAreaLabel',
                        style: TextStyle(color: Colors.grey[300], fontSize: 12),
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      Text(
                        'Store area not detected yet. Use current location below.',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: _detectingStoreLocation
                              ? null
                              : _useCurrentLocationForStore,
                          icon: _detectingStoreLocation
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.my_location, size: 16),
                          label: Text(
                            _detectingStoreLocation
                                ? 'Detecting...'
                                : 'Use Current Location',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: goldYellow,
                            side: BorderSide(
                              color: goldYellow.withOpacity(0.35),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Tip: Detect store location once, then set radius and Save.',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Expanded(
          child: FutureBuilder<List<OrderRecord>>(
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
                          size: 34,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Failed to load orders',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: Colors.white),
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
              final incoming = orders.where((order) {
                return order.status == 'new' ||
                    order.status == 'accepted' ||
                    order.status == 'preparing';
              }).toList();
              final history = orders.where((order) {
                return order.status == 'out_for_delivery' ||
                    order.status == 'delivered' ||
                    order.status == 'cancelled';
              }).toList();

              if (incoming.isEmpty && history.isEmpty) {
                return Center(
                  child: Text(
                    'No incoming orders yet.',
                    style: TextStyle(color: Colors.grey[300], fontSize: 16),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      children: [
                        _buildViewButton(
                          label: 'Incoming',
                          active: _selectedView == _OrderListView.incoming,
                          onTap: () {
                            setState(
                              () => _selectedView = _OrderListView.incoming,
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildViewButton(
                          label: 'History',
                          active: _selectedView == _OrderListView.history,
                          onTap: () {
                            setState(
                              () => _selectedView = _OrderListView.history,
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_selectedView == _OrderListView.incoming) ...[
                      Text(
                        'Incoming Orders',
                        style: TextStyle(
                          color: Colors.grey[200],
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (incoming.isEmpty)
                        _buildEmptySection('No active incoming orders.'),
                      ...incoming.map(
                        (order) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildOrderCard(order),
                        ),
                      ),
                    ] else ...[
                      Text(
                        'History',
                        style: TextStyle(
                          color: Colors.grey[200],
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (history.isEmpty)
                        _buildEmptySection('No order history yet.'),
                      ...history.map(
                        (order) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildOrderCard(order),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    TextInputType inputType,
  ) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.black,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: goldYellow.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: goldYellow),
        ),
      ),
    );
  }

  Widget _buildEmptySection(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF222222),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: goldYellow.withOpacity(0.18)),
      ),
      child: Text(text, style: TextStyle(color: Colors.grey[300])),
    );
  }

  Widget _buildOrderCard(OrderRecord order) {
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
                  _labelForStatus(order.status).toUpperCase(),
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
          Text(
            'Customer: ${order.customerName}',
            style: TextStyle(color: Colors.grey[200]),
          ),
          Text(
            'Phone: ${order.phone}',
            style: TextStyle(color: Colors.grey[200]),
          ),
          Text(
            'Address: ${order.address}',
            style: TextStyle(color: Colors.grey[300]),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Items: ${order.itemCount}',
                style: TextStyle(
                  color: Colors.grey[300],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Total: Rs ${order.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: goldYellow,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Placed: ${order.createdAt.toLocal()}',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
          if (_nextStatus(order.status) != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => _moveOrderToNextStage(order),
                icon: const Icon(Icons.chevron_right),
                label: Text(_nextActionLabel(order.status)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: goldYellow,
                  foregroundColor: Colors.black,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildViewButton({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: active ? goldYellow : const Color(0xFF222222),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: active ? Colors.black : Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _OrderListView { incoming, history }
