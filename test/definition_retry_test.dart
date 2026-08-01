import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wordbucket/data/database/database.dart';
import 'package:wordbucket/data/models/word_model.dart';
import 'package:wordbucket/data/services/dictionary_service.dart';
import 'package:wordbucket/data/services/home_widget_service.dart';
import 'package:wordbucket/providers/word_provider.dart';

void main() {
  test('retries one temporary dictionary failure and then succeeds', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final dictionary = _FakeDictionaryService([
      const DictionaryException(
        'Temporary failure',
        kind: DictionaryFailure.temporary,
      ),
      WordModel(
        word: 'luminous',
        partOfSpeech: 'adjective',
        definition: 'Giving off light.',
        savedAt: DateTime(2026, 8, 1),
      ),
    ]);
    final notifier = WordNotifier(
      dictionary,
      database,
      HomeWidgetService(),
      retryDelay: Duration.zero,
    );

    await notifier.lookUp('luminous');

    expect(dictionary.calls, 2);
    expect(notifier.state.result?.word, 'luminous');
    expect(notifier.state.error, isNull);
  });

  test('verifies a not-found response once before showing it', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final dictionary = _FakeDictionaryService([
      const DictionaryException('Not found', kind: DictionaryFailure.notFound),
      const DictionaryException('Not found', kind: DictionaryFailure.notFound),
    ]);
    final notifier = WordNotifier(
      dictionary,
      database,
      HomeWidgetService(),
      retryDelay: Duration.zero,
    );

    await notifier.lookUp('notaword');

    expect(dictionary.calls, 2);
    expect(notifier.state.result, isNull);
    expect(notifier.state.error, 'Not found');
    expect(notifier.state.canRetry, isTrue);
  });
}

class _FakeDictionaryService extends DictionaryService {
  _FakeDictionaryService(this.responses);

  final List<Object> responses;
  int calls = 0;

  @override
  Future<WordModel> define(String word) async {
    final response = responses[calls++];
    if (response is DictionaryException) throw response;
    return response as WordModel;
  }
}
