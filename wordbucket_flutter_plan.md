# WordBucket — Flutter (Android) Project Plan

> **Who this is for:** Someone new to Flutter building their first real-world app.
> Every section explains *what* you're doing and *why*, not just *how*.

---

## What This App Does

WordBucket lets you highlight any word while reading on your phone — in any app —
and instantly get its definition, part of speech, phonetic, and an example sentence.
Words are saved into a personal "bucket" (a local database on your phone).
The app then nudges you to review them over time via notifications and a home screen widget,
so vocabulary actually sticks.

---

## How Flutter + Android Work Together

Flutter is a UI framework written in **Dart**. It compiles to native Android code,
but it lives in its own world — it doesn't automatically know about Android system features
like text selection intents or home screen widgets.

When you need Android to talk to Flutter, you use a **Platform Channel** —
a named pipe that passes messages between Dart and Kotlin.

```
Android System (Kotlin)
        │
        │  Platform Channel ("wordbucket/intent")
        ▼
Flutter App (Dart)
        │
        ├── shows UI (Bottom Sheet)
        ├── calls Dictionary API
        └── saves to local database
```

You will write a small amount of Kotlin (one file, ~60 lines) to catch the Android
text selection event, then hand everything off to Flutter. The rest of the app is
pure Dart.

---

## Architecture Overview

```
User highlights word in any app
          │
          ▼
[Android: MainActivity.kt]
  catches ACTION_PROCESS_TEXT intent
  sends word over Platform Channel
          │
          ▼
[Flutter: main.dart]
  receives word from channel
  triggers DefinitionSheet
          │
          ├── [DictionaryService] → calls Free Dictionary API
          │         │
          │         └── returns WordModel (definition, POS, example)
          │
          ├── [DefinitionSheet widget] → user taps "Save"
          │
          └── [WordRepository] → saves to SQLite via Drift (local DB)

[Home Screen Widget]  ←── reads DB via home_widget package
[Notifications]       ←── flutter_local_notifications + spaced repetition logic
```

---

## Tech Stack

| What | Tool | Why |
|---|---|---|
| Language (app) | Dart | Flutter's language — simple, typed, async-friendly |
| Language (Android bridge) | Kotlin | One file only — catches the text intent |
| UI | Flutter Widgets + Material 3 | Flutter's built-in component system |
| HTTP / API calls | `dio` package | Cleaner than Flutter's built-in `http` for real apps |
| Local database | `drift` package | Type-safe SQLite for Flutter — like Room but in Dart |
| State management | `riverpod` | Clean, testable, beginner-friendly once you get it |
| Home screen widget | `home_widget` package | Lets Flutter update native Android widget data |
| Notifications | `flutter_local_notifications` | Scheduled and custom notifications |
| Background tasks | `workmanager` package | Runs Dart code even when the app is closed |

---

## Flutter Concepts You Will Learn Through This Project

This is your learning roadmap. Each concept is introduced in a specific phase so
you encounter it when it's relevant, not all at once.

### Phase 1 — Widgets & Layout
- Everything in Flutter is a **Widget** (UI building block)
- `StatelessWidget` vs `StatefulWidget` — when UI needs to change vs when it doesn't
- Common layout widgets: `Column`, `Row`, `Padding`, `Expanded`, `SizedBox`
- `Scaffold` — the skeleton of every screen (app bar, body, floating button)
- `MaterialApp` and themes

### Phase 2 — Async Dart
- `Future<T>` — a value that arrives later (like a network response)
- `async` / `await` — how to wait for a Future without freezing the app
- `try / catch` — handling errors gracefully

### Phase 3 — State Management (Riverpod)
- What "state" means — data that can change and trigger UI updates
- `Provider` — a box that holds state and notifies listeners
- `StateNotifier` — a class that manages and mutates state
- `ConsumerWidget` — a widget that reads from a Provider

### Phase 4 — Platform Channels
- How Dart and Kotlin talk to each other
- `MethodChannel` — send a named message and get a reply
- Android `Intent` basics — how Android passes data between apps

