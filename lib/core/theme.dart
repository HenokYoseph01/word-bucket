import 'package:flutter/material.dart';

enum AppPalette {
  classicInk,
  forestJournal,
  sepiaLibrary,
  plumNotebook,
  midnightBlue,
  monochromePaper,
}

extension AppPaletteDetails on AppPalette {
  String get label => switch (this) {
    AppPalette.classicInk => 'Classic Ink',
    AppPalette.forestJournal => 'Forest Journal',
    AppPalette.sepiaLibrary => 'Sepia Library',
    AppPalette.plumNotebook => 'Plum Notebook',
    AppPalette.midnightBlue => 'Midnight Blue',
    AppPalette.monochromePaper => 'Monochrome Paper',
  };

  Color get seed => switch (this) {
    AppPalette.classicInk => const Color(0xFF203A43),
    AppPalette.forestJournal => const Color(0xFF315B45),
    AppPalette.sepiaLibrary => const Color(0xFF6B4932),
    AppPalette.plumNotebook => const Color(0xFF65445F),
    AppPalette.midnightBlue => const Color(0xFF354B6B),
    AppPalette.monochromePaper => const Color(0xFF111111),
  };

  Color get accent => switch (this) {
    AppPalette.classicInk => const Color(0xFFF4C95D),
    AppPalette.forestJournal => const Color(0xFFC79A45),
    AppPalette.sepiaLibrary => const Color(0xFFB7793F),
    AppPalette.plumNotebook => const Color(0xFFD09A5B),
    AppPalette.midnightBlue => const Color(0xFF8FAED1),
    AppPalette.monochromePaper => const Color(0xFF777777),
  };

  Color get lightPaper => switch (this) {
    AppPalette.classicInk => const Color(0xFFFFFBF3),
    AppPalette.forestJournal => const Color(0xFFFBF8ED),
    AppPalette.sepiaLibrary => const Color(0xFFFFF5DF),
    AppPalette.plumNotebook => const Color(0xFFFFF7FA),
    AppPalette.midnightBlue => const Color(0xFFF6F8FC),
    AppPalette.monochromePaper => const Color(0xFFFFFFFF),
  };

  Color get darkPaper => switch (this) {
    AppPalette.classicInk => const Color(0xFF111A1D),
    AppPalette.forestJournal => const Color(0xFF121C17),
    AppPalette.sepiaLibrary => const Color(0xFF211813),
    AppPalette.plumNotebook => const Color(0xFF20171F),
    AppPalette.midnightBlue => const Color(0xFF111821),
    AppPalette.monochromePaper => const Color(0xFF000000),
  };
}

ThemeData buildWordBucketTheme({AppPalette palette = AppPalette.classicInk}) {
  return _buildTheme(Brightness.light, palette);
}

ThemeData buildWordBucketDarkTheme({
  AppPalette palette = AppPalette.classicInk,
}) {
  return _buildTheme(Brightness.dark, palette);
}

ThemeData _buildTheme(Brightness brightness, AppPalette palette) {
  final dark = brightness == Brightness.dark;
  final paper = dark ? palette.darkPaper : palette.lightPaper;
  final baseScheme = ColorScheme.fromSeed(
    seedColor: palette.seed,
    brightness: brightness,
    surface: paper,
    dynamicSchemeVariant: palette == AppPalette.monochromePaper
        ? DynamicSchemeVariant.monochrome
        : DynamicSchemeVariant.tonalSpot,
  );
  final scheme = baseScheme.copyWith(
    tertiary: palette.accent,
    onTertiary:
        ThemeData.estimateBrightnessForColor(palette.accent) == Brightness.dark
        ? Colors.white
        : Colors.black,
    tertiaryContainer: Color.alphaBlend(
      palette.accent.withValues(alpha: dark ? 0.28 : 0.24),
      paper,
    ),
    onTertiaryContainer: baseScheme.onSurface,
  );
  final raisedSurface = Color.alphaBlend(
    dark
        ? scheme.primary.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.72),
    paper,
  );

  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: paper,
    fontFamily: 'sans-serif',
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: raisedSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: raisedSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Color.alphaBlend(
        scheme.primary.withValues(alpha: dark ? 0.06 : 0.025),
        paper,
      ),
      indicatorColor: scheme.primaryContainer,
      elevation: 0,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: paper,
      surfaceTintColor: Colors.transparent,
    ),
  );
}
