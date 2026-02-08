import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'providers/cart_provider.dart';
import 'services/cart_service.dart';
import 'screens/splash/splash_screen.dart';

void main() {
  runApp(const PapichuloApp());
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
