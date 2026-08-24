# WordBucket

**Save the words you meet. Remember the words that matter.**

WordBucket is an Android vocabulary companion designed to keep reading uninterrupted. Instead of leaving a book, article, document, or conversation to search for a definition and then losing your place, you can send a word to WordBucket, read its meaning in a compact sheet, and save it for later review.

The app combines quick word capture, a personal vocabulary collection, gentle reminders, and recall-based practice in a calm, paper-inspired interface.

> WordBucket is currently an Android-first Flutter application. A desktop edition is planned as the next stage of the project, but is not part of this repository yet.

## Why WordBucket?

Looking up an unfamiliar word often means moving from the thing you are reading to a browser or dictionary and then finding your way back. WordBucket shortens that journey:

1. Select or copy an unfamiliar word.
2. Open **Bucketify** from the text menu, Android share menu, or Quick Settings.
3. Read the definition without navigating through a full dictionary app.
4. Save the word to your bucket.
5. Review it later until it becomes familiar.

Some Android apps restrict their selection and sharing menus. In those apps, copy the word and use the **Bucketify Quick Settings tile** instead.

## Features

### Look up and capture words

- Search for a definition from inside WordBucket.
- Get autocomplete suggestions while typing.
- Use **Bucketify** from Android's selected-text actions when the host app supports them.
- Send selected text to WordBucket through Android's share sheet.
- Define the current clipboard word from the optional **Bucketify Quick Settings tile**.
- Retry temporary dictionary failures with a paced fallback lookup.
- See a friendly message when a word is already in the bucket instead of creating a duplicate.
- Receive an in-app confirmation after saving normally and a lightweight Android toast when saving through Bucketify.

