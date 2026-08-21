import 'package:flutter/material.dart';

enum AppPalette {
  classicInk,
  forestJournal,
  sepiaLibrary,
  plumNotebook,
  midnightBlue,
  monochromePaper,
  rosePetal,
  matchaHoney,
  cherryInk,
  lilacEvening,
  pressedFlowers,
  moonlitLagoon,
}

extension AppPaletteDetails on AppPalette {
  String get label => switch (this) {
    AppPalette.classicInk => 'Classic Ink',
    AppPalette.forestJournal => 'Forest Journal',
    AppPalette.sepiaLibrary => 'Sepia Library',
    AppPalette.plumNotebook => 'Plum Notebook',
    AppPalette.midnightBlue => 'Midnight Blue',
    AppPalette.monochromePaper => 'Monochrome Paper',
    AppPalette.rosePetal => 'Rose Petal',
    AppPalette.matchaHoney => 'Matcha & Honey',
    AppPalette.lilacEvening => 'Lilac Evening',
    AppPalette.cherryInk => 'Cherry Ink',
    AppPalette.pressedFlowers => 'Pressed Flowers',
    AppPalette.moonlitLagoon => 'Moonlit Lagoon',
  };

  Color get seed => switch (this) {
    AppPalette.classicInk => const Color(0xFF203A43),
    AppPalette.forestJournal => const Color(0xFF315B45),
    AppPalette.sepiaLibrary => const Color(0xFF6B4932),
    AppPalette.plumNotebook => const Color(0xFF65445F),
    AppPalette.midnightBlue => const Color(0xFF354B6B),
    AppPalette.monochromePaper => const Color(0xFF111111),
    AppPalette.rosePetal => const Color(0xFFA75A7A),
    AppPalette.matchaHoney => const Color(0xFF9CA764),
    AppPalette.lilacEvening => const Color(0xFF4D3E6B),
    AppPalette.cherryInk => const Color(0xFF8F2040),
    AppPalette.pressedFlowers => const Color(0xFF473469),
    AppPalette.moonlitLagoon => const Color(0xFF294380),
  };

  Color get accent => switch (this) {
    AppPalette.classicInk => const Color(0xFFF4C95D),
    AppPalette.forestJournal => const Color(0xFFC79A45),
    AppPalette.sepiaLibrary => const Color(0xFFB7793F),
    AppPalette.plumNotebook => const Color(0xFFD09A5B),
    AppPalette.midnightBlue => const Color(0xFF8FAED1),
    AppPalette.monochromePaper => const Color(0xFF777777),
    AppPalette.rosePetal => const Color(0xFFE7A5B8),
    AppPalette.matchaHoney => const Color(0xFFF1E8C7),
    AppPalette.lilacEvening => const Color(0xFF8DAEC3),
    AppPalette.cherryInk => const Color(0xFFD78391),
    AppPalette.pressedFlowers => const Color(0xFFF79EB1),
    AppPalette.moonlitLagoon => const Color(0xFF69D2CD),
  };

  Color get lightPaper => switch (this) {
    AppPalette.classicInk => const Color(0xFFFFFBF3),
    AppPalette.forestJournal => const Color(0xFFFBF8ED),
    AppPalette.sepiaLibrary => const Color(0xFFFFF5DF),
    AppPalette.plumNotebook => const Color(0xFFFFF7FA),
    AppPalette.midnightBlue => const Color(0xFFF6F8FC),
    AppPalette.monochromePaper => const Color(0xFFFFFFFF),
    AppPalette.rosePetal => const Color(0xFFFFF5F8),
    AppPalette.matchaHoney => const Color(0xFFFCFAEF),
    AppPalette.lilacEvening => const Color(0xFFFCFCE2),
    AppPalette.cherryInk => const Color(0xFFFFF8F3),
    AppPalette.pressedFlowers => const Color(0xFFF2E7D2),
    AppPalette.moonlitLagoon => const Color(0xFFF1F6CE),
  };

  Color get darkPaper => switch (this) {
    AppPalette.classicInk => const Color(0xFF111A1D),
    AppPalette.forestJournal => const Color(0xFF121C17),
    AppPalette.sepiaLibrary => const Color(0xFF211813),
    AppPalette.plumNotebook => const Color(0xFF20171F),
    AppPalette.midnightBlue => const Color(0xFF111821),
    AppPalette.monochromePaper => const Color(0xFF000000),
    AppPalette.rosePetal => const Color(0xFF21151B),
    AppPalette.matchaHoney => const Color(0xFF1B1D13),
    AppPalette.lilacEvening => const Color(0xFF211A2B),
    AppPalette.cherryInk => const Color(0xFF211218),
    AppPalette.pressedFlowers => const Color(0xFF1E1725),
    AppPalette.moonlitLagoon => const Color(0xFF0D0F36),
  };

