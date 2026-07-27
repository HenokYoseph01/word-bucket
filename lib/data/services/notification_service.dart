import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../database/database.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  void Function(String word)? _onNotificationTap;

  Future<void> initialize({
    void Function(String word)? onNotificationTap,
  }) async {
    if (onNotificationTap != null) _onNotificationTap = onNotificationTap;
    if (_isInitialized) return;

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('ic_notification'),
    );
    await _notifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        final word = response.payload;
        if (word != null && word.isNotEmpty) _onNotificationTap?.call(word);
      },
    );

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
    const streakChannel = AndroidNotificationChannel(
      'streak_reminders',
      'Streak reminders',
      description: 'Optional reminders to continue your review streak',
      importance: Importance.defaultImportance,
    );
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(streakChannel);

    _isInitialized = true;
  }

  Future<String?> getLaunchWord() async {
    await initialize();
    final details = await _notifications.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp != true) return null;
    return details?.notificationResponse?.payload;
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
      title: 'Tap to review: ${word.word}',
      body: body,
      notificationDetails: NotificationDetails(android: androidDetails),
      payload: word.word,
    );
  }

  Future<void> showStreakReminder(SavedWord word, {required int streak}) async {
    await initialize();

    final body = streak > 0
        ? 'A few words are ready when you are. A quick review keeps your '
              '$streak-day rhythm going.'
        : 'A few words are ready when you are. Take a moment to review.';
    const androidDetails = AndroidNotificationDetails(
      'streak_reminders',
      'Streak reminders',
      channelDescription: 'Optional reminders to continue your review streak',
      icon: 'ic_notification',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    await _notifications.show(
      id: 91827,
      title: 'A little WordBucket moment?',
      body: body,
      notificationDetails: const NotificationDetails(android: androidDetails),
      payload: word.word,
    );
  }
}
