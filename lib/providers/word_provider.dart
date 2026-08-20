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

final savedMeaningsProvider = StreamProvider<List<SavedMeaning>>((ref) {
  return ref.watch(databaseProvider).watchAllMeanings();
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
    required this.weeklyActivity,
    required this.longestStreak,
    required this.overdueWords,
    required this.dueToday,
    required this.dueTomorrow,
    required this.dueThisWeek,
  });

  final int totalWords;
  final int dueWords;
  final int totalReviews;
  final int rememberedReviews;
  final int currentStreak;
  final List<SavedWord> upcomingWords;
  final List<WordMastery> wordMastery;
  final List<DailyReviewActivity> weeklyActivity;
  final int longestStreak;
  final int overdueWords;
  final int dueToday;
  final int dueTomorrow;
  final int dueThisWeek;

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

  DailyReviewActivity? get mostActiveDay {
    if (weeklyActivity.every((day) => day.reviews == 0)) return null;
    return weeklyActivity.reduce(
      (best, day) => day.reviews > best.reviews ? day : best,
    );
  }
}

class DailyReviewActivity {
  const DailyReviewActivity({
    required this.date,
    required this.reviews,
    required this.remembered,
    required this.wordsAdded,
  });

  final DateTime date;
  final int reviews;
  final int remembered;
  final int wordsAdded;

  double get rememberedRate => reviews == 0 ? 0 : remembered / reviews;
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
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));
  final dayAfterTomorrow = tomorrow.add(const Duration(days: 1));
  final endOfForecast = today.add(const Duration(days: 8));

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

  final weeklyActivity = List.generate(7, (index) {
    final date = today.subtract(Duration(days: 6 - index));
    final nextDate = date.add(const Duration(days: 1));
    final dayReviews = history.where(
      (attempt) =>
          !attempt.reviewedAt.isBefore(date) &&
          attempt.reviewedAt.isBefore(nextDate),
    );
    return DailyReviewActivity(
      date: date,
      reviews: dayReviews.length,
      remembered: dayReviews.where((attempt) => attempt.remembered).length,
      wordsAdded: words
          .where(
            (word) =>
                !word.savedAt.isBefore(date) && word.savedAt.isBefore(nextDate),
          )
          .length,
    );
  });

  final overdueWords = words
      .where(
        (word) =>
            word.nextReviewAt == null || word.nextReviewAt!.isBefore(today),
      )
      .length;
  final dueToday = words
      .where(
        (word) =>
            word.nextReviewAt != null &&
            !word.nextReviewAt!.isBefore(today) &&
            word.nextReviewAt!.isBefore(tomorrow),
      )
      .length;
  final dueTomorrow = words
      .where(
        (word) =>
            word.nextReviewAt != null &&
            !word.nextReviewAt!.isBefore(tomorrow) &&
            word.nextReviewAt!.isBefore(dayAfterTomorrow),
      )
      .length;
  final dueThisWeek = words
      .where(
        (word) =>
            word.nextReviewAt != null &&
            !word.nextReviewAt!.isBefore(dayAfterTomorrow) &&
            word.nextReviewAt!.isBefore(endOfForecast),
      )
      .length;

  return ReviewStatistics(
    totalWords: words.length,
    dueWords: dueWords.length,
    totalReviews: history.length,
    rememberedReviews: history.where((attempt) => attempt.remembered).length,
    currentStreak: _calculateReviewStreak(history, now),
    upcomingWords: upcoming.take(5).toList(growable: false),
    wordMastery: mastery,
    weeklyActivity: weeklyActivity,
    longestStreak: _calculateLongestStreak(history),
    overdueWords: overdueWords,
    dueToday: dueToday,
    dueTomorrow: dueTomorrow,
    dueThisWeek: dueThisWeek,
  );
});

int _calculateLongestStreak(List<ReviewAttempt> history) {
  final days =
      history
          .map(
            (attempt) => DateTime(
              attempt.reviewedAt.year,
              attempt.reviewedAt.month,
              attempt.reviewedAt.day,
            ),
          )
          .toSet()
          .toList()
        ..sort();
  if (days.isEmpty) return 0;

  var longest = 1;
  var current = 1;
  for (var index = 1; index < days.length; index++) {
    if (days[index].difference(days[index - 1]).inDays == 1) {
      current++;
      if (current > longest) longest = current;
    } else {
      current = 1;
    }
  }
  return longest;
}

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
    this.isRetrying = false,
    this.result,
    this.error,
    this.canRetry = false,
    this.existingWord,
    this.savedMeanings = const [],
  });

  final bool isLoading;
  final bool isRetrying;
  final WordModel? result;
  final String? error;
  final bool canRetry;
  final SavedWord? existingWord;
  final List<SavedMeaning> savedMeanings;

  SavedMeaning? get selectedSavedMeaning {
    final selected = result;
    if (selected == null) return null;
    for (final meaning in savedMeanings) {
      if (_sameDefinition(meaning.definition, selected.definition)) {
        return meaning;
      }
    }
    return null;
  }
}

