import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

@DataClassName('SavedWord')
class Words extends Table {
  TextColumn get word => text()();
  TextColumn get phonetic => text().nullable()();
  TextColumn get partOfSpeech => text()();
  TextColumn get definition => text()();
  TextColumn get exampleSentence => text().nullable()();
  DateTimeColumn get savedAt => dateTime()();
  IntColumn get reviewCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextReviewAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {word};
}

@DataClassName('ReviewAttempt')
class ReviewAttempts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get word => text()();
  DateTimeColumn get reviewedAt => dateTime()();
  BoolColumn get remembered => boolean()();
  IntColumn get reviewCount => integer()();
  IntColumn get meaningId => integer().nullable()();
}

@DataClassName('SavedMeaning')
class SavedMeanings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get word => text()();
  TextColumn get phonetic => text().nullable()();
  TextColumn get partOfSpeech => text()();
  TextColumn get definition => text()();
  TextColumn get exampleSentence => text().nullable()();
  DateTimeColumn get savedAt => dateTime()();
  IntColumn get reviewCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextReviewAt => dateTime().nullable()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {word, definition},
  ];
}

@DriftDatabase(tables: [Words, ReviewAttempts, SavedMeanings])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(
        executor ??
            driftDatabase(
              name: 'wordbucket',
              native: const DriftNativeOptions(shareAcrossIsolates: true),
            ),
      );

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (migrator) => migrator.createAll(),
      onUpgrade: (migrator, from, to) async {
        if (from < 2) {
          await migrator.createTable(reviewAttempts);
        }
        if (from < 3) {
          await migrator.createTable(savedMeanings);
          await customStatement('''
            INSERT OR IGNORE INTO saved_meanings
              (word, phonetic, part_of_speech, definition, example_sentence, saved_at,
               review_count, next_review_at)
            SELECT word, phonetic, part_of_speech, definition, example_sentence, saved_at,
                   review_count, next_review_at
            FROM words
          ''');
        }
        if (from >= 3 && from < 4) {
          await migrator.addColumn(savedMeanings, savedMeanings.phonetic);
          await customStatement('''
            UPDATE saved_meanings
            SET phonetic = (
              SELECT words.phonetic FROM words
              WHERE words.word = saved_meanings.word
            )
          ''');
        }
        if (from >= 2 && from < 4) {
          await migrator.addColumn(reviewAttempts, reviewAttempts.meaningId);
        }
        if (from < 4) {
          await customStatement('''
            UPDATE review_attempts
            SET meaning_id = (
              SELECT sm.id
              FROM saved_meanings sm
              JOIN words w ON w.word = sm.word
              WHERE sm.word = review_attempts.word
              ORDER BY CASE WHEN sm.definition = w.definition THEN 0 ELSE 1 END,
                       sm.saved_at ASC
              LIMIT 1
            )
            WHERE meaning_id IS NULL
          ''');
        }
      },
    );
  }
}
