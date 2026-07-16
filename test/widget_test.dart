import 'package:flutter_test/flutter_test.dart';
import 'package:wordbucket/app.dart';

void main() {
  testWidgets('shows a word from the bucket', (tester) async {
    await tester.pumpWidget(const WordBucketApp());

    expect(find.text('WordBucket'), findsOneWidget);
    expect(find.text('1 word'), findsOneWidget);
    expect(find.text('ephemeral'), findsOneWidget);
    expect(find.text('adjective'), findsOneWidget);
    expect(find.text('Lasting for a very short time.'), findsOneWidget);
  });
}
