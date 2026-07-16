import 'package:flutter_test/flutter_test.dart';
import 'package:wordbucket/app.dart';

void main() {
  testWidgets('shows the empty bucket screen', (tester) async {
    await tester.pumpWidget(const WordBucketApp());

    expect(find.text('WordBucket'), findsOneWidget);
    expect(find.text('0 words'), findsOneWidget);
    expect(find.text('Your bucket is empty'), findsOneWidget);
  });
}