### Phase 5 — Local Database (Drift)
- What SQLite is — a file-based database that lives on the device
- Tables, columns, and rows in Drift
- `@DataClass` and `@TableInfo` annotations
- Writing queries in Dart

### Phase 6 — Navigation
- `Navigator.push` / `Navigator.pop` — moving between screens
- Showing a `BottomSheet` — modal overlay on the current screen

### Phase 7 — Packages & Pub.dev
- `pubspec.yaml` — Flutter's dependency file (like `package.json` in JS)
- How to add, version, and use third-party packages

### Phase 8 — Background & Notifications
- `WorkManager` — scheduling tasks that run when the app is closed
- Notification channels and how Android categorizes them
- Spaced repetition logic — a simple algorithm, not a library

---

## Project Setup

### Prerequisites

Install these before starting:

1. **Flutter SDK** — https://docs.flutter.dev/get-started/install/linux (or your OS)
2. **Android Studio** — for the Android emulator and SDK tools
3. **VS Code** with the Flutter extension — your main editor
4. Run `flutter doctor` in your terminal — fix anything it flags

### Create the Project

```bash
flutter create wordbucket
cd wordbucket
```

This generates the full project structure. Open it in VS Code:

```bash
code .
```

### Understanding the Generated Structure

```
wordbucket/
├── android/                  ← Native Android project (you'll edit one file here)
│   └── app/src/main/
│       ├── kotlin/.../MainActivity.kt   ← YOU WILL EDIT THIS
│       └── AndroidManifest.xml          ← YOU WILL EDIT THIS
├── lib/                      ← All your Dart/Flutter code lives here
│   └── main.dart             ← App entry point
├── pubspec.yaml              ← Dependencies (packages)
└── test/                     ← Tests (we'll skip for now)
```

**The golden rule:** 99% of your work happens inside `lib/`. The `android/` folder is
only touched for the platform channel and widget setup.

---

## Phase 1 — Dependencies

Open `pubspec.yaml` and replace the `dependencies` section:

```yaml
dependencies:
  flutter:
    sdk: flutter

  # HTTP requests
  dio: ^5.4.0

  # Local database
  drift: ^2.14.1
  sqlite3_flutter_libs: ^0.5.20
  path_provider: ^2.1.2
  path: ^1.9.0

  # State management
  flutter_riverpod: ^2.4.10
  riverpod_annotation: ^2.3.3

  # Home screen widget
  home_widget: ^0.5.0

  # Notifications + background
  flutter_local_notifications: ^17.0.0
  workmanager: ^0.5.2

  # Utilities
  intl: ^0.19.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  drift_dev: ^2.14.1
  build_runner: ^2.4.8
  riverpod_generator: ^2.3.9
```

Then run:

```bash
flutter pub get
```

This downloads all packages. Think of it like `npm install`.

---

## Phase 2 — Folder Structure

Create this structure inside `lib/`:

```
lib/
├── main.dart
├── app.dart                        ← MaterialApp setup
│
├── core/
│   ├── constants.dart              ← API URLs, channel names, etc.
│   └── theme.dart                  ← App colors and typography
│
├── data/
│   ├── database/
│   │   ├── database.dart           ← Drift DB definition
│   │   ├── database.g.dart         ← Auto-generated (don't edit)
│   │   └── word_dao.dart           ← Database queries
│   │
│   ├── models/
│   │   └── word_model.dart         ← Data class for a word
│   │
│   └── services/
│       └── dictionary_service.dart ← API calls
│
├── providers/
│   ├── word_provider.dart          ← Riverpod state
│   └── word_provider.g.dart        ← Auto-generated
│
└── ui/
    ├── screens/
    │   ├── bucket_screen.dart      ← Main word list
    │   └── word_detail_screen.dart ← Single word expanded view
    │
    └── widgets/
        ├── definition_sheet.dart   ← Bottom sheet shown after highlight
        ├── word_card.dart          ← One word in the list
        └── part_of_speech_badge.dart
```

