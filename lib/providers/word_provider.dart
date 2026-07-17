import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/database.dart';
import '../data/database/word_dao.dart';
import '../data/models/word_model.dart';
import '../data/services/dictionary_service.dart';
import '../data/services/notification_service.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(() {
    database.close();
  });
  return database;
});

final dictionaryServiceProvider = Provider<DictionaryService>((ref) {
  return DictionaryService();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final savedWordsProvider = StreamProvider<List<SavedWord>>((ref) {
  return ref.watch(databaseProvider).watchAllWords();
});

class LookupState {
  const LookupState({this.isLoading = false, this.result, this.error});

  final bool isLoading;
  final WordModel? result;
  final String? error;
}

class WordNotifier extends StateNotifier<LookupState> {
  WordNotifier(this._dictionary, this._database) : super(const LookupState());

  final DictionaryService _dictionary;
  final AppDatabase _database;

  Future<void> lookUp(String text) async {
    state = const LookupState(isLoading: true);
    try {
      final result = await _dictionary.define(text);
      state = LookupState(result: result);
    } on DictionaryException catch (error) {
      state = LookupState(error: error.message);
    }
  }

  Future<WordModel?> saveCurrentWord() async {
    final result = state.result;
    if (result == null) return null;

    await _database.saveWord(result);
    state = const LookupState();
    return result;
  }

  void clear() {
    state = const LookupState();
  }
}

final wordNotifierProvider = StateNotifierProvider<WordNotifier, LookupState>((
  ref,
) {
  return WordNotifier(
    ref.watch(dictionaryServiceProvider),
    ref.watch(databaseProvider),
  );
});
