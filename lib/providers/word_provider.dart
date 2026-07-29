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
    required this.wordMastery,
  });

  final int totalWords;
  final int dueWords;
  final int totalReviews;
  final int rememberedReviews;
  final int currentStreak;
  final List<SavedWord> upcomingWords;
  final List<WordMastery> wordMastery;

  double get rememberedRate =>
      totalReviews == 0 ? 0 : rememberedReviews / totalReviews;

  int masteryCount(MasteryLevel level) =>
      wordMastery.where((word) => word.level == level).length;

  List<WordMastery> get strongestWords {
    final reviewed =
        wordMastery.where((word) => word.level == MasteryLevel.strong).toList()
          ..sort((a, b) => b.strengthScore.compareTo(a.strengthScore));
    return reviewed.take(5).toList(growable: false);
  }

  List<WordMastery> get weakestWords {
    final reviewed =
        wordMastery
            .where((word) => word.level == MasteryLevel.needsPractice)
            .toList()
          ..sort((a, b) => a.strengthScore.compareTo(b.strengthScore));
    return reviewed.take(5).toList(growable: false);
  }
}

enum MasteryLevel { newWord, learning, strong, needsPractice }

class WordMastery {
  const WordMastery({
    required this.word,
    required this.history,
    required this.remembered,
    required this.level,
    required this.strengthScore,
  });

  final SavedWord word;
  final List<ReviewAttempt> history;
  final int remembered;
  final MasteryLevel level;
  final double strengthScore;

  int get attempts => history.length;
  int get missed => attempts - remembered;
  double get recallRate => attempts == 0 ? 0 : remembered / attempts;
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

  final mastery = words
      .map((word) {
        final wordHistory = history
            .where((attempt) => attempt.word == word.word)
            .toList(growable: false);
        final remembered = wordHistory
            .where((attempt) => attempt.remembered)
            .length;
        final attempts = wordHistory.length;
        final recallRate = attempts == 0 ? 0.0 : remembered / attempts;
        final recentMisses =
            attempts >= 2 &&
            wordHistory.take(2).every((attempt) => !attempt.remembered);

        final level = switch (attempts) {
          < 2 => MasteryLevel.newWord,
          _ when recallRate < 0.5 || recentMisses => MasteryLevel.needsPractice,
          _ when attempts >= 3 && recallRate >= 0.8 && word.reviewCount >= 2 =>
            MasteryLevel.strong,
          _ => MasteryLevel.learning,
        };

        // Bayesian smoothing prevents one lucky review from outranking words
        // remembered reliably across several attempts.
        final smoothedRecall = (remembered + 1) / (attempts + 2);
        final confidence = (attempts / 5).clamp(0.0, 1.0);
        final streakBonus = (word.reviewCount / 5).clamp(0.0, 1.0);
        final strengthScore =
            (smoothedRecall * 0.65) + (confidence * 0.2) + (streakBonus * 0.15);

        return WordMastery(
          word: word,
          history: wordHistory,
          remembered: remembered,
          level: level,
          strengthScore: strengthScore,
        );
      })
      .toList(growable: false);

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
    wordMastery: mastery,
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
  const LookupState({
    this.isLoading = false,
    this.result,
    this.error,
    this.existingWord,
  });

  final bool isLoading;
  final WordModel? result;
  final String? error;
  final SavedWord? existingWord;
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
      final normalizedWord = text.trim().toLowerCase();
      final existingWord = await _database.getWord(normalizedWord);
      if (existingWord != null) {
        state = LookupState(
          result: existingWord.toModel(),
          existingWord: existingWord,
        );
        return;
      }
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
