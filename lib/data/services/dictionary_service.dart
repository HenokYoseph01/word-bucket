import 'package:dio/dio.dart';

import '../models/word_model.dart';

class DictionaryService {
  DictionaryService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://api.dictionaryapi.dev/api/v2/entries/en/',
              connectTimeout: const Duration(seconds: 7),
              receiveTimeout: const Duration(seconds: 7),
            ),
          );

  final Dio _dio;

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
      final meanings = entry['meanings'] as List<dynamic>?;
      if (meanings == null || meanings.isEmpty) {
        throw DictionaryException(
          'No definition found for "$normalizedWord".',
          kind: DictionaryFailure.notFound,
        );
      }

      final meaning = meanings.first as Map<String, dynamic>;
      final definitions = meaning['definitions'] as List<dynamic>?;
      if (definitions == null || definitions.isEmpty) {
        throw DictionaryException(
          'No definition found for "$normalizedWord".',
          kind: DictionaryFailure.notFound,
        );
      }

      final definition = definitions.first as Map<String, dynamic>;

      return WordModel(
        word: entry['word'] as String? ?? normalizedWord,
        phonetic: _readPhonetic(entry),
        partOfSpeech: meaning['partOfSpeech'] as String? ?? 'unknown',
        definition:
            definition['definition'] as String? ?? 'No definition available.',
        exampleSentence: definition['example'] as String?,
        savedAt: DateTime.now(),
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
