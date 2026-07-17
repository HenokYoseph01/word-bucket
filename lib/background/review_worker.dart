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

    if (taskName != reviewTaskName) return true;

    final database = AppDatabase();
    try {
      final word = await database.getWordDueForReview();

      if (word == null) return true;

      final notifications = NotificationService();
      await notifications.showReview(word);

      await database.advanceReviewSchedule(word);
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

Future<void> _registerDailyReviewWork() {
  return Workmanager().registerPeriodicTask(
    reviewTaskUniqueName,
    reviewTaskName,
    frequency: const Duration(hours: 24),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    constraints: Constraints(networkType: NetworkType.notRequired),
  );
}
