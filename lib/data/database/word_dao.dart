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

  Future<void> deleteWord(String text) {
    return (delete(words)..where((word) => word.word.equals(text))).go();
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
    final reviewTime = at ?? DateTime.now();
    return (select(words)
          ..where(
            (word) =>
                word.nextReviewAt.isNull() |
                word.nextReviewAt.isSmallerOrEqualValue(reviewTime),
          )
          ..orderBy([
            (word) => OrderingTerm.asc(word.nextReviewAt),
            (word) => OrderingTerm.asc(word.savedAt),
          ])
          ..limit(1))
        .getSingleOrNull();
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
