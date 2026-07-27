import 'package:dio/dio.dart';

class WordSuggestionService {
  WordSuggestionService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://api.datamuse.com',
              connectTimeout: const Duration(seconds: 3),
              receiveTimeout: const Duration(seconds: 3),
            ),
          );

  final Dio _dio;

  Future<List<String>> suggest(String query) async {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.length < 2) return const [];

    try {
      final response = await _dio.get<List<dynamic>>(
        '/sug',
        queryParameters: {'s': normalizedQuery, 'max': 8},
      );

      return (response.data ?? const [])
          .map((item) => (item as Map<String, dynamic>)['word'] as String?)
          .whereType<String>()
          .where((word) => word.isNotEmpty && !word.contains(' '))
          .take(5)
          .toList(growable: false);
    } on DioException {
      // Suggestions are optional; manual dictionary search must keep working.
      return const [];
    } on TypeError {
      return const [];
    }
  }
}
