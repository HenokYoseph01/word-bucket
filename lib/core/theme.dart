import 'package:flutter/material.dart';

ThemeData buildWordBucketTheme() {
  const seedColor = Color(0xFF3566D6);

  return ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFF8F9FD),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    ),
  );
}