Create the folders now — files will be filled in each phase:

```bash
mkdir -p lib/core lib/data/database lib/data/models lib/data/services
mkdir -p lib/providers lib/ui/screens lib/ui/widgets
```

---

## Phase 3 — Data Model

**What you're learning:** How to represent data as a Dart class.

Create `lib/data/models/word_model.dart`:

```dart
/// Represents one word and everything we know about it.
/// This is a plain Dart class — no Flutter, no database yet.
class WordModel {
  final String word;
  final String? phonetic;       // e.g. "/ɪˈfɛm.ər.əl/"
  final String partOfSpeech;   // "noun", "verb", "adjective"
  final String definition;
  final String? exampleSentence;
  final DateTime savedAt;
  final int reviewCount;
  final DateTime? nextReviewAt;

  const WordModel({
    required this.word,
    this.phonetic,
    required this.partOfSpeech,
    required this.definition,
    this.exampleSentence,
    required this.savedAt,
    this.reviewCount = 0,
    this.nextReviewAt,
  });
}
```

**Why `?` on some fields:** The `?` means "nullable" — this value might not exist.
Not every word in the API has a phonetic or an example sentence.

---

## Phase 4 — Dictionary API Service

**What you're learning:** `async`/`await`, `Future`, `try/catch`, and using `dio`.

### The API

```
GET https://api.dictionaryapi.dev/api/v2/entries/en/ephemeral
```

Returns a JSON array. You only need the first entry.

Create `lib/data/services/dictionary_service.dart`:

```dart
import 'package:dio/dio.dart';
import '../models/word_model.dart';

class DictionaryService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://api.dictionaryapi.dev/api/v2/entries/en/',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ));

  /// Fetches a word's definition from the Free Dictionary API.
  /// Returns a [WordModel] on success, throws an exception on failure.
  Future<WordModel> define(String word) async {
    try {
      // await pauses here until the network call completes
      final response = await _dio.get(word.toLowerCase().trim());

      // response.data is a List — take the first entry
      final entry = (response.data as List).first;
      final meanings = entry['meanings'] as List;
      final firstMeaning = meanings.first;
      final definitions = firstMeaning['definitions'] as List;
      final firstDef = definitions.first;

      return WordModel(
        word: entry['word'] as String,
        phonetic: entry['phonetic'] as String?,
        partOfSpeech: firstMeaning['partOfSpeech'] as String,
        definition: firstDef['definition'] as String,
        exampleSentence: firstDef['example'] as String?,
        savedAt: DateTime.now(),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('"$word" was not found in the dictionary.');
      }
      throw Exception('Network error. Check your connection.');
    }
  }
}
```

**Key concept — `Future<WordModel>`:** This function doesn't return a `WordModel`
immediately. It returns a *promise* of one. The `async` keyword enables `await`
inside the function. The caller must also `await` it.

---

## Phase 5 — Local Database (Drift)

**What you're learning:** SQLite on-device storage, Drift tables, and DAOs.

### 5.1 Define the Table

Create `lib/data/database/database.dart`:

```dart
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart'; // Auto-generated — run build_runner to create it

/// This class defines the "words" table in SQLite.
/// Each field becomes a column.
class Words extends Table {
  TextColumn get word => text()();                        // PRIMARY KEY set below
  TextColumn get phonetic => text().nullable()();
  TextColumn get partOfSpeech => text()();
  TextColumn get definition => text()();
  TextColumn get exampleSentence => text().nullable()();
  DateTimeColumn get savedAt => dateTime()();
  IntColumn get reviewCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextReviewAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {word};
}

/// The actual database class. @DriftDatabase tells Drift which tables exist.
@DriftDatabase(tables: [Words])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

/// Opens the SQLite file on the device's storage.
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'wordbucket.db'));
    return NativeDatabase.createInBackground(file);
  });
}
```

After creating this file, run:

```bash
flutter pub run build_runner build
```