  List<Color> get previewColors => switch (this) {
    AppPalette.classicInk => const [
      Color(0xFFFFFBF3),
      Color(0xFF203A43),
      Color(0xFFF4C95D),
    ],
    AppPalette.forestJournal => const [
      Color(0xFFFBF8ED),
      Color(0xFF315B45),
      Color(0xFFC79A45),
    ],
    AppPalette.sepiaLibrary => const [
      Color(0xFFFFF5DF),
      Color(0xFF6B4932),
      Color(0xFFB7793F),
    ],
    AppPalette.plumNotebook => const [
      Color(0xFFFFF7FA),
      Color(0xFF65445F),
      Color(0xFFD09A5B),
    ],
    AppPalette.midnightBlue => const [
      Color(0xFFF6F8FC),
      Color(0xFF354B6B),
      Color(0xFF8FAED1),
    ],
    AppPalette.monochromePaper => const [
      Color(0xFFFFFFFF),
      Color(0xFF111111),
      Color(0xFF777777),
    ],
    AppPalette.rosePetal => const [
      Color(0xFFFFF5F8),
      Color(0xFFA75A7A),
      Color(0xFFE7A5B8),
    ],
    AppPalette.matchaHoney => const [
      Color(0xFFF1E8C7),
      Color(0xFF9CA764),
      Color(0xFFFCFAEF),
    ],
    AppPalette.lilacEvening => const [
      Color(0xFF81749C),
      Color(0xFF4D3E6B),
      Color(0xFF8DAEC3),
      Color(0xFFC5DFE0),
      Color(0xFFFCFCE2),
    ],
    AppPalette.cherryInk => const [
      Color(0xFFFFF8F3),
      Color(0xFFF0CDD2),
      Color(0xFFD78391),
      Color(0xFF8F2040),
      Color(0xFF211218),
    ],
    AppPalette.pressedFlowers => const [
      Color(0xFFF2E7D2),
      Color(0xFFF79EB1),
      Color(0xFFAE8FBA),
      Color(0xFF4C5E91),
      Color(0xFF473469),
    ],
    AppPalette.moonlitLagoon => const [
      Color(0xFF0D0F36),
      Color(0xFF294380),
      Color(0xFF69D2CD),
      Color(0xFFB9F1D6),
      Color(0xFFF1F6CE),
    ],
  };

  String get collectionLabel => switch (this) {
    AppPalette.lilacEvening ||
    AppPalette.pressedFlowers ||
    AppPalette.moonlitLagoon => 'Robi Pack',
    _ => 'WordBucket Original',
  };

  bool get isRobiPack => collectionLabel == 'Robi Pack';
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
  final monochrome = palette == AppPalette.monochromePaper;
  final paper = dark ? palette.darkPaper : palette.lightPaper;
  final baseScheme = ColorScheme.fromSeed(
    seedColor: palette.seed,
    brightness: brightness,
    surface: paper,
    dynamicSchemeVariant: monochrome
        ? DynamicSchemeVariant.monochrome
        : DynamicSchemeVariant.tonalSpot,
  );
  var scheme = baseScheme.copyWith(
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
  if (monochrome) {
    scheme = scheme.copyWith(
      primary: dark ? Colors.white : Colors.black,
      onPrimary: dark ? Colors.black : Colors.white,
      primaryContainer: dark
          ? const Color(0xFF2E2E2E)
          : const Color(0xFFE2E2E2),
      onPrimaryContainer: dark ? Colors.white : Colors.black,
      secondary: dark ? const Color(0xFFD0D0D0) : const Color(0xFF333333),
      onSecondary: dark ? Colors.black : Colors.white,
      secondaryContainer: dark
          ? const Color(0xFF333333)
          : const Color(0xFFE2E2E2),
      onSecondaryContainer: dark ? Colors.white : const Color(0xFF111111),
    );
  }
  if (palette == AppPalette.cherryInk) {
    scheme = scheme.copyWith(
      primary: dark ? const Color(0xFFE68A9A) : const Color(0xFF8F2040),
      onPrimary: dark ? const Color(0xFF351018) : Colors.white,
      primaryContainer: dark
          ? const Color(0xFF5A1D30)
          : const Color(0xFFF4D6DB),
      onPrimaryContainer: dark
          ? const Color(0xFFFFD9DF)
          : const Color(0xFF5C1028),
      secondary: dark ? const Color(0xFFD3A4AB) : const Color(0xFF76565D),
      onSecondary: dark ? const Color(0xFF2D151A) : Colors.white,
      tertiary: dark ? const Color(0xFFD78391) : const Color(0xFFB6435F),
      onTertiary: dark ? const Color(0xFF351018) : Colors.white,
      tertiaryContainer: dark
          ? const Color(0xFF4B2631)
          : const Color(0xFFF0CDD2),
      onTertiaryContainer: dark
          ? const Color(0xFFFFD9DF)
          : const Color(0xFF541125),
    );
  }
  final raisedSurface = Color.alphaBlend(
    dark
        ? scheme.primary.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.72),
    paper,
  );
  final snackBarSurface = Color.alphaBlend(
    scheme.primary.withValues(alpha: dark ? 0.16 : 0.08),
    raisedSurface,
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
      indicatorColor: monochrome ? scheme.primary : scheme.primaryContainer,
      iconTheme: monochrome
          ? WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return IconThemeData(
                color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
              );
            })
          : null,
      labelTextStyle: monochrome
          ? WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return TextStyle(
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              );
            })
          : null,
      elevation: 0,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: paper,
      surfaceTintColor: Colors.transparent,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: snackBarSurface,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: scheme.primary.withValues(alpha: dark ? 0.55 : 0.38),
        ),
      ),
      insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      contentTextStyle: TextStyle(
        color: scheme.onSurface,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.35,
      ),
      actionTextColor: scheme.primary,
      disabledActionTextColor: scheme.onSurfaceVariant,
    ),
  );
}
