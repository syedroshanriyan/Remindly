class AppConstants {
  static const String appName = 'Remindly';
  static const String appTagline = 'Never miss what matters';
  static const String appVersion = '1.0.0';

  // Hive Box Names
  static const String boxReminders = 'reminders';
  static const String boxDiaryEntries = 'diary_entries';
  static const String boxSettings = 'settings';
  static const String boxNotificationHistory = 'notification_history';

  // Settings Keys
  static const String keyTheme = 'theme';
  static const String keyVoiceAnnouncement = 'voice_announcement';
  static const String keyTtsSpeechRate = 'tts_speech_rate';
  static const String keySoundEnabled = 'sound_enabled';
  static const String keyVibrationEnabled = 'vibration_enabled';
  static const String keyHasSeenOnboarding = 'has_seen_onboarding';
  static const String keyAppLockEnabled = 'app_lock_enabled';
  static const String keyAppLockMode = 'app_lock_mode';
  static const String keyAppLockPassword = 'app_lock_password';
  static const String lockModeDevice = 'device';
  static const String lockModeCustomPassword = 'custom_password';

  // Notification Channel
  static const String notificationChannelId = 'remindly_channel_reminders';
  static const String notificationChannelName = 'Reminders';
  static const String notificationChannelDesc =
      'Intelligent reminder notifications and alarms';

  // Notification Action Identifiers
  static const String actionDone = 'ACTION_DONE';
  static const String actionSnooze10 = 'ACTION_SNOOZE_10';
  static const String actionSnooze15 = 'ACTION_SNOOZE_15';
  static const String actionMute = 'ACTION_MUTE';

  // ML Confidence Thresholds per Master Prompt Section 11
  static const double confidenceThresholdAuto = 0.85;
  static const double confidenceThresholdConfirm = 0.60;

  // Snooze Durations in minutes
  static const int defaultSnooze10 = 10;
  static const int defaultSnooze15 = 15;
}
