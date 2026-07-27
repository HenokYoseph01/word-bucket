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
}

@DriftDatabase(tables: [Words, ReviewAttempts])
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
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (migrator) => migrator.createAll(),
      onUpgrade: (migrator, from, to) async {
        if (from < 2) {
          await migrator.createTable(reviewAttempts);
        }
      },
    );
  }
}
