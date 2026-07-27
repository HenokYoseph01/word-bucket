import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/database.dart';
import '../data/database/word_dao.dart';
import '../data/models/word_model.dart';
import '../data/services/dictionary_service.dart';
import '../data/services/home_widget_service.dart';
import '../data/services/notification_service.dart';
import '../data/services/word_suggestion_service.dart';

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

final wordSuggestionServiceProvider = Provider<WordSuggestionService>((ref) {
  return WordSuggestionService();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final homeWidgetServiceProvider = Provider<HomeWidgetService>((ref) {
  return HomeWidgetService();
});

final savedWordsProvider = StreamProvider<List<SavedWord>>((ref) {
  return ref.watch(databaseProvider).watchAllWords();
});

final dueWordsProvider = FutureProvider<List<SavedWord>>((ref) {
  return ref.watch(databaseProvider).getWordsDueForReview();
});

class ReviewStatistics {
  const ReviewStatistics({
    required this.totalWords,
    required this.dueWords,
    required this.totalReviews,
    required this.rememberedReviews,
    required this.currentStreak,
    required this.upcomingWords,
    required this.frequentlyMissedWords,
  });

  final int totalWords;
  final int dueWords;
  final int totalReviews;
  final int rememberedReviews;
  final int currentStreak;
  final List<SavedWord> upcomingWords;
  final List<MapEntry<String, int>> frequentlyMissedWords;

  double get rememberedRate =>
      totalReviews == 0 ? 0 : rememberedReviews / totalReviews;
}

final reviewStatisticsProvider = FutureProvider<ReviewStatistics>((ref) async {
  final database = ref.watch(databaseProvider);
  final results = await Future.wait([
    database.getAllWords(),
    database.getWordsDueForReview(),
    database.getReviewHistory(),
  ]);
  final words = results[0] as List<SavedWord>;
  final dueWords = results[1] as List<SavedWord>;
  final history = results[2] as List<ReviewAttempt>;
  final now = DateTime.now();

  final missedCounts = <String, int>{};
  for (final attempt in history.where((attempt) => !attempt.remembered)) {
    missedCounts.update(attempt.word, (count) => count + 1, ifAbsent: () => 1);
  }
  final frequentlyMissed = missedCounts.entries.toList()
    ..sort((a, b) {
      final countComparison = b.value.compareTo(a.value);
      return countComparison != 0 ? countComparison : a.key.compareTo(b.key);
    });

  final upcoming =
      words
          .where(
            (word) =>
                word.nextReviewAt != null && word.nextReviewAt!.isAfter(now),
          )
          .toList()
        ..sort((a, b) => a.nextReviewAt!.compareTo(b.nextReviewAt!));

  return ReviewStatistics(
    totalWords: words.length,
    dueWords: dueWords.length,
    totalReviews: history.length,
    rememberedReviews: history.where((attempt) => attempt.remembered).length,
    currentStreak: _calculateReviewStreak(history, now),
    upcomingWords: upcoming.take(5).toList(growable: false),
    frequentlyMissedWords: frequentlyMissed.take(5).toList(growable: false),
  );
});

int _calculateReviewStreak(List<ReviewAttempt> history, DateTime now) {
  if (history.isEmpty) return 0;

  final reviewDays = history
      .map(
        (attempt) => DateTime(
          attempt.reviewedAt.year,
          attempt.reviewedAt.month,
          attempt.reviewedAt.day,
        ),
      )
      .toSet();
  final today = DateTime(now.year, now.month, now.day);
  var day = reviewDays.contains(today)
      ? today
      : today.subtract(const Duration(days: 1));
  var streak = 0;

  while (reviewDays.contains(day)) {
    streak++;
    day = day.subtract(const Duration(days: 1));
  }
  return streak;
}

class LookupState {
  const LookupState({this.isLoading = false, this.result, this.error});

  final bool isLoading;
  final WordModel? result;
  final String? error;
}

class WordNotifier extends StateNotifier<LookupState> {
  WordNotifier(this._dictionary, this._database, this._homeWidget)
    : super(const LookupState());

  final DictionaryService _dictionary;
  final AppDatabase _database;
  final HomeWidgetService _homeWidget;

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
    await _homeWidget.syncFromDatabase(_database, preferredWord: result.word);
    state = const LookupState();
    return result;
  }

  Future<void> deleteWord(String word) async {
    await _database.deleteWord(word);
    await syncHomeWidget();
  }

  Future<void> syncHomeWidget() {
    return _homeWidget.syncFromDatabase(_database);
  }

  Future<void> recordReview(SavedWord word, {required bool remembered}) async {
    await _database.recordReviewAttempt(word, remembered: remembered);
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
    ref.watch(homeWidgetServiceProvider),
  );
});
