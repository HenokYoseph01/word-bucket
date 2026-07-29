import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import '../core/theme.dart';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _load();
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
  ThemePaletteNotifier() : super(AppPalette.classicInk) {
    _load();
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