This generates `database.g.dart` — you never edit that file manually.

### 5.2 Data Access Object (DAO)

Create `lib/data/database/word_dao.dart`:

```dart
import 'package:drift/drift.dart';
import 'database.dart';

/// A DAO (Data Access Object) groups all database operations for Words.
/// Think of it as the "API" for your database.
extension WordDao on AppDatabase {

  /// Insert or replace a word (if word already exists, update it).
  Future<void> saveWord(WordsCompanion word) =>
      into(words).insertOnConflictUpdate(word);

  /// Stream of all words, newest first.
  /// Stream means the UI auto-updates whenever the DB changes.
  Stream<List<Word>> watchAllWords() =>
      (select(words)..orderBy([(w) => OrderingTerm.desc(w.savedAt)])).watch();

  /// Get one word due for review (nextReviewAt is in the past).
  Future<Word?> getWordDueForReview() =>
      (select(words)
        ..where((w) => w.nextReviewAt.isSmallerOrEqualValue(DateTime.now()))
        ..orderBy([(w) => OrderingTerm.random()])
        ..limit(1))
          .getSingleOrNull();

  /// Get a random word (for the home screen widget).
  Future<Word?> getRandomWord() =>
      (select(words)..orderBy([(w) => OrderingTerm.random()])..limit(1))
          .getSingleOrNull();

  /// Delete a word by its text.
  Future<void> deleteWord(String wordText) =>
      (delete(words)..where((w) => w.word.equals(wordText))).go();

  /// Total count of saved words as a stream.
  Stream<int> watchWordCount() =>
      (selectOnly(words)..addColumns([words.word.count()]))
          .map((row) => row.read(words.word.count()) ?? 0)
          .watchSingle();
}
```

**Why `Stream` instead of `Future`?** A `Future` gives you the data once.
A `Stream` keeps sending updates. When you add a word to the DB, the word list
screen automatically refreshes — you don't have to manually reload it.

---

## Phase 6 — State Management (Riverpod)

**What you're learning:** How to share state across widgets without passing data
manually through every layer.

Create `lib/providers/word_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/database.dart';
import '../data/models/word_model.dart';
import '../data/services/dictionary_service.dart';

// ---------------------------------------------------------------------------
// Providers — think of these as global "boxes" that hold state or services.
// Any widget can read from them. When they change, dependent widgets rebuild.
// ---------------------------------------------------------------------------

/// Provides a single shared instance of the database.
final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

/// Provides a single shared instance of the dictionary service.
final dictionaryServiceProvider =
    Provider<DictionaryService>((ref) => DictionaryService());

/// Streams the list of all saved words. Widgets that use this
/// automatically rebuild whenever the database changes.
final allWordsProvider = StreamProvider<List<Word>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllWords();
});

/// Streams the total word count.
final wordCountProvider = StreamProvider<int>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchWordCount();
});

// ---------------------------------------------------------------------------
// WordNotifier — manages the "define and save" action
// ---------------------------------------------------------------------------

/// Holds the state of the current lookup operation.
class LookupState {
  final bool isLoading;
  final WordModel? result;
  final String? error;

  const LookupState({
    this.isLoading = false,
    this.result,
    this.error,
  });

  LookupState copyWith({bool? isLoading, WordModel? result, String? error}) =>
      LookupState(
        isLoading: isLoading ?? this.isLoading,
        result: result ?? this.result,
        error: error ?? this.error,
      );
}

class WordNotifier extends StateNotifier<LookupState> {
  final DictionaryService _service;
  final AppDatabase _db;

  WordNotifier(this._service, this._db) : super(const LookupState());

  /// Fetches the definition of [word] from the API.
  Future<void> lookup(String word) async {
    state = const LookupState(isLoading: true);
    try {
      final result = await _service.define(word);
      state = LookupState(result: result);
    } catch (e) {
      state = LookupState(error: e.toString());
    }
  }

  /// Saves the current lookup result to the database.
  Future<void> saveCurrentWord() async {
    final word = state.result;
    if (word == null) return;

    await _db.saveWord(WordsCompanion.insert(
      word: word.word,
      phonetic: Value(word.phonetic),
      partOfSpeech: word.partOfSpeech,
      definition: word.definition,
      exampleSentence: Value(word.exampleSentence),
      savedAt: word.savedAt,
      nextReviewAt: Value(DateTime.now().add(const Duration(days: 1))),
    ));
  }
}

final wordNotifierProvider =
    StateNotifierProvider<WordNotifier, LookupState>((ref) {
  return WordNotifier(
    ref.watch(dictionaryServiceProvider),
    ref.watch(databaseProvider),
  );
});
```

