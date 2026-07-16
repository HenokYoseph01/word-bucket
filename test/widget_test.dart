import 'package:flutter_test/flutter_test.dart';
import 'package:wordbucket/app.dart';

void main() {
  testWidgets('shows the dictionary lookup form', (tester) async {
    await tester.pumpWidget(const WordBucketApp());

    expect(find.text('WordBucket'), findsOneWidget);
    expect(find.text('0 words'), findsOneWidget);
    expect(find.text('Look up a word'), findsOneWidget);
    expect(
      find.text('Enter a word above to fetch its definition.'),
      findsOneWidget,
    );
  });
}
