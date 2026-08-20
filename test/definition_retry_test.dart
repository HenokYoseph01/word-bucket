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

  test('uses the backup dictionary after both primary attempts fail', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final dictionary = _FakeDictionaryService(
      [
        const DictionaryException(
          'Temporary failure',
          kind: DictionaryFailure.temporary,
        ),
        const DictionaryException(
          'Temporary failure',
          kind: DictionaryFailure.temporary,
        ),
      ],
      fallbackResponse: WordModel(
        word: 'luminous',
        partOfSpeech: 'adjective',
        definition: 'Emitting light.',
        savedAt: DateTime(2026, 8, 7),
      ),
    );
    final notifier = WordNotifier(
      dictionary,
      database,
      HomeWidgetService(),
      retryDelay: Duration.zero,
    );

    await notifier.lookUp('luminous');

    expect(dictionary.calls, 2);
    expect(dictionary.fallbackCalls, 1);
    expect(notifier.state.result?.definition, 'Emitting light.');
    expect(notifier.state.error, isNull);
  });

  test('selects the intended meaning before saving', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final dictionary = _FakeDictionaryService([
      WordModel(
        word: 'pen',
        partOfSpeech: 'noun',
        definition: 'A small enclosure for animals.',
        savedAt: DateTime(2026, 8, 19),
        senses: const [
          WordSense(
            partOfSpeech: 'noun',
            definition: 'A small enclosure for animals.',
          ),
          WordSense(
            partOfSpeech: 'noun',
            definition: 'An instrument used for writing with ink.',
          ),
        ],
      ),
    ]);
    final notifier = WordNotifier(
      dictionary,
      database,
      HomeWidgetService(),
      retryDelay: Duration.zero,
    );

    await notifier.lookUp('pen');
    notifier.selectSense(1);

    expect(
      notifier.state.result?.definition,
      'An instrument used for writing with ink.',
    );
    expect(notifier.state.result?.senses, hasLength(2));
  });
}

class _FakeDictionaryService extends DictionaryService {
  _FakeDictionaryService(this.responses, {this.fallbackResponse});

  final List<Object> responses;
  final WordModel? fallbackResponse;
  int calls = 0;
  int fallbackCalls = 0;

  @override
  Future<WordModel> define(String word) async {
    final response = responses[calls++];
    if (response is DictionaryException) throw response;
    return response as WordModel;
  }

  @override
  Future<WordModel> defineFallback(String word) async {
    fallbackCalls++;
    final result = fallbackResponse;
    if (result != null) return result;
    throw const DictionaryException(
      'Fallback not found',
      kind: DictionaryFailure.notFound,
    );
  }
}