---

## Phase 7 — Platform Channel (The Android Bridge)

**What you're learning:** How Flutter talks to native Android code.

This is the most unique part of this app. Two files need editing.

### 7.1 AndroidManifest.xml

Open `android/app/src/main/AndroidManifest.xml`.

Add this inside the `<application>` tag, **after** the existing `<activity>` block:

```xml
<!-- This activity handles text selected in other apps -->
<activity
    android:name=".TextReceiverActivity"
    android:label="Define &amp; Save"
    android:theme="@style/Theme.AppCompat.Translucent"
    android:exported="true">
    <intent-filter>
        <action android:name="android.intent.action.PROCESS_TEXT" />
        <category android:name="android.intent.category.DEFAULT" />
        <data android:mimeType="text/plain" />
    </intent-filter>
</activity>
```

Also add this permission near the top of the manifest:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

### 7.2 Create TextReceiverActivity.kt

Create a new file: `android/app/src/main/kotlin/com/yourname/wordbucket/TextReceiverActivity.kt`

```kotlin
package com.yourname.wordbucket  // match your actual package name

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class TextReceiverActivity : FlutterActivity() {

    // This name must exactly match what you use in Dart
    private val CHANNEL = "wordbucket/intent"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Extract the word the user highlighted
        val selectedText = intent
            .getCharSequenceExtra(Intent.EXTRA_PROCESS_TEXT)
            ?.toString()
            ?.trim()
            ?.split("\\s+".toRegex())
            ?.firstOrNull()  // take only the first word if multiple selected
            ?: run { finish(); return }

        // Once Flutter engine is ready, send the word over the channel
        flutterEngine?.let { engine ->
            MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
                .invokeMethod("defineWord", selectedText)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
    }
}
```

### 7.3 Receive the Word in Dart (`main.dart`)

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'ui/widgets/definition_sheet.dart';
import 'providers/word_provider.dart';

// A global navigator key so we can show the bottom sheet from outside widget tree
final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(  // ProviderScope is required for Riverpod
      child: WordBucketApp(),
    ),
  );
}

class WordBucketApp extends ConsumerStatefulWidget {
  const WordBucketApp({super.key});

  @override
  ConsumerState<WordBucketApp> createState() => _WordBucketAppState();
}

class _WordBucketAppState extends ConsumerState<WordBucketApp> {
  // Platform channel — must match the name in Kotlin
  static const _channel = MethodChannel('wordbucket/intent');

  @override
  void initState() {
    super.initState();
    _listenForIntents();
  }

  void _listenForIntents() {
    // This callback fires when Kotlin calls invokeMethod("defineWord", word)
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'defineWord') {
        final word = call.arguments as String;
        _handleIncomingWord(word);
      }
    });
  }

  void _handleIncomingWord(String word) {
    // Trigger the lookup
    ref.read(wordNotifierProvider.notifier).lookup(word);

    // Show the definition bottom sheet
    navigatorKey.currentState?.push(
      ModalBottomSheetRoute(
        builder: (_) => const DefinitionSheet(),
        isScrollControlled: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'WordBucket',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4A90D9)),
        useMaterial3: true,
      ),
      home: const BucketScreen(),
    );
  }
}
```

---

## Phase 8 — UI: Definition Bottom Sheet

**What you're learning:** `StatelessWidget`, `ConsumerWidget`, `BottomSheet` layout,
conditional rendering based on state.

Create `lib/ui/widgets/definition_sheet.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/word_provider.dart';

