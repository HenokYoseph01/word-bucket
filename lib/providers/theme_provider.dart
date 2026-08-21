import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import '../core/theme.dart';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier({
    ThemeMode initialMode = ThemeMode.system,
    bool load = true,
  }) : super(initialMode) {
    if (load) _load();
  }

  Future<void> _load() async {
    final saved = await SharedPreferencesAsync().getString(themeModeKey);
    state = ThemeMode.values.firstWhere(
      (mode) => mode.name == saved,
      orElse: () => ThemeMode.system,
    );
    await _syncWidgetAppearance(themeMode: state.name);
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await SharedPreferencesAsync().setString(themeModeKey, mode.name);
    await _syncWidgetAppearance(themeMode: mode.name);
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((
  ref,
) {
  return ThemeModeNotifier();
});

class ThemePaletteNotifier extends StateNotifier<AppPalette> {
  ThemePaletteNotifier({
    AppPalette initialPalette = AppPalette.classicInk,
    bool load = true,
  }) : super(initialPalette) {
    if (load) _load();
  }

  Future<void> _load() async {
    final saved = await SharedPreferencesAsync().getString(themePaletteKey);
    state = AppPalette.values.firstWhere(
      (palette) => palette.name == saved,
      orElse: () => AppPalette.classicInk,
    );
    await _syncWidgetAppearance(themePalette: state.name);
  }

  Future<void> setPalette(AppPalette palette) async {
    state = palette;
    await SharedPreferencesAsync().setString(themePaletteKey, palette.name);
    await _syncWidgetAppearance(themePalette: palette.name);
  }
}

final themePaletteProvider =
    StateNotifierProvider<ThemePaletteNotifier, AppPalette>((ref) {
      return ThemePaletteNotifier();
    });

class StartupTheme {
  const StartupTheme({required this.mode, required this.palette});

  final ThemeMode mode;
  final AppPalette palette;
}

Future<StartupTheme> loadStartupTheme() async {
  try {
    final preferences = SharedPreferencesAsync();
    final values = await Future.wait<String?>([
      preferences.getString(themeModeKey),
      preferences.getString(themePaletteKey),
    ]);
    return StartupTheme(
      mode: ThemeMode.values.firstWhere(
        (mode) => mode.name == values[0],
        orElse: () => ThemeMode.system,
      ),
      palette: AppPalette.values.firstWhere(
        (palette) => palette.name == values[1],
        orElse: () => AppPalette.classicInk,
      ),
    );
  } on Exception {
    return const StartupTheme(
      mode: ThemeMode.system,
      palette: AppPalette.classicInk,
    );
  }
}

Future<void> _syncWidgetAppearance({
  String? themeMode,
  String? themePalette,
}) async {
  if (themeMode != null) {
    await HomeWidget.saveWidgetData<String>('themeMode', themeMode);
  }
  if (themePalette != null) {
    await HomeWidget.saveWidgetData<String>('themePalette', themePalette);
  }
  await HomeWidget.updateWidget(
    qualifiedAndroidName: 'com.elst.wordbucket.WordWidgetProvider',
  );
}
