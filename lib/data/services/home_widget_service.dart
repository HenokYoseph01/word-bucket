import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';

import '../database/database.dart';
import '../database/word_dao.dart';
import '../models/word_model.dart';

class HomeWidgetService {
  static const _providerName = 'WordWidgetProvider';

  Future<void> showWord(WordModel word) {
    return _show(
      word: word.word,
      partOfSpeech: word.partOfSpeech,
      definition: word.definition,
    );
  }

  Future<void> showSavedWord(SavedWord word) {
    return _show(
      word: word.word,
      partOfSpeech: word.partOfSpeech,
      definition: word.definition,
    );
  }

  Future<void> syncFromDatabase(AppDatabase database) async {
    final currentWord = await HomeWidget.getWidgetData<String>('word');
    final word =
        await database.getRandomWord(excluding: currentWord) ??
        await database.getRandomWord();
    if (word == null) {
      await clear();
    } else {
      await showSavedWord(word);
    }
  }

  Future<void> clear() async {
    await Future.wait([
      HomeWidget.saveWidgetData<String>('word', null),
      HomeWidget.saveWidgetData<String>('partOfSpeech', null),
      HomeWidget.saveWidgetData<String>('definition', null),
    ]);
    await _update();
  }

  Future<void> _show({
    required String word,
    required String partOfSpeech,
    required String definition,
  }) async {
    await Future.wait([
      HomeWidget.saveWidgetData<String>('word', word),
      HomeWidget.saveWidgetData<String>('partOfSpeech', partOfSpeech),
      HomeWidget.saveWidgetData<String>('definition', definition),
    ]);
    await _update();
  }

  Future<void> _update() {
    return HomeWidget.updateWidget(androidName: _providerName);
  }
}

Future<void> initializeHomeWidget() async {
  await HomeWidget.registerInteractivityCallback(homeWidgetCallback);
}

@pragma('vm:entry-point')
Future<void> homeWidgetCallback(Uri? uri) async {
  if (uri?.host != 'refresh') return;

  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  final database = AppDatabase();
  try {
    await HomeWidgetService().syncFromDatabase(database);
  } finally {
    await database.close();
  }
}
