import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'providers/cart_provider.dart';
import 'services/cart_service.dart';
import 'services/analytics_service.dart';
import 'screens/splash/splash_screen.dart';
import 'widgets/error_fallback_widget.dart';

void main() {
  runZonedGuarded(() {
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
        params: {
          'exception': details.exceptionAsString(),
        },
      );
      return const ErrorFallbackWidget();
    };

    runApp(const PapichuloApp());
  }, (error, stack) {
    AnalyticsService().track(
      'zone_error',
      params: {
        'error': error.toString(),
      },
    );
  });
}

class PapichuloApp extends StatelessWidget {
  const PapichuloApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<CartService>(create: (_) => CartService()),
        ChangeNotifierProxyProvider<CartService, CartProvider>(
          create: (_) => CartProvider(),
          update: (_, cartService, cartProvider) => CartProvider(cartService: cartService),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const SplashScreen(),
      ),
    );
  }
}
