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
    await database.advanceReviewSchedule(words.single);
    final reviewedWord = (await database.watchAllWords().first).single;

    expect(reviewedWord.reviewCount, 1);
    expect(reviewedWord.nextReviewAt!.isAfter(originalReviewDate), isTrue);
  });
}