class DefinitionSheet extends ConsumerWidget {
  const DefinitionSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wordNotifierProvider);

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        // Pushes the sheet above the keyboard
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,  // sheet only as tall as content
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Loading state
          if (state.isLoading) ...[
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 16),
            const Center(child: Text('Looking up definition...')),
          ],

          // Error state
          if (state.error != null) ...[
            const Icon(Icons.error_outline, color: Colors.red, size: 32),
            const SizedBox(height: 8),
            Text(state.error!,
                style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Dismiss'),
              ),
            ),
          ],

          // Success state
          if (state.result != null) ...[
            // Word + phonetic
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  state.result!.word,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (state.result!.phonetic != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    state.result!.phonetic!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 4),

            // Part of speech badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                state.result!.partOfSpeech,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Definition
            Text(
              state.result!.definition,
              style: Theme.of(context).textTheme.bodyLarge,
            ),

            // Example sentence
            if (state.result!.exampleSentence != null) ...[
              const SizedBox(height: 10),
              Text(
                '"${state.result!.exampleSentence}"',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Dismiss'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      await ref
                          .read(wordNotifierProvider.notifier)
                          .saveCurrentWord();
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '"${state.result!.word}" saved to your bucket!'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    child: const Text('Save to Bucket'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
```

---

## Phase 9 — UI: Bucket Screen (Main App)

**What you're learning:** `StreamProvider`, `AsyncValue`, `ListView`, `Dismissible`.

Create `lib/ui/screens/bucket_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/word_provider.dart';
import '../widgets/word_card.dart';

class BucketScreen extends ConsumerWidget {
  const BucketScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // AsyncValue can be: loading, error, or data
    final wordsAsync = ref.watch(allWordsProvider);
    final countAsync = ref.watch(wordCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('WordBucket'),
        actions: [
          // Word count badge
          countAsync.whenData(
            (count) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Chip(label: Text('$count words')),
            ),
          ).value ?? const SizedBox(),
        ],
      ),
      body: wordsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (words) {
          if (words.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.menu_book_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Your bucket is empty.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Highlight a word in any app to get started.',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: words.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final word = words[index];
              return Dismissible(
                key: Key(word.word),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  color: Colors.red,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) {
                  ref.read(databaseProvider).deleteWord(word.word);
                },
                child: WordCard(word: word),
              );
            },
          );
        },
      ),
    );
  }
}
```

---

## Phase 10 — Home Screen Widget

**What you're learning:** How native Android widgets get data from Flutter.

The `home_widget` package works differently from everything else. Flutter can't
draw the widget UI — Android does that with XML. But Flutter can *write data*
that the Android widget reads.

### 10.1 Flutter Side — Update Widget Data

Add this helper anywhere (e.g., in `WordNotifier.saveCurrentWord()`):

```dart
import 'package:home_widget/home_widget.dart';

Future<void> updateHomeWidget(WordModel word) async {
  await HomeWidget.saveWidgetData<String>('word', word.word);
  await HomeWidget.saveWidgetData<String>('partOfSpeech', word.partOfSpeech);
  await HomeWidget.saveWidgetData<String>('definition', word.definition);
  await HomeWidget.updateWidget(
    androidName: 'WordWidgetProvider',  // matches class name you'll create
  );
}
```

Call `updateHomeWidget(word)` inside `saveCurrentWord()` after the DB insert.

### 10.2 Android Widget Layout

Create `android/app/src/main/res/layout/word_widget.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout
    xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:padding="16dp"
    android:background="@drawable/widget_background">

    <TextView
        android:id="@+id/widget_word"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:textSize="20sp"
        android:textStyle="bold"
        android:textColor="#1A1A2E" />

    <TextView
        android:id="@+id/widget_pos"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:textSize="11sp"
        android:textColor="#4A90D9"
        android:layout_marginTop="2dp" />

    <TextView
        android:id="@+id/widget_definition"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:textSize="13sp"
        android:textColor="#444444"
        android:layout_marginTop="8dp"
        android:maxLines="3"
        android:ellipsize="end" />

