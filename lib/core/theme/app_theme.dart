import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const _seedColor = Color(0xFF5E35B1);

  // ---------------- LIGHT ----------------
  static final light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFF5F5F7),

    cardTheme: CardThemeData(
      elevation: 3,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),

    appBarTheme: const AppBarTheme(elevation: 0, centerTitle: false),

    // ❗ Do NOT override floatingActionButtonTheme
  );

  // ---------------- DARK ----------------
  static final dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    ),

    scaffoldBackgroundColor: const Color(0xFF0F0F14),

    cardTheme: CardThemeData(
      elevation: 3,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),

    appBarTheme: const AppBarTheme(elevation: 0, centerTitle: false),
  );
}
