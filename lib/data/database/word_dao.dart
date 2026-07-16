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
        nextReviewAt: Value(model.nextReviewAt),
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
