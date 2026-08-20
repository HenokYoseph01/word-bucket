import 'package:dio/dio.dart';

import '../models/word_model.dart';

class DictionaryService {
  DictionaryService({Dio? dio, Dio? fallbackDio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://api.dictionaryapi.dev/api/v2/entries/en/',
              connectTimeout: const Duration(seconds: 7),
              receiveTimeout: const Duration(seconds: 7),
            ),
          ),
      _fallbackDio =
          fallbackDio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://api.datamuse.com',
              connectTimeout: const Duration(seconds: 7),
              receiveTimeout: const Duration(seconds: 7),
            ),
          );

  final Dio _dio;
  final Dio _fallbackDio;

  Future<WordModel> define(String word) async {
    final normalizedWord = word.trim().toLowerCase();
    if (normalizedWord.isEmpty) {
      throw const DictionaryException(
        'Enter a word to look up.',
        kind: DictionaryFailure.invalidInput,
      );
    }

    try {
      final response = await _dio.get<List<dynamic>>(
        Uri.encodeComponent(normalizedWord),
      );
      final entries = response.data;
      if (entries == null || entries.isEmpty) {
        throw DictionaryException(
          'No definition found for "$normalizedWord".',
          kind: DictionaryFailure.notFound,
        );
      }

      final entry = entries.first as Map<String, dynamic>;
      final senses = _readSenses(entries);
      if (senses.isEmpty) {
        throw DictionaryException(
          'No definition found for "$normalizedWord".',
          kind: DictionaryFailure.notFound,
        );
      }
      final selected = senses.first;

      return WordModel(
        word: entry['word'] as String? ?? normalizedWord,
        phonetic: _readPhonetic(entry),
        partOfSpeech: selected.partOfSpeech,
        definition: selected.definition,
        exampleSentence: selected.exampleSentence,
        savedAt: DateTime.now(),
        senses: senses,
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        throw DictionaryException(
          '"$normalizedWord" was not found.',
          kind: DictionaryFailure.notFound,
        );
      }
      final statusCode = error.response?.statusCode;
      final retryable =
          statusCode == null ||
          statusCode == 408 ||
          statusCode == 429 ||
          statusCode >= 500;
      throw DictionaryException(
        retryable
            ? 'The dictionary did not respond. Check your connection and try again.'
            : 'The dictionary could not process this request.',
        kind: retryable
            ? DictionaryFailure.temporary
            : DictionaryFailure.unexpectedResponse,
      );
    } on DictionaryException {
      rethrow;
    } on FormatException {
      throw const DictionaryException(
        'The dictionary returned an unexpected response.',
        kind: DictionaryFailure.unexpectedResponse,
      );
    } on TypeError {
      throw const DictionaryException(
        'The dictionary returned an unexpected response.',
        kind: DictionaryFailure.unexpectedResponse,
      );
    }
  }

  Future<WordModel> defineFallback(String word) async {
    final normalizedWord = word.trim().toLowerCase();
    if (normalizedWord.isEmpty) {
      throw const DictionaryException(
        'Enter a word to look up.',
        kind: DictionaryFailure.invalidInput,
      );
    }

    try {
      final response = await _fallbackDio.get<List<dynamic>>(
        '/words',
        queryParameters: {
          'sp': normalizedWord,
          'md': 'dpr',
          'ipa': 1,
          'max': 10,
        },
      );
      final entries = response.data;
      if (entries == null || entries.isEmpty) {
        throw DictionaryException(
          'No definition found for "$normalizedWord".',
          kind: DictionaryFailure.notFound,
        );
      }

      final candidates = entries.whereType<Map<String, dynamic>>();
      final entry = candidates.cast<Map<String, dynamic>?>().firstWhere((
        candidate,
      ) {
        if (candidate == null) return false;
        final definitions = candidate['defs'] as List<dynamic>?;
        if (definitions == null || definitions.isEmpty) return false;
        final tags = (candidate['tags'] as List<dynamic>?)?.whereType<String>();
        // Datamuse uses uppercase POS tags for proper names. Those results
        // often describe albums, films, and songs rather than vocabulary.
        return tags?.any(const {'n', 'v', 'adj', 'adv'}.contains) ?? false;
      }, orElse: () => null);
      if (entry == null) {
        throw DictionaryException(
          'No definition found for "$normalizedWord".',
          kind: DictionaryFailure.notFound,
        );
      }
      final definitions = entry['defs'] as List<dynamic>?;
      if (definitions == null || definitions.isEmpty) {
        throw DictionaryException(
          'No definition found for "$normalizedWord".',
          kind: DictionaryFailure.notFound,
        );
      }

      final senses = definitions
          .whereType<String>()
          .map(_readFallbackSense)
          .where((sense) => sense.definition.isNotEmpty)
          .toSetBy((sense) => '${sense.partOfSpeech}|${sense.definition}')
          .take(8)
          .toList(growable: false);
      if (senses.isEmpty) {
        throw DictionaryException(
          'No definition found for "$normalizedWord".',
          kind: DictionaryFailure.notFound,
        );
      }
      final selected = senses.first;
      final tags = (entry['tags'] as List<dynamic>?)?.whereType<String>();
      final phonetic = _readFallbackPhonetic(tags);

      return WordModel(
        // Preserve what the user looked up when Datamuse supplies a base form
        // (for example, "feeling" for "feelings").
        word: normalizedWord,
        phonetic: phonetic,
        partOfSpeech: selected.partOfSpeech,
        definition: selected.definition,
        savedAt: DateTime.now(),
        senses: senses,
      );
    } on DioException {
      throw const DictionaryException(
        'The backup dictionary did not respond.',
        kind: DictionaryFailure.temporary,
      );
    } on DictionaryException {
      rethrow;
    } on FormatException {
      throw const DictionaryException(
        'The backup dictionary returned an unexpected response.',
        kind: DictionaryFailure.unexpectedResponse,
      );
    } on TypeError {
      throw const DictionaryException(
        'The backup dictionary returned an unexpected response.',
        kind: DictionaryFailure.unexpectedResponse,
      );
    }
  }

  String? _readFallbackPhonetic(Iterable<String>? tags) {
    if (tags == null) return null;
    for (final prefix in const ['ipa_pron:', 'pron:']) {
      for (final tag in tags) {
        if (tag.startsWith(prefix)) {
          final value = tag.substring(prefix.length).trim();
          if (value.isNotEmpty) return value;
        }
      }
    }
    return null;
  }

  String _expandPartOfSpeech(String value) => switch (value) {
    'n' => 'noun',
    'v' => 'verb',
    'adj' => 'adjective',
    'adv' => 'adverb',
    _ => value,
  };

  List<WordSense> _readSenses(List<dynamic> entries) {
    final senses = <WordSense>[];
    final seen = <String>{};
    for (final rawEntry in entries.whereType<Map<String, dynamic>>()) {
      final meanings = rawEntry['meanings'] as List<dynamic>? ?? const [];
      for (final rawMeaning in meanings.whereType<Map<String, dynamic>>()) {
        final partOfSpeech = rawMeaning['partOfSpeech'] as String? ?? 'unknown';
        final definitions =
            rawMeaning['definitions'] as List<dynamic>? ?? const [];
        for (final rawDefinition
            in definitions.whereType<Map<String, dynamic>>()) {
          final definition = (rawDefinition['definition'] as String?)?.trim();
          if (definition == null || definition.isEmpty) continue;
          final key =
              '${partOfSpeech.toLowerCase()}|${definition.toLowerCase()}';
          if (!seen.add(key)) continue;
          senses.add(
            WordSense(
              partOfSpeech: partOfSpeech,
              definition: definition,
              exampleSentence: rawDefinition['example'] as String?,
            ),
          );
          if (senses.length == 8) return senses;
        }
      }
    }
    return senses;
  }

  WordSense _readFallbackSense(String rawDefinition) {
    final separator = rawDefinition.indexOf('\t');
    final rawPartOfSpeech = separator == -1
        ? 'unknown'
        : rawDefinition.substring(0, separator);
    return WordSense(
      partOfSpeech: _expandPartOfSpeech(rawPartOfSpeech),
      definition:
          (separator == -1
                  ? rawDefinition
                  : rawDefinition.substring(separator + 1))
              .trim(),
    );
  }

  String? _readPhonetic(Map<String, dynamic> entry) {
    final directPhonetic = entry['phonetic'] as String?;
    if (directPhonetic != null && directPhonetic.isNotEmpty) {
      return directPhonetic;
    }

    final phonetics = entry['phonetics'] as List<dynamic>?;
    if (phonetics == null) return null;

    for (final item in phonetics) {
      final phonetic = (item as Map<String, dynamic>)['text'] as String?;
      if (phonetic != null && phonetic.isNotEmpty) return phonetic;
    }
    return null;
  }
}

extension<T> on Iterable<T> {
  Iterable<T> toSetBy(Object Function(T value) keyOf) sync* {
    final keys = <Object>{};
    for (final value in this) {
      if (keys.add(keyOf(value))) yield value;
    }
  }
}

enum DictionaryFailure { invalidInput, notFound, temporary, unexpectedResponse }

class DictionaryException implements Exception {
  const DictionaryException(this.message, {required this.kind});

  final String message;
  final DictionaryFailure kind;

  // The public dictionary occasionally returns a transient 404 for a valid
  // word. Verify a not-found response once before treating it as final.
  bool get isRetryable =>
      kind == DictionaryFailure.temporary || kind == DictionaryFailure.notFound;

  @override
  String toString() => message;
}
