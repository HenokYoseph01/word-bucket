import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wordbucket/core/theme.dart';

void main() {
  test('every palette provides the shared floating snackbar style', () {
    for (final palette in AppPalette.values) {
      for (final theme in [
        buildWordBucketTheme(palette: palette),
        buildWordBucketDarkTheme(palette: palette),
      ]) {
        final snackBar = theme.snackBarTheme;

        expect(snackBar.behavior, SnackBarBehavior.floating);
        expect(snackBar.backgroundColor, isNotNull);
        expect(snackBar.contentTextStyle?.color, theme.colorScheme.onSurface);
        expect(snackBar.shape, isA<RoundedRectangleBorder>());
      }
    }
  });
}
