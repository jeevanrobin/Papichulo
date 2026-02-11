import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'models/order_record.dart';
import 'providers/cart_provider.dart';
import 'screens/admin/orders_admin_screen.dart';
import 'services/api_config.dart';
import 'services/auth_service.dart';
import 'services/cart_service.dart';
import 'services/analytics_service.dart';
import 'services/order_alert_service.dart';
import 'services/order_api_service.dart';
import 'screens/splash/splash_screen.dart';
import 'widgets/error_fallback_widget.dart';

void main() {
  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        AnalyticsService().track(
          'app_error',
          params: {
            'exception': details.exceptionAsString(),
            'library': details.library ?? 'unknown',
          },
        );
      };

      ErrorWidget.builder = (FlutterErrorDetails details) {
        AnalyticsService().track(
          'render_error',
          params: {'exception': details.exceptionAsString()},
        );
        return const ErrorFallbackWidget();
      };

      runApp(const PapichuloApp());
    },
    (error, stack) {
      AnalyticsService().track(
        'zone_error',
        params: {'error': error.toString()},
      );
    },
  );
}

class PapichuloApp extends StatelessWidget {
  const PapichuloApp({super.key});
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<CartService>(create: (_) => CartService()),
        ChangeNotifierProvider<AuthService>(
          create: (_) => AuthService()..bootstrap(),
        ),
        ChangeNotifierProxyProvider<CartService, CartProvider>(
          create: (context) =>
              CartProvider(cartService: context.read<CartService>()),
          update: (_, cartService, cartProvider) =>
              cartProvider ?? CartProvider(cartService: cartService),
        ),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        builder: (context, child) => _GlobalOrderAlertLayer(
          navigatorKey: navigatorKey,
          child: child ?? const SizedBox.shrink(),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}

class _GlobalOrderAlertLayer extends StatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  const _GlobalOrderAlertLayer({
    required this.child,
    required this.navigatorKey,
  });

  @override
  State<_GlobalOrderAlertLayer> createState() => _GlobalOrderAlertLayerState();
}

