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

@DriftDatabase(tables: [Words])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'wordbucket'));

  @override
  int get schemaVersion => 1;
}
