import 'package:drift/drift.dart';

import '../models/word_model.dart';
import 'database.dart';

class DeletedWordSnapshot {
  const DeletedWordSnapshot({required this.word, required this.meanings});

  final SavedWord word;
  final List<SavedMeaning> meanings;
}

extension WordDao on AppDatabase {
  Future<void> saveWord(WordModel model) => saveMeaning(model);

  Future<void> saveMeaning(WordModel model) {
    final nextReviewAt =
        model.nextReviewAt ?? DateTime.now().add(const Duration(days: 1));
    return transaction(() async {
      await into(words).insert(
        WordsCompanion.insert(
          word: model.word,
          phonetic: Value(model.phonetic),
          partOfSpeech: model.partOfSpeech,
          definition: model.definition,
          exampleSentence: Value(model.exampleSentence),
          savedAt: model.savedAt,
          reviewCount: Value(model.reviewCount),
          nextReviewAt: Value(nextReviewAt),
        ),
        mode: InsertMode.insertOrIgnore,
      );
      await into(savedMeanings).insert(
        SavedMeaningsCompanion.insert(
          word: model.word,
          phonetic: Value(model.phonetic),
          partOfSpeech: model.partOfSpeech,
          definition: model.definition,
          exampleSentence: Value(model.exampleSentence),
          savedAt: model.savedAt,
          reviewCount: Value(model.reviewCount),
          nextReviewAt: Value(nextReviewAt),
        ),
        mode: InsertMode.insertOrIgnore,
      );
    });
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
    return transaction(() async {
      await (delete(
        savedMeanings,
      )..where((meaning) => meaning.word.equals(text))).go();
      await (delete(words)..where((word) => word.word.equals(text))).go();
    });
  }

  Future<DeletedWordSnapshot?> deleteWordWithSnapshot(String text) async {
    final word = await getWord(text);
    if (word == null) return null;
    final snapshot = DeletedWordSnapshot(
      word: word,
      meanings: await getMeanings(text),
    );
    await deleteWord(text);
    return snapshot;
  }

  Future<DeletedWordSnapshot?> deleteMeaningWithSnapshot(
    String text,
    int meaningId,
  ) async {
    final word = await getWord(text);
    if (word == null) return null;
    final allMeanings = await getMeanings(text);
    if (!allMeanings.any((meaning) => meaning.id == meaningId)) return null;
    final snapshot = DeletedWordSnapshot(word: word, meanings: allMeanings);

    await transaction(() async {
      await (delete(
        savedMeanings,
      )..where((meaning) => meaning.id.equals(meaningId))).go();
      final remaining = allMeanings
          .where((meaning) => meaning.id != meaningId)
          .toList(growable: false);
      if (remaining.isEmpty) {
        await (delete(words)..where((row) => row.word.equals(text))).go();
        return;
      }
      final replacement = remaining.first;
      if (_sameStoredDefinition(
        word.definition,
        snapshot.meanings
            .firstWhere((meaning) => meaning.id == meaningId)
            .definition,
      )) {
        await (update(words)..where((row) => row.word.equals(text))).write(
          WordsCompanion(
            phonetic: Value(replacement.phonetic),
            partOfSpeech: Value(replacement.partOfSpeech),
            definition: Value(replacement.definition),
            exampleSentence: Value(replacement.exampleSentence),
            savedAt: Value(replacement.savedAt),
            reviewCount: Value(replacement.reviewCount),
            nextReviewAt: Value(replacement.nextReviewAt),
          ),
        );
      }
    });
    return snapshot;
  }

  Future<void> restoreDeletedWord(DeletedWordSnapshot snapshot) {
    return transaction(() async {
      await into(words).insertOnConflictUpdate(snapshot.word);
      for (final meaning in snapshot.meanings) {
        await into(
          savedMeanings,
        ).insert(meaning, mode: InsertMode.insertOrIgnore);
      }
    });
  }

  Future<SavedWord?> getWord(String text) {
    return (select(
      words,
    )..where((word) => word.word.equals(text))).getSingleOrNull();
  }

  Future<List<SavedMeaning>> getMeanings(String text) {
    return (select(savedMeanings)
          ..where((meaning) => meaning.word.equals(text))
          ..orderBy([(meaning) => OrderingTerm.asc(meaning.savedAt)]))
        .get();
  }

  Future<SavedMeaning?> getMeaning(int id) {
    return (select(
      savedMeanings,
    )..where((meaning) => meaning.id.equals(id))).getSingleOrNull();
  }

  Future<SavedMeaning?> getMeaningDueForReview({DateTime? at}) {
    return getMeaningsDueForReview(
      at: at,
      limit: 1,
    ).then((meanings) => meanings.firstOrNull);
  }

  Future<List<SavedMeaning>> getMeaningsDueForReview({
    DateTime? at,
    int? limit,
  }) {
    final reviewTime = at ?? DateTime.now();
    final query = select(savedMeanings)
      ..where(
        (meaning) =>
            meaning.nextReviewAt.isNull() |
            meaning.nextReviewAt.isSmallerOrEqualValue(reviewTime),
      )
      ..orderBy([
        (meaning) => OrderingTerm.asc(meaning.nextReviewAt),
        (meaning) => OrderingTerm.asc(meaning.savedAt),
      ]);
    if (limit != null) query.limit(limit);
    return query.get();
  }

  Future<void> recordMeaningReview(
    SavedMeaning meaning, {
    required bool remembered,
    DateTime? reviewedAt,
  }) {
    return transaction(() async {
      const reviewIntervals = [1, 3, 7, 14, 30];
      final completedReviews = remembered ? meaning.reviewCount + 1 : 0;
      final intervalIndex = completedReviews.clamp(
        0,
        reviewIntervals.length - 1,
      );
      final nextReview = DateTime.now().add(
        Duration(days: remembered ? reviewIntervals[intervalIndex] : 1),
      );
      await (update(
        savedMeanings,
      )..where((row) => row.id.equals(meaning.id))).write(
        SavedMeaningsCompanion(
          reviewCount: Value(completedReviews),
          nextReviewAt: Value(nextReview),
        ),
      );
      await into(reviewAttempts).insert(
        ReviewAttemptsCompanion.insert(
          word: meaning.word,
          reviewedAt: reviewedAt ?? DateTime.now(),
          remembered: remembered,
          reviewCount: completedReviews,
          meaningId: Value(meaning.id),
        ),
      );
    });
  }

  Stream<List<SavedMeaning>> watchAllMeanings() {
    return (select(
      savedMeanings,
    )..orderBy([(meaning) => OrderingTerm.asc(meaning.savedAt)])).watch();
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

bool _sameStoredDefinition(String first, String second) =>
    first.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase() ==
    second.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

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
