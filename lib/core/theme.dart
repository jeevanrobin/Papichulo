import 'package:flutter/material.dart';

class AppTheme {
  static const Color goldYellow = Color(0xFFFFD700);
  static const Color darkGold = Color(0xFFB8860B);
  static const Color black = Color(0xFF000000);
  static const Color darkGrey = Color(0xFF1A1A1A);

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF0A0A0A),
      colorScheme: ColorScheme.fromSeed(
        seedColor: goldYellow,
        brightness: Brightness.dark,
        primary: goldYellow,
        secondary: darkGold,
        surface: const Color(0xFF161616),
        onSurface: Colors.white,
      ),
      fontFamily: 'Segoe UI',
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF0A0A0A),
        foregroundColor: goldYellow,
        centerTitle: true,
        elevation: 0,
      ),
      textTheme: TextTheme(
        displayLarge: const TextStyle(
          fontSize: 56,
          fontWeight: FontWeight.w900,
          height: 1.0,
          letterSpacing: -1.5,
        ),
        displayMedium: const TextStyle(
          fontSize: 42,
          fontWeight: FontWeight.w900,
          height: 1.1,
          letterSpacing: -1,
        ),
        headlineLarge: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          height: 1.2,
          letterSpacing: -0.5,
        ),
        headlineMedium: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          height: 1.2,
          letterSpacing: -0.3,
        ),
        headlineSmall: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          height: 1.3,
        ),
        titleLarge: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
        titleMedium: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
        bodyLarge: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1.5,
        ),
        bodyMedium: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        bodySmall: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 1.4,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFD84D),
          foregroundColor: black,
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
