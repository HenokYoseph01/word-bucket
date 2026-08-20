import 'dart:convert';

import 'package:home_widget/home_widget.dart';

import '../database/database.dart';
import '../database/word_dao.dart';

class HomeWidgetService {
  static const _providerName = 'WordWidgetProvider';

  Future<void> syncFromDatabase(
    AppDatabase database, {
    String? preferredWord,
  }) async {
    final words = await database.watchAllMeanings().first;
    final currentWord = await HomeWidget.getWidgetData<String>('word');
    final selectedWord = preferredWord ?? currentWord;
    var selectedIndex = words.indexWhere((word) => word.word == selectedWord);
    if (selectedIndex < 0) selectedIndex = 0;

    final items = words
        .map(
          (meaning) => {
            'word': meaning.word,
            'partOfSpeech': meaning.partOfSpeech,
            'definition': meaning.definition,
          },
        )
        .toList(growable: false);
    final version = (await HomeWidget.getWidgetData<int>('dataVersion')) ?? 0;

    await Future.wait([
      HomeWidget.saveWidgetData<String>('itemsJson', jsonEncode(items)),
      HomeWidget.saveWidgetData<int>('wordCount', words.length),
      HomeWidget.saveWidgetData<int>('currentIndex', selectedIndex),
      HomeWidget.saveWidgetData<int>('dataVersion', version + 1),
      if (words.isEmpty) ...[
        HomeWidget.saveWidgetData<String>('word', null),
        HomeWidget.saveWidgetData<String>('partOfSpeech', null),
        HomeWidget.saveWidgetData<String>('definition', null),
      ] else ...[
        HomeWidget.saveWidgetData<String>('word', words[selectedIndex].word),
        HomeWidget.saveWidgetData<String>(
          'partOfSpeech',
          words[selectedIndex].partOfSpeech,
        ),
        HomeWidget.saveWidgetData<String>(
          'definition',
          words[selectedIndex].definition,
        ),
      ],
    ]);

    await HomeWidget.updateWidget(androidName: _providerName);
  }
}
