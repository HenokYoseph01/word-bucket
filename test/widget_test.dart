import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wordbucket/data/database/database.dart';
import 'package:wordbucket/data/database/word_dao.dart';
import 'package:wordbucket/data/models/word_model.dart';

void main() {
  test('saves and reads a word', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await database.saveWord(
      WordModel(
        word: 'ephemeral',
        partOfSpeech: 'adjective',
        definition: 'Lasting for a very short time.',
        savedAt: DateTime(2026, 7, 16),
      ),
    );

    final words = await database.watchAllWords().first;

    expect(words, hasLength(1));
    expect(words.single.word, 'ephemeral');
    expect(words.single.reviewCount, 0);
    expect(words.single.nextReviewAt, isNotNull);

    final originalReviewDate = words.single.nextReviewAt!;
    await database.recordReviewAttempt(
      words.single,
      remembered: true,
      reviewedAt: DateTime(2026, 7, 17),
    );
    final reviewedWord = (await database.watchAllWords().first).single;

    expect(reviewedWord.reviewCount, 1);
    expect(reviewedWord.nextReviewAt!.isAfter(originalReviewDate), isTrue);

    await database.recordReviewAttempt(
      reviewedWord,
      remembered: false,
      reviewedAt: DateTime(2026, 7, 18),
    );
    final forgottenWord = (await database.watchAllWords().first).single;

    expect(forgottenWord.reviewCount, 0);
    expect(
      forgottenWord.nextReviewAt!.isBefore(reviewedWord.nextReviewAt!),
      isTrue,
    );

    final history = await database.getReviewHistory();
    expect(history, hasLength(2));
    expect(history.first.word, 'ephemeral');
    expect(history.first.remembered, isFalse);
    expect(history.first.reviewCount, 0);
    expect(history.last.remembered, isTrue);
    expect(history.last.reviewCount, 1);
  });
}
