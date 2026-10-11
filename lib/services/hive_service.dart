import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants/app_constants.dart';

class HiveService {
  static Box get reminderBox => Hive.box(AppConstants.boxReminders);
  static Box get diaryBox => Hive.box(AppConstants.boxDiaryEntries);
  static Box get settingsBox => Hive.box(AppConstants.boxSettings);
  static Box get historyBox => Hive.box(AppConstants.boxNotificationHistory);

  static Future<void> init() async {
    await Hive.initFlutter();

    await Hive.openBox(AppConstants.boxSettings);
    await Hive.openBox(AppConstants.boxReminders);
    await Hive.openBox(AppConstants.boxDiaryEntries);
    await Hive.openBox(AppConstants.boxNotificationHistory);
  }

  static Future<void> clearAllData() async {
    await reminderBox.clear();
    await diaryBox.clear();
    await historyBox.clear();
    // Keep user's onboarding and theme settings unless factory reset requested
  }

  static Future<void> resetAll() async {
    await reminderBox.clear();
    await diaryBox.clear();
    await settingsBox.clear();
    await historyBox.clear();
  }
}
