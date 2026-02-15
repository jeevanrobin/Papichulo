import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'providers/cart_provider.dart';
import 'router/app_router.dart';
import 'services/auth_service.dart';
import 'services/cart_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PapichuloApp());
}

class PapichuloApp extends StatelessWidget {
  const PapichuloApp({super.key});

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
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