</LinearLayout>
```

### 10.3 Widget Provider (Kotlin)

Create `android/app/src/main/kotlin/com/yourname/wordbucket/WordWidgetProvider.kt`:

```kotlin
package com.yourname.wordbucket

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class WordWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (widgetId in appWidgetIds) {
            val widgetData = HomeWidgetPlugin.getData(context)

            val word = widgetData.getString("word", "No words yet")
            val pos = widgetData.getString("partOfSpeech", "")
            val definition = widgetData.getString("definition",
                "Highlight a word in any app to get started.")

            val views = RemoteViews(context.packageName, R.layout.word_widget).apply {
                setTextViewText(R.id.widget_word, word)
                setTextViewText(R.id.widget_pos, pos)
                setTextViewText(R.id.widget_definition, definition)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
```

### 10.4 Register Widget in AndroidManifest

```xml
<receiver
    android:name=".WordWidgetProvider"
    android:exported="true">
    <intent-filter>
        <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
    </intent-filter>
    <meta-data
        android:name="android.appwidget.provider"
        android:resource="@xml/word_widget_info" />
</receiver>
```

Create `android/app/src/main/res/xml/word_widget_info.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<appwidget-provider
    xmlns:android="http://schemas.android.com/apk/res/android"
    android:minWidth="250dp"
    android:minHeight="100dp"
    android:updatePeriodMillis="86400000"
    android:resizeMode="horizontal|vertical"
    android:widgetCategory="home_screen" />
```

---

## Phase 11 — Spaced Repetition Notifications

**What you're learning:** WorkManager scheduling, notification channels, simple SR logic.

### 11.1 Notification Channel Setup

In `main()`, before `runApp()`:

```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin notifications =
    FlutterLocalNotificationsPlugin();

Future<void> setupNotifications() async {
  const androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  await notifications.initialize(
    const InitializationSettings(android: androidSettings),
  );

  // Create the notification channel (required on Android 8+)
  const channel = AndroidNotificationChannel(
    'word_review',
    'Word Reviews',
    description: 'Daily reminders to review your saved words',
    importance: Importance.defaultImportance,
  );

  await notifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}
```

### 11.2 Background Worker (WorkManager)

```dart
import 'package:workmanager/workmanager.dart';

// This runs in a separate Dart isolate — no Flutter UI available here.
// Must be a top-level function (not inside a class).
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName == 'wordReview') {
      final db = AppDatabase();
      final word = await db.getWordDueForReview();

      if (word != null) {
        await notifications.show(
          word.word.hashCode,
          'Review: ${word.word}',
          '${word.partOfSpeech} — ${word.definition}',
          NotificationDetails(
            android: AndroidNotificationDetails(
              'word_review',
              'Word Reviews',
              styleInformation: BigTextStyleInformation(
                '${word.partOfSpeech} — ${word.definition}'
                '${word.exampleSentence != null ? '\n\n"${word.exampleSentence}"' : ''}',
              ),
            ),
          ),
        );

        // Update next review time using spaced repetition intervals
        final intervals = [1, 3, 7, 14, 30]; // days
        final next = intervals[word.reviewCount.clamp(0, intervals.length - 1)];

        await db.saveWord(WordsCompanion(
          word: Value(word.word),
          reviewCount: Value(word.reviewCount + 1),
          nextReviewAt: Value(DateTime.now().add(Duration(days: next))),
        ));
      }
    }
    return Future.value(true);
  });
}
```

### 11.3 Register WorkManager

In `main()`:

```dart
await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
await Workmanager().registerPeriodicTask(
  'wordReview',
  'wordReview',
  frequency: const Duration(hours: 24),
  initialDelay: const Duration(hours: 24),
  constraints: Constraints(networkType: NetworkType.not_required),
);
```

---

## Build Order (Step-by-Step)

Follow this order — each step builds on the last and gives you something
testable before moving on.

```
Step 1:  Create Flutter project, add dependencies, run on emulator
Step 2:  Create WordModel — just a Dart class, no setup required
Step 3:  Implement DictionaryService — test it by calling define("hello") in main()
Step 4:  Set up Drift DB — run build_runner, test an insert + read
Step 5:  Set up Riverpod — wire DictionaryService and DB into providers
Step 6:  Build DefinitionSheet — hard-code a fake word first to test the layout
Step 7:  Build BucketScreen — connect it to the allWordsProvider stream
Step 8:  Set up Platform Channel — edit AndroidManifest + MainActivity.kt
         Test: highlight a word in Chrome, tap "Define & Save", see it log
