import 'package:home_widget/home_widget.dart';

import '../models/word_model.dart';

class HomeWidgetService {
  static const _providerName = 'WordWidgetProvider';

  Future<void> showWord(WordModel word) async {
    await Future.wait([
      HomeWidget.saveWidgetData<String>('word', word.word),
      HomeWidget.saveWidgetData<String>('partOfSpeech', word.partOfSpeech),
      HomeWidget.saveWidgetData<String>('definition', word.definition),
    ]);

    await HomeWidget.updateWidget(androidName: _providerName);
  }
}
