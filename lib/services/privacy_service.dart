import 'hive_service.dart';

class PrivacyService {
  static const String zeroCloudGuarantee =
      'Remindly is 100% offline-first. Your diary entries, reminders, voice transcripts, and settings never leave your device. There are no tracking scripts, third-party analytics, remote AI endpoints, or advertising SDKs.';

  static Future<void> deleteAllUserData() async {
    await HiveService.resetAll();
  }

  static Future<void> clearDiaryOnly() async {
    await HiveService.diaryBox.clear();
  }

  static Future<void> clearRemindersOnly() async {
    await HiveService.reminderBox.clear();
  }
}
