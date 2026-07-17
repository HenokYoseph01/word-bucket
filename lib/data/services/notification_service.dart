import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../database/database.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('ic_notification'),
    );
    await _notifications.initialize(settings: settings);

    const channel = AndroidNotificationChannel(
      'word_reviews',
      'Word reviews',
      description: 'Reminders to review words saved in your bucket',
      importance: Importance.defaultImportance,
    );
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    _isInitialized = true;
  }

  Future<bool> requestPermission() async {
    await initialize();
    return await _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission() ??
        true;
  }

  Future<void> showReview(SavedWord word) async {
    await initialize();

    final example = word.exampleSentence == null
        ? ''
        : '\n\n“${word.exampleSentence}”';
    final body = '${word.partOfSpeech} — ${word.definition}$example';
    final androidDetails = AndroidNotificationDetails(
      'word_reviews',
      'Word reviews',
      channelDescription: 'Reminders to review words saved in your bucket',
      icon: 'ic_notification',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      styleInformation: BigTextStyleInformation(body),
    );
    await _notifications.show(
      id: word.word.hashCode,
      title: 'Review: ${word.word}',
      body: body,
      notificationDetails: NotificationDetails(android: androidDetails),
      payload: word.word,
    );
  }
}
