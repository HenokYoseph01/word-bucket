import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../core/constants.dart';
import '../data/database/database.dart';
import '../data/database/word_dao.dart';
import '../data/services/notification_service.dart';

@pragma('vm:entry-point')
void reviewCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();

    if (taskName != reviewTaskName && taskName != streakTaskName) return true;

    final database = AppDatabase();
    try {
      if (await _wasReminderSentToday()) return true;

      final word = await database.getWordDueForReview();
      if (word == null) return true;

      final notifications = NotificationService();
      if (taskName == streakTaskName) {
        final history = await database.getReviewHistory();
        if (_hasReviewedToday(history)) return true;
        final streak = _streakEndingYesterday(history);
        if (streak == 0) return true;
        await notifications.showStreakReminder(word, streak: streak);
      } else {
        await notifications.showReview(word);
      }
      await _markReminderSentToday();
      return true;
    } catch (_) {
      // Returning false asks Android to retry according to WorkManager policy.
      return false;
    } finally {
      await database.close();
    }
  });
}

Future<void> initializeReviewWork() async {
  await Workmanager().initialize(reviewCallbackDispatcher);
  if (await areReviewRemindersEnabled()) {
    await _registerDailyReviewWork();
  } else {
    await Workmanager().cancelByUniqueName(reviewTaskUniqueName);
  }
  if (await areStreakRemindersEnabled()) {
    await _registerDailyStreakWork();
  } else {
    await Workmanager().cancelByUniqueName(streakTaskUniqueName);
  }
}

Future<bool> areReviewRemindersEnabled() async {
  return await SharedPreferencesAsync().getBool(reviewRemindersEnabledKey) ??
      false;
}

Future<void> setReviewRemindersEnabled(bool enabled) async {
  await SharedPreferencesAsync().setBool(reviewRemindersEnabledKey, enabled);
  if (enabled) {
    await _registerDailyReviewWork();
  } else {
    await Workmanager().cancelByUniqueName(reviewTaskUniqueName);
  }
}

Future<bool> areStreakRemindersEnabled() async {
  return await SharedPreferencesAsync().getBool(streakRemindersEnabledKey) ??
      true;
}

Future<void> setStreakRemindersEnabled(bool enabled) async {
  await SharedPreferencesAsync().setBool(streakRemindersEnabledKey, enabled);
  if (enabled) {
    await _registerDailyStreakWork();
  } else {
    await Workmanager().cancelByUniqueName(streakTaskUniqueName);
  }
}

Future<void> _registerDailyReviewWork() {
  return Workmanager().registerPeriodicTask(
    reviewTaskUniqueName,
    reviewTaskName,
    frequency: const Duration(hours: 24),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    constraints: Constraints(networkType: NetworkType.notRequired),
  );
}

Future<void> _registerDailyStreakWork() async {
  // Replace older registrations so reminder-time changes take effect.
  await Workmanager().cancelByUniqueName(streakTaskUniqueName);
  await Workmanager().registerPeriodicTask(
    streakTaskUniqueName,
    streakTaskName,
    frequency: const Duration(hours: 24),
    initialDelay: _delayUntilNextReminder(),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    constraints: Constraints(networkType: NetworkType.notRequired),
  );
}

Duration _delayUntilNextReminder() {
  final now = DateTime.now();
  var nextRun = DateTime(now.year, now.month, now.day, 13);
  if (!nextRun.isAfter(now)) {
    nextRun = nextRun.add(const Duration(days: 1));
  }
  return nextRun.difference(now);
}

bool _hasReviewedToday(List<ReviewAttempt> history) {
  final now = DateTime.now();
  return history.any(
    (attempt) =>
        attempt.reviewedAt.year == now.year &&
        attempt.reviewedAt.month == now.month &&
        attempt.reviewedAt.day == now.day,
  );
}

int _streakEndingYesterday(List<ReviewAttempt> history) {
  final reviewDays = history
      .map(
        (attempt) => DateTime(
          attempt.reviewedAt.year,
          attempt.reviewedAt.month,
          attempt.reviewedAt.day,
        ),
      )
      .toSet();
  final now = DateTime.now();
  var day = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(const Duration(days: 1));
  var streak = 0;
  while (reviewDays.contains(day)) {
    streak++;
    day = day.subtract(const Duration(days: 1));
  }
  return streak;
}

Future<bool> _wasReminderSentToday() async {
  final lastDate = await SharedPreferencesAsync().getString(
    lastReminderDateKey,
  );
  return lastDate == _todayKey();
}

Future<void> _markReminderSentToday() {
  return SharedPreferencesAsync().setString(lastReminderDateKey, _todayKey());
}

String _todayKey() {
  final now = DateTime.now();
  return '${now.year}-${now.month}-${now.day}';
}
