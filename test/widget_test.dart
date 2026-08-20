import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wordbucket/data/database/database.dart';
import 'package:wordbucket/data/database/word_dao.dart';
import 'package:wordbucket/data/models/word_model.dart';

void main() {
  test('migrates a version-2 word into its first saved meaning', () async {
    final executor = NativeDatabase.memory(
      setup: (database) {
        database.execute('''
          CREATE TABLE words (
            word TEXT NOT NULL PRIMARY KEY,
            phonetic TEXT NULL,
            part_of_speech TEXT NOT NULL,
            definition TEXT NOT NULL,
            example_sentence TEXT NULL,
            saved_at INTEGER NOT NULL,
            review_count INTEGER NOT NULL DEFAULT 0,
            next_review_at INTEGER NULL
          )
        ''');
        database.execute('''
          CREATE TABLE review_attempts (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            word TEXT NOT NULL,
            reviewed_at INTEGER NOT NULL,
            remembered INTEGER NOT NULL,
            review_count INTEGER NOT NULL
          )
        ''');
        database.execute(
          "INSERT INTO words VALUES "
          "('pen', '/pen/', 'noun', 'An instrument used for writing.', "
          "NULL, 1787097600, 3, 1787184000)",
        );
        database.execute(
          "INSERT INTO review_attempts "
          "(word, reviewed_at, remembered, review_count) VALUES "
          "('pen', 1787184000, 1, 3)",
        );
        database.userVersion = 2;
      },
    );
    final database = AppDatabase(executor);
    addTearDown(database.close);

    final meanings = await database.getMeanings('pen');

    expect(meanings, hasLength(1));
    expect(meanings.single.definition, 'An instrument used for writing.');
    expect(meanings.single.partOfSpeech, 'noun');
    expect(meanings.single.reviewCount, 3);
    final history = await database.getReviewHistory();
    expect(history.single.meaningId, meanings.single.id);
  });

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
    final meanings = await database.getMeanings('ephemeral');
    expect(meanings, hasLength(1));
    expect(meanings.single.definition, 'Lasting for a very short time.');
    await database.saveMeaning(
      WordModel(
        word: 'ephemeral',
        partOfSpeech: 'noun',
        definition: 'Something that lasts only briefly.',
        savedAt: DateTime(2026, 7, 17),
      ),
    );
    await database.saveMeaning(
      WordModel(
        word: 'ephemeral',
        partOfSpeech: 'noun',
        definition: 'Something that lasts only briefly.',
        savedAt: DateTime(2026, 7, 18),
      ),
    );
    final twoMeanings = await database.getMeanings('ephemeral');
    expect(twoMeanings, hasLength(2));
    final meaningSnapshot = await database.deleteMeaningWithSnapshot(
      'ephemeral',
      twoMeanings.first.id,
    );
    expect(await database.getMeanings('ephemeral'), hasLength(1));
    expect(
      (await database.getWord('ephemeral'))?.definition,
      'Something that lasts only briefly.',
    );
    await database.restoreDeletedWord(meaningSnapshot!);
    expect(await database.getMeanings('ephemeral'), hasLength(2));

    final wordSnapshot = await database.deleteWordWithSnapshot('ephemeral');
    expect(await database.getWord('ephemeral'), isNull);
    expect(await database.getMeanings('ephemeral'), isEmpty);
    await database.restoreDeletedWord(wordSnapshot!);
    expect(await database.getWord('ephemeral'), isNotNull);
    expect(await database.getMeanings('ephemeral'), hasLength(2));

    final originalMeaning = (await database.getMeanings('ephemeral')).first;
    final otherMeaning = (await database.getMeanings('ephemeral')).last;
    final otherReviewDate = otherMeaning.nextReviewAt;
    final originalReviewDate = originalMeaning.nextReviewAt!;
    await database.recordMeaningReview(
      originalMeaning,
      remembered: true,
      reviewedAt: DateTime(2026, 7, 17),
    );
    final reviewedMeaning = (await database.getMeaning(originalMeaning.id))!;

    expect(reviewedMeaning.reviewCount, 1);
    expect(reviewedMeaning.nextReviewAt!.isAfter(originalReviewDate), isTrue);
    expect(
      (await database.getMeaning(otherMeaning.id))?.nextReviewAt,
      otherReviewDate,
    );

    await database.recordMeaningReview(
      reviewedMeaning,
      remembered: false,
      reviewedAt: DateTime(2026, 7, 18),
    );
    final forgottenMeaning = (await database.getMeaning(originalMeaning.id))!;

    expect(forgottenMeaning.reviewCount, 0);
    expect(
      forgottenMeaning.nextReviewAt!.isBefore(reviewedMeaning.nextReviewAt!),
      isTrue,
    );

    final history = await database.getReviewHistory();
    expect(history, hasLength(2));
    expect(history.first.word, 'ephemeral');
    expect(history.first.remembered, isFalse);
    expect(history.first.reviewCount, 0);
    expect(history.first.meaningId, originalMeaning.id);
    expect(history.last.remembered, isTrue);
    expect(history.last.reviewCount, 1);
  });
}
