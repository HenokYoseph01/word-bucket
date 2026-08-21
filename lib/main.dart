import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'background/review_worker.dart';
import 'providers/theme_provider.dart';

Future<void> main(List<String> arguments) async {
  WidgetsFlutterBinding.ensureInitialized();
  final bucketifyMode = arguments.contains('bucketify');
  final startupTheme = await loadStartupTheme();
  if (!bucketifyMode) {
    await initializeReviewWork();
  }

  runApp(
    ProviderScope(
      overrides: [
        themeModeProvider.overrideWith(
          (ref) =>
              ThemeModeNotifier(initialMode: startupTheme.mode, load: false),
        ),
        themePaletteProvider.overrideWith(
          (ref) => ThemePaletteNotifier(
            initialPalette: startupTheme.palette,
            load: false,
          ),
        ),
      ],
      child: WordBucketApp(bucketifyMode: bucketifyMode),
    ),
  );
}