Step 9:  Connect platform channel to DefinitionSheet — full flow working
Step 10: Set up WorkManager + Notifications
Step 11: Set up home_widget — Android XML layout + WordWidgetProvider.kt
```

---

## Common Beginner Mistakes to Avoid

**1. Editing `database.g.dart` manually**
This file is auto-generated. Every time you change `database.dart`, run
`flutter pub run build_runner build` to regenerate it. Your edits will be overwritten.

**2. Forgetting `await`**
If a function is `async`, calls to it usually need `await`. Forgetting it means
you're working with a `Future` object, not the actual value.

**3. Using `setState` with Riverpod**
When using Riverpod, you don't call `setState`. Riverpod's `StateNotifier`
handles re-renders automatically when state changes.

**4. Calling `Navigator.pop()` after the widget is unmounted**
Always check `if (context.mounted)` before using `context` after an `await`.

**5. Package name mismatch in Kotlin**
The package declaration at the top of every `.kt` file must match the package
name in your `AndroidManifest.xml` and your actual folder path.

---

## Running the App

```bash
# Run on connected device or emulator
flutter run

# Build a release APK
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk

# Install directly on connected device
flutter install
```

---

## Debugging Tips

```bash
# See all Flutter logs
flutter logs

# Check for dependency issues
flutter pub deps

# Regenerate Drift code
flutter pub run build_runner build --delete-conflicting-outputs

# Clean build cache if something is wrong
flutter clean && flutter pub get
```

---

## Key Packages Reference

| Package | Pub.dev | What it does |
|---|---|---|
| `dio` | pub.dev/packages/dio | HTTP client for API calls |
| `drift` | pub.dev/packages/drift | Type-safe SQLite database |
| `flutter_riverpod` | pub.dev/packages/flutter_riverpod | State management |
| `home_widget` | pub.dev/packages/home_widget | Flutter ↔ Android widget bridge |
| `flutter_local_notifications` | pub.dev/packages/flutter_local_notifications | In-device notifications |
| `workmanager` | pub.dev/packages/workmanager | Background task scheduling |

---

## What's Different From Native Android

| Concept | Native Android | Flutter Equivalent |
|---|---|---|
| UI components | Jetpack Compose `@Composable` | `Widget` classes |
| Async | `suspend` functions + Coroutines | `async`/`await` + `Future` |
| Reactive streams | `Flow<T>` | `Stream<T>` |
| State management | `ViewModel` + `StateFlow` | `StateNotifier` + Riverpod |
| Local DB | Room | Drift |
| HTTP | Retrofit | Dio |
| DI | Hilt | Riverpod (doubles as DI) |
| Widget (home screen) | Glance API | `home_widget` + native XML |
| Background tasks | WorkManager (Kotlin) | `workmanager` (Dart) |

---

## Summary

The only native Kotlin you write is:
1. `TextReceiverActivity.kt` — catches the text selection intent (~60 lines)
2. `WordWidgetProvider.kt` — reads data and updates widget UI (~30 lines)

Everything else — the API calls, database, state, UI, notifications, background
tasks — is pure Dart inside `lib/`. This is the strength of Flutter for this
project: minimal native code, maximum portability.