bool _sameDefinition(String first, String second) =>
    first.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase() ==
    second.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

class WordNotifier extends StateNotifier<LookupState> {
  WordNotifier(
    this._dictionary,
    this._database,
    this._homeWidget, {
    this._retryDelay = const Duration(seconds: 5),
  }) : super(const LookupState());

  final DictionaryService _dictionary;
  final AppDatabase _database;
  final HomeWidgetService _homeWidget;
  final Duration _retryDelay;
  int _lookupGeneration = 0;
  String? _lastLookup;

  Future<void> lookUp(String text) async {
    final request = ++_lookupGeneration;
    final normalizedWord = text.trim().toLowerCase();
    _lastLookup = normalizedWord;
    state = const LookupState(isLoading: true);
    try {
      final existingWord = await _database.getWord(normalizedWord);
      final savedMeanings = existingWord == null
          ? const <SavedMeaning>[]
          : await _database.getMeanings(normalizedWord);
      if (request != _lookupGeneration) return;

      DictionaryException? primaryError;
      for (var attempt = 0; attempt < 2; attempt++) {
        try {
          final result = await _dictionary.define(normalizedWord);
          if (request == _lookupGeneration) {
            state = LookupState(
              result: _includeSavedSenses(result, savedMeanings),
              existingWord: existingWord,
              savedMeanings: savedMeanings,
            );
          }
          return;
        } on DictionaryException catch (error) {
          if (request != _lookupGeneration) return;
          final shouldRetry = error.isRetryable && attempt == 0;
          if (!shouldRetry) {
            primaryError = error;
            break;
          }

          state = const LookupState(isLoading: true, isRetrying: true);
          await Future<void>.delayed(_retryDelay);
          if (request != _lookupGeneration) return;
        }
      }

      if (primaryError != null) {
        try {
          final result = await _dictionary.defineFallback(normalizedWord);
          if (request == _lookupGeneration) {
            state = LookupState(
              result: _includeSavedSenses(result, savedMeanings),
              existingWord: existingWord,
              savedMeanings: savedMeanings,
            );
          }
        } on DictionaryException catch (fallbackError) {
          if (request == _lookupGeneration) {
            state = existingWord == null
                ? LookupState(
                    error: primaryError.message,
                    canRetry:
                        primaryError.isRetryable || fallbackError.isRetryable,
                  )
                : LookupState(
                    result: _includeSavedSenses(
                      existingWord.toModel(),
                      savedMeanings,
                    ),
                    existingWord: existingWord,
                    savedMeanings: savedMeanings,
                  );
          }
        }
      }
    } on DictionaryException catch (error) {
      if (request == _lookupGeneration) {
        state = LookupState(error: error.message, canRetry: error.isRetryable);
      }
    } catch (_) {
      if (request == _lookupGeneration) {
        state = const LookupState(
          error: 'Something interrupted the lookup. Please try again.',
          canRetry: true,
        );
      }
    }
  }

  Future<void> retry() async {
    final word = _lastLookup;
    if (word == null || word.isEmpty) return;
    await lookUp(word);
  }

  Future<WordModel?> saveCurrentWord() async {
    final result = state.result;
    if (result == null) return null;
    if (state.selectedSavedMeaning != null) return null;

    await _database.saveMeaning(result);
    await _homeWidget.syncFromDatabase(_database, preferredWord: result.word);
    state = const LookupState();
    return result;
  }

  void selectSense(int index) {
    final result = state.result;
    if (result == null || index < 0 || index >= result.senses.length) return;
    state = LookupState(
      result: result.withSense(result.senses[index]),
      existingWord: state.existingWord,
      savedMeanings: state.savedMeanings,
    );
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
    _lookupGeneration++;
    _lastLookup = null;
    state = const LookupState();
  }

  WordModel _includeSavedSenses(
    WordModel result,
    List<SavedMeaning> savedMeanings,
  ) {
    if (savedMeanings.isEmpty) return result;
    final senses = [...result.senses];
    for (final saved in savedMeanings) {
      if (senses.any(
        (sense) => _sameDefinition(sense.definition, saved.definition),
      )) {
        continue;
      }
      senses.add(
        WordSense(
          partOfSpeech: saved.partOfSpeech,
          definition: saved.definition,
          exampleSentence: saved.exampleSentence,
        ),
      );
    }
    final selected = senses.firstWhere(
      (sense) => _sameDefinition(sense.definition, result.definition),
      orElse: () => senses.first,
    );
    return WordModel(
      word: result.word,
      phonetic: result.phonetic,
      partOfSpeech: selected.partOfSpeech,
      definition: selected.definition,
      exampleSentence: selected.exampleSentence,
      savedAt: result.savedAt,
      reviewCount: result.reviewCount,
      nextReviewAt: result.nextReviewAt,
      senses: senses,
    );
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
