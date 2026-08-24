import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
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

  const previewRequested = bool.fromEnvironment('DEVICE_PREVIEW');
  runApp(
    DevicePreview(
      enabled: !kReleaseMode && previewRequested,
      builder: (_) => ProviderScope(
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
    ),
  );
}
