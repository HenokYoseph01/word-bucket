import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wordbucket/ui/widgets/responsive_segmented_control.dart';

void main() {
  testWidgets('appearance labels lay out on a compact screen', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ResponsiveSegmentedControl<ThemeMode>(
                segments: const [
                  ResponsiveSegment(
                    value: ThemeMode.system,
                    icon: Icons.brightness_auto_rounded,
                    label: 'System',
                  ),
                  ResponsiveSegment(
                    value: ThemeMode.light,
                    icon: Icons.light_mode_outlined,
                    label: 'Light',
                  ),
                  ResponsiveSegment(
                    value: ThemeMode.dark,
                    icon: Icons.dark_mode_outlined,
                    label: 'Dark',
                  ),
                ],
                selected: ThemeMode.system,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('System'), findsOneWidget);
  });
}
