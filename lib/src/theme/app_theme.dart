import 'package:flutter/material.dart';

class AppTheme {
  static const Color _ink = Color(0xFF1F2933);
  static const Color _paper = Color(0xFFF7F3EA);
  static const Color _sage = Color(0xFF5F7A61);
  static const Color _clay = Color(0xFFC97A51);
  static const Color _mist = Color(0xFFE8E2D4);

  static ThemeData lightTheme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _sage,
      brightness: Brightness.light,
      surface: _paper,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme.copyWith(
        primary: _sage,
        secondary: _clay,
        surface: _paper,
        onSurface: _ink,
      ),
      scaffoldBackgroundColor: const Color(0xFFF1ECE2),
      textTheme: Typography.material2021().black.apply(
            bodyColor: _ink,
            displayColor: _ink,
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: _ink,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: _paper,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: _mist),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        selectedColor: _sage.withValues(alpha: 0.18),
        backgroundColor: Colors.white.withValues(alpha: 0.72),
        side: const BorderSide(color: _mist),
        labelStyle: const TextStyle(color: _ink),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.86),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _ink,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  static ThemeData darkTheme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _sage,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF14181B),
      textTheme: Typography.material2021().white,
    );
  }
}
