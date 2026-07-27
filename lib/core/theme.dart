import 'package:flutter/material.dart';

ThemeData buildWordBucketTheme() {
  const ink = Color(0xFF203A43);
  const paper = Color(0xFFFFFBF3);

  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: ink,
      brightness: Brightness.light,
      surface: paper,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: paper,
    fontFamily: 'sans-serif',
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white.withValues(alpha: 0.78),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFEAE2D4)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE2D9CA)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE2D9CA)),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Color(0xFFFFFDF8),
      indicatorColor: Color(0xFFDCE8E3),
      elevation: 0,
    ),
  );
}