class _GlobalOrderAlertLayerState extends State<_GlobalOrderAlertLayer>
    with SingleTickerProviderStateMixin {
  static const Color goldYellow = Color(0xFFFFD700);
  final OrderAlertService _alerts = OrderAlertService.instance;
  final OrderApiService _api = OrderApiService();
  StreamSubscription<OrderRecord>? _subscription;
  final List<OrderRecord> _queue = <OrderRecord>[];
  OrderRecord? _activeOrder;
  bool _updating = false;
  late final VoidCallback _authListener;
  late final AnimationController _fxController;
  late final Animation<double> _scalePulse;
  late final Animation<double> _glowPulse;
  late final Animation<double> _bellWiggle;

  @override
  void initState() {
    super.initState();
    _fxController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _scalePulse = Tween<double>(
      begin: 0.985,
      end: 1.015,
    ).animate(CurvedAnimation(parent: _fxController, curve: Curves.easeInOut));
    _glowPulse = Tween<double>(
      begin: 0.22,
      end: 0.5,
    ).animate(CurvedAnimation(parent: _fxController, curve: Curves.easeInOut));
    _bellWiggle = Tween<double>(
      begin: -0.18,
      end: 0.18,
    ).animate(CurvedAnimation(parent: _fxController, curve: Curves.easeInOut));
    _authListener = _syncAlertPolling;
    AuthService.instance.addListener(_authListener);
    _syncAlertPolling();
    _subscription = _alerts.newOrderStream.listen(_onIncomingOrder);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    AuthService.instance.removeListener(_authListener);
    _alerts.stop();
    _fxController.dispose();
    super.dispose();
  }

  void _syncAlertPolling() {
    final canPollAdminOrders =
        AuthService.instance.isAdmin || ApiConfig.adminKey.isNotEmpty;
    if (canPollAdminOrders) {
      _alerts.start();
    } else {
      _alerts.stop();
      pendingCleanup();
    }
  }

  void pendingCleanup() {
    _queue.clear();
    _activeOrder = null;
    _stopAlertFx();
  }

  void _onIncomingOrder(OrderRecord order) {
    if (_activeOrder?.id == order.id || _queue.any((o) => o.id == order.id)) {
      return;
    }
    setState(() {
      if (_activeOrder == null) {
        _activeOrder = order;
        _startAlertFx();
      } else {
        _queue.add(order);
      }
    });
    _playAlertSound();
  }

  void _showNextAlert() {
    if (_queue.isNotEmpty) {
      setState(() {
        _activeOrder = _queue.removeAt(0);
      });
      _startAlertFx();
      _playAlertSound();
    } else {
      setState(() => _activeOrder = null);
      _stopAlertFx();
    }
  }

  void _startAlertFx() {
    if (!_fxController.isAnimating) {
      _fxController.repeat(reverse: true);
    }
  }

  void _stopAlertFx() {
    if (_fxController.isAnimating) {
      _fxController.stop();
      _fxController.reset();
    }
  }

  Future<void> _playAlertSound() async {
    try {
      await SystemSound.play(SystemSoundType.alert);
      await Future.delayed(const Duration(milliseconds: 180));
      await SystemSound.play(SystemSoundType.alert);
    } catch (_) {
      // Some web/mobile environments can block auto-play sound.
    }
  }

  Future<void> _updateOrderStatus(String status) async {
    final order = _activeOrder;
    if (order == null || _updating) return;

    setState(() => _updating = true);
    try {
      await _api.updateOrderStatus(orderId: order.id, status: status);
      _alerts.markOrderHandled(order.id);
      await _alerts.refreshNow(silent: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'accepted'
                ? 'Order ${order.id} accepted.'
                : 'Order ${order.id} declined.',
          ),
          backgroundColor: status == 'accepted'
              ? Colors.green
              : Colors.redAccent,
        ),
      );
      _showNextAlert();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update order: $error'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _updating = false);
      }
    }
  }

  void _openOrders() {
    final canOpen =
        AuthService.instance.isAdmin || ApiConfig.adminKey.isNotEmpty;
    if (!canOpen) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Admin access required to open orders.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    _showNextAlert();
    widget.navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const OrdersAdminScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned(
          right: 16,
          bottom: 16,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              final slide =
                  Tween<Offset>(
                    begin: const Offset(0.18, 0.18),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  );
              final scale = Tween<double>(begin: 0.94, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
              );
              return SlideTransition(
                position: slide,
                child: FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: scale, child: child),
                ),
              );
            },
            child: _activeOrder == null
                ? const SizedBox.shrink()
                : _buildAlertCard(_activeOrder!),
          ),
        ),
      ],
    );
  }

  Widget _buildAlertCard(OrderRecord order) {
    return AnimatedBuilder(
      animation: _fxController,
      builder: (context, _) {
        return Transform.scale(
          scale: _activeOrder == null ? 1.0 : _scalePulse.value,
          child: Material(
            key: ValueKey(order.id),
            color: Colors.transparent,
            child: Container(
              width: 360,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF222222),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: goldYellow.withValues(alpha: _glowPulse.value),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: goldYellow.withValues(
                      alpha: (_glowPulse.value * 0.45).clamp(0.0, 1.0),
                    ),
                    blurRadius: 24,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Transform.rotate(
                        angle: _activeOrder == null ? 0 : _bellWiggle.value,
                        child: const Icon(
                          Icons.notifications_active,
                          color: goldYellow,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'New Order Received',
                          style: TextStyle(
                            color: goldYellow,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: _showNextAlert,
                        borderRadius: BorderRadius.circular(999),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.close,
                            color: Colors.grey,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Order ${order.id}',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  Text(
                    'Customer: ${order.customerName}',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  Text(
                    'Total: Rs ${order.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      TextButton(
                        onPressed: _updating
                            ? null
                            : () => _updateOrderStatus('cancelled'),
                        child: const Text(
                          'Decline',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _updating
                            ? null
                            : () => _updateOrderStatus('accepted'),
                        child: const Text(
                          'Accept',
                          style: TextStyle(
                            color: Color(0xFF7FFFD4),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _openOrders,
                        child: const Text(
                          'Open Orders',
                          style: TextStyle(
                            color: goldYellow,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
