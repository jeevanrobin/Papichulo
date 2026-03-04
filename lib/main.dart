import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'firebase_options.dart';
import 'providers/cart_provider.dart';
import 'providers/theme_provider.dart';
import 'router/app_router.dart';
import 'services/auth_service.dart';
import 'services/address_service.dart';
import 'services/cart_service.dart';
import 'services/favourites_service.dart';
import 'widgets/error_boundary_screen.dart';
import 'widgets/offline_banner.dart';

void main() async {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exception}');
  };

  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      FavouritesService.instance.load();
      AddressService.instance.loadAddresses();
      runApp(const PapichuloApp());
    },
    (error, stack) {
      debugPrint('Unhandled error: $error\n$stack');
    },
  );
}

class PapichuloApp extends StatelessWidget {
  const PapichuloApp({super.key});

  @override
  Widget build(BuildContext context) {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return ErrorBoundaryScreen(errorDetails: details);
    };

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
        ChangeNotifierProvider<FavouritesService>.value(
          value: FavouritesService.instance,
        ),
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return OfflineBanner(
            child: MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeProvider.mode,
              routerConfig: AppRouter.router,
            ),
          );
        },
      ),
    );
  }
}