Definitions are retrieved from [Free Dictionary API](https://dictionaryapi.dev/), with [Datamuse](https://www.datamuse.com/api/) used as a fallback. An internet connection is required for new lookups. Previously saved words and review history remain in the local database.

### Build a personal word bucket

- Keep a searchable collection of saved words and their definitions.
- Store phonetics, part of speech, example sentences when available, and the date saved.
- Refresh and rotate the featured word.
- Automatically rotate the featured word while the app is active.
- View a saved word's learning history and progress.

### Review and remember

- Practice words that are due for review.
- Reveal each definition before recording whether the word was remembered.
- Schedule future reviews from the result of each attempt.
- Open the relevant review directly by tapping a review notification.
- Track current and longest review streaks.
- Enable a daily due-word reminder.
- Receive a gentle streak reminder around 1 PM when an active streak still needs attention.

Notification delivery never counts as a completed review. Progress changes only after the user records a review result.

### Understand progress

The Progress screen turns review history into useful feedback, including:

- total saved and due words;
- overall recall rate;
- current and longest streaks;
- strongest words and words that need practice;
- mastery groups for new, learning, strong, and struggling words;
- recent review and word-saving activity;
- upcoming, overdue, today, tomorrow, and weekly review workload; and
- per-word review history and strength information.

### Make it feel personal

- System, light, and dark appearance modes.
- Eight paper-inspired palettes: Classic Ink, Forest Journal, Sepia Library, Plum Notebook, Midnight Blue, Monochrome Paper, Rose Petal, and Matcha & Honey.
- A themed Android home-screen widget that rotates through saved words and follows the selected app palette.
- A first-launch walkthrough covering search, Bucketify, Quick Settings, reviews, and widget setup.
- A branded launch experience and launcher icon.

## App structure

WordBucket uses a small layered Flutter architecture:

```text
lib/
├── background/       # Periodic review and streak reminder work
├── core/             # Constants, palettes, and Material themes
├── data/
│   ├── database/     # Drift tables, migrations, and queries
│   ├── models/       # Dictionary and saved-word models
│   └── services/     # Dictionary, suggestions, notifications, and widget sync
├── providers/        # Riverpod state and feature orchestration
├── ui/
│   ├── screens/      # Home, review, progress, settings, launch, and walkthrough
│   └── widgets/      # Reusable word and definition components
├── app.dart          # App theme, navigation entry, intents, and notification taps
└── main.dart         # Flutter and background-worker initialization
```

The Android host in `android/app/src/main/` provides the platform pieces Flutter cannot supply on its own:

- `BucketifyActivity` receives selected or shared text;
- `QuickBucketifyTileService` reads a copied word on explicit user action;
- `WordWidgetProvider` renders and refreshes the home-screen widget; and
- `MainActivity` connects Android platform actions to Flutter.

### Main technologies

- **Flutter and Dart** for the application interface and shared logic
- **Riverpod** for state management and dependency wiring
- **Drift/SQLite** for local words and review history
- **Dio** for dictionary and suggestion requests
- **Workmanager** for periodic Android background work
- **flutter_local_notifications** for review and streak notifications
- **home_widget** for communication with the Android widget
- **SharedPreferences** for appearance and reminder settings

## Getting started

### Requirements

- Flutter stable with a compatible Dart SDK (`pubspec.yaml` currently requires Dart `^3.12.2`)
- Android SDK and accepted Android licenses
- JDK 17 or a compatible Android Studio bundled JDK
- An Android device with USB debugging enabled, or an Android emulator

Check the development environment:

```bash
flutter doctor -v
flutter doctor --android-licenses
```

If Flutter cannot find Java on Linux, point `JAVA_HOME` at the Android Studio runtime for the current terminal session:

```bash
export JAVA_HOME=/snap/android-studio/current/jbr
export PATH="$JAVA_HOME/bin:$PATH"
```

### Run the app

```bash
git clone https://github.com/HenokYoseph01/word-bucket.git
cd word-bucket
flutter pub get
flutter devices
flutter run
```

To target a particular connected device:

```bash
flutter run -d <device-id>
```

You can use hot reload while the debug session is running by pressing `r` in the terminal. Native Android changes—such as widget, manifest, icon, or Quick Settings changes—require a full stop and rebuild rather than hot reload.

### Preview different screen sizes

WordBucket includes an opt-in Device Preview workspace for checking compact,
large, notched, and accessibility-scaled layouts without changing production
behavior. Run it on an Android emulator:

```bash
flutter emulators
flutter emulators --launch <emulator-id>
flutter run -d <device-id> --dart-define=DEVICE_PREVIEW=true
```

Use Device Preview's device and accessibility controls to switch screen size,
orientation, text scale, and safe areas. Omit the `--dart-define` flag for a
normal development run. Device Preview is always disabled in release builds,
and physical-device testing remains necessary for Android overlays, widgets,
notifications, and system text-selection actions.

## Testing

Run static analysis and the automated Flutter tests before creating a release:

```bash
flutter analyze
flutter test
```

The current test suite covers core widget behavior, theme behavior, and definition retry handling. Android integrations should additionally be tested on a physical device because selected-text actions, notifications, Quick Settings, and home-screen widgets depend on the host launcher and Android version.

Useful manual checks include:

1. Search for and save a new word from the app.
2. Trigger a temporary lookup failure and verify the retry/fallback flow.
3. Try saving the same word again and confirm that no duplicate is created.
4. Select a word in another app and choose Bucketify or share it to WordBucket.
5. Copy a word and invoke the Bucketify Quick Settings tile.
6. Complete both remembered and missed review attempts.
7. Tap a review notification and confirm that it opens the relevant word.
8. Change palette and brightness, then confirm that the widget updates too.
9. Leave and reopen the app to verify saved data and preferences persist.

## Building an Android release

The public package version is defined in `pubspec.yaml` using Flutter's `versionName+versionCode` format. Increase both appropriately before publishing an update—for example, `1.0.3+4`.

Release signing is intentionally local. Do not commit a keystore, passwords, or `android/key.properties`. Configure `android/key.properties` on the release machine with the expected signing values:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=YOUR_KEY_ALIAS
storeFile=/absolute/path/to/your-release-key.jks
```

Then build the APK:

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

The output is created at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Verify the artifact before attaching it to a GitHub Release:

```bash
sha256sum build/app/outputs/flutter-apk/app-release.apk
```

Publishing the checksum lets downloaders verify that their APK is byte-for-byte identical to the file produced for the release.

## Data and privacy

- Saved words, review attempts, and learning progress are stored locally on the device.
- Appearance and reminder preferences are stored locally.
- Word lookup and autocomplete text are sent to the configured public dictionary services.
- Quick Bucketify reads the clipboard only when the user explicitly taps the tile; it is not intended to monitor the clipboard continuously.
- WordBucket currently has no account system or cross-device synchronization.

Removing the app normally removes its local application data unless it was preserved by the device's own backup behavior.

## Current platform scope

This repository currently contains Android platform scaffolding. The core Flutter interface, database, and learning logic provide a foundation for a future desktop version, but the following Android experiences will require desktop-native alternatives:

- selected-text Bucketify;
- the Quick Settings tile;
- Android background scheduling; and
- the home-screen widget.

The planned desktop direction is a clipboard-triggered definition popover, global keyboard shortcut, and system-tray companion, beginning with Linux and later expanding to Windows.

## Contributing

Contributions and bug reports are welcome. When reporting an issue, include:

- the WordBucket version;
- Android version and device model;
- clear reproduction steps;
- expected and actual behavior; and
- relevant Flutter or Android logs with private information removed.

Keep changes focused, run `flutter analyze` and `flutter test`, and verify Android-specific behavior on a device before opening a pull request.

## Project status

WordBucket is an independently distributed project currently released through [GitHub Releases](https://github.com/HenokYoseph01/word-bucket/releases). It is actively evolving through real-device testing and user feedback.
