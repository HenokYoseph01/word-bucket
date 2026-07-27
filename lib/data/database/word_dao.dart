import 'package:drift/drift.dart';

import '../models/word_model.dart';
import 'database.dart';

extension WordDao on AppDatabase {
  Future<void> saveWord(WordModel model) {
    return into(words).insertOnConflictUpdate(
      WordsCompanion.insert(
        word: model.word,
        phonetic: Value(model.phonetic),
        partOfSpeech: model.partOfSpeech,
        definition: model.definition,
        exampleSentence: Value(model.exampleSentence),
        savedAt: model.savedAt,
        reviewCount: Value(model.reviewCount),
        nextReviewAt: Value(
          model.nextReviewAt ?? DateTime.now().add(const Duration(days: 1)),
        ),
      ),
    );
  }

  Stream<List<SavedWord>> watchAllWords() {
    return (select(
      words,
    )..orderBy([(word) => OrderingTerm.desc(word.savedAt)])).watch();
  }

  Future<List<SavedWord>> getAllWords() {
    return (select(
      words,
    )..orderBy([(word) => OrderingTerm.desc(word.savedAt)])).get();
  }

  Future<void> deleteWord(String text) {
    return (delete(words)..where((word) => word.word.equals(text))).go();
  }

  Future<SavedWord?> getWord(String text) {
    return (select(
      words,
    )..where((word) => word.word.equals(text))).getSingleOrNull();
  }

  Future<SavedWord?> getRandomWord({String? excluding}) {
    final query = select(words);
    if (excluding != null) {
      query.where((word) => word.word.isNotValue(excluding));
    }
    query
      ..orderBy([(word) => OrderingTerm.random()])
      ..limit(1);
    return query.getSingleOrNull();
  }

  Future<SavedWord?> getWordDueForReview({DateTime? at}) {
    return getWordsDueForReview(
      at: at,
      limit: 1,
    ).then((words) => words.firstOrNull);
  }

  Future<List<SavedWord>> getWordsDueForReview({DateTime? at, int? limit}) {
    final reviewTime = at ?? DateTime.now();
    final query = select(words)
      ..where(
        (word) =>
            word.nextReviewAt.isNull() |
            word.nextReviewAt.isSmallerOrEqualValue(reviewTime),
      )
      ..orderBy([
        (word) => OrderingTerm.asc(word.nextReviewAt),
        (word) => OrderingTerm.asc(word.savedAt),
      ]);
    if (limit != null) query.limit(limit);
    return query.get();
  }

  Future<void> advanceReviewSchedule(SavedWord word) {
    const reviewIntervals = [1, 3, 7, 14, 30];
    final completedReviews = word.reviewCount + 1;
    final intervalIndex = completedReviews.clamp(0, reviewIntervals.length - 1);
    final nextReview = DateTime.now().add(
      Duration(days: reviewIntervals[intervalIndex]),
    );

    return (update(words)..where((row) => row.word.equals(word.word))).write(
      WordsCompanion(
        reviewCount: Value(completedReviews),
        nextReviewAt: Value(nextReview),
      ),
    );
  }

  Future<void> resetReviewSchedule(SavedWord word) {
    return (update(words)..where((row) => row.word.equals(word.word))).write(
      WordsCompanion(
        reviewCount: const Value(0),
        nextReviewAt: Value(DateTime.now().add(const Duration(days: 1))),
      ),
    );
  }

  Future<void> recordReviewAttempt(
    SavedWord word, {
    required bool remembered,
    DateTime? reviewedAt,
  }) {
    return transaction(() async {
      if (remembered) {
        await advanceReviewSchedule(word);
      } else {
        await resetReviewSchedule(word);
      }

      await into(reviewAttempts).insert(
        ReviewAttemptsCompanion.insert(
          word: word.word,
          reviewedAt: reviewedAt ?? DateTime.now(),
          remembered: remembered,
          reviewCount: remembered ? word.reviewCount + 1 : 0,
        ),
      );
    });
  }

  Future<List<ReviewAttempt>> getReviewHistory() {
    return (select(
      reviewAttempts,
    )..orderBy([(attempt) => OrderingTerm.desc(attempt.reviewedAt)])).get();
  }
}

extension SavedWordModel on SavedWord {
  WordModel toModel() {
    return WordModel(
      word: word,
      phonetic: phonetic,
      partOfSpeech: partOfSpeech,
      definition: definition,
      exampleSentence: exampleSentence,
      savedAt: savedAt,
      reviewCount: reviewCount,
      nextReviewAt: nextReviewAt,
    );
  }
}
