import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:remindly/core/constants/app_constants.dart';
import 'package:remindly/models/notification_action.dart';
import 'package:remindly/models/recurrence_rule.dart';
import 'package:remindly/models/reminder.dart';
import 'package:remindly/providers/reminder_provider.dart';
import 'package:remindly/providers/settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('remindly_test_profile_');
    Hive.init(tempDir.path);
    await Hive.openBox(AppConstants.boxSettings);
    await Hive.openBox(AppConstants.boxReminders);
    await Hive.openBox(AppConstants.boxDiaryEntries);
    await Hive.openBox(AppConstants.boxNotificationHistory);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('SettingsProvider Profile Picture & Profile Management Tests', () {
    test('saveProfile persists profileImagePath and user fields in Hive', () {
      final settings = SettingsProvider();

      settings.saveProfile(
        name: 'Elena Rostova',
        email: 'elena@example.com',
        phone: '+1 234 567 8900',
        dob: '1995-04-12',
        gender: 'Female',
        profileImagePath: '/path/to/avatar.png',
      );

      expect(settings.userName, equals('Elena Rostova'));
      expect(settings.userInitial, equals('E'));
      expect(settings.userEmail, equals('elena@example.com'));
      expect(settings.profileImagePath, equals('/path/to/avatar.png'));
      expect(settings.hasCompletedProfile, isTrue);

      // Verify persistence by loading into a new provider instance
      final reloaded = SettingsProvider();
      expect(reloaded.userName, equals('Elena Rostova'));
      expect(reloaded.profileImagePath, equals('/path/to/avatar.png'));
    });

    test('setProfileImage and removeProfileImage properly update state and Hive', () {
      final settings = SettingsProvider();

      settings.setProfileImage('/storage/emulated/0/Pictures/profile.jpg');
      expect(settings.profileImagePath, equals('/storage/emulated/0/Pictures/profile.jpg'));

      settings.removeProfileImage();
      expect(settings.profileImagePath, isEmpty);
    });
  });

  group('ReminderProvider Mute and Action Tests', () {
    test('muteReminder and unmuteReminder properly update reminder state', () {
      final provider = ReminderProvider();
      final reminder = Reminder(
        id: 'rem-mute-test-1',
        title: 'Morning Yoga',
        dueDate: DateTime.now().add(const Duration(minutes: 15)),
        voiceEnabled: true,
        muted: false,
      );

      provider.addReminder(reminder);
      expect(provider.reminders.first.muted, isFalse);

      provider.muteReminder('rem-mute-test-1');
      expect(provider.reminders.first.muted, isTrue);

      provider.unmuteReminder('rem-mute-test-1');
      expect(provider.reminders.first.muted, isFalse);
    });

    test('handleNotificationAction mute executes muteReminder', () {
      final provider = ReminderProvider();
      final reminder = Reminder(
        id: 'rem-action-test-1',
        title: 'Evening Medicine',
        dueDate: DateTime.now().add(const Duration(minutes: 12)),
        voiceEnabled: true,
        muted: false,
      );

      provider.addReminder(reminder);
      provider.handleNotificationAction('rem-action-test-1', NotificationActionType.mute);

      expect(provider.reminders.first.muted, isTrue);
    });

    test('handleNotificationAction done marks reminder complete', () {
      final provider = ReminderProvider();
      final reminder = Reminder(
        id: 'rem-action-done-1',
        title: 'Submit Report',
        dueDate: DateTime.now().add(const Duration(minutes: 10)),
      );

      provider.addReminder(reminder);
      expect(provider.reminders.first.isCompleted, isFalse);

      provider.handleNotificationAction('rem-action-done-1', NotificationActionType.done);
      expect(provider.reminders.first.isCompleted, isTrue);
    });

    test('handleNotificationAction snooze10 extends due date by 10 minutes', () {
      final provider = ReminderProvider();
      final initialDue = DateTime.now().add(const Duration(minutes: 2));
      final reminder = Reminder(
        id: 'rem-action-snooze-1',
        title: 'Team Standup',
        dueDate: initialDue,
      );

      provider.addReminder(reminder);
      provider.handleNotificationAction('rem-action-snooze-1', NotificationActionType.snooze10);

      final updated = provider.reminders.first;
      expect(updated.snoozeCount, equals(1));
      expect(updated.dueDate.isAfter(initialDue), isTrue);
      final diff = updated.dueDate.difference(DateTime.now()).inMinutes;
      expect(diff, inInclusiveRange(9, 10));
    });

    test('handleNotificationAction resolves reminder via notificationId fallback', () {
      final provider = ReminderProvider();
      final reminder = Reminder(
        id: 'rem-action-fallback-1',
        title: 'Call Doctor',
        dueDate: DateTime.now().add(const Duration(minutes: 5)),
      );

      provider.addReminder(reminder);
      provider.handleNotificationAction('rem-action-fallback-1', NotificationActionType.done);
      expect(provider.reminders.first.isCompleted, isTrue);
    });

    test('NotificationActionType IDs match AppConstants and support casing', () {
      expect(NotificationActionType.mute.actionId, equals(AppConstants.actionMute));
      expect(NotificationActionType.snooze15.actionId, equals(AppConstants.actionSnooze15));
      expect(NotificationActionType.snooze10.actionId, equals(AppConstants.actionSnooze10));
      expect(NotificationActionType.done.actionId, equals(AppConstants.actionDone));

      expect(NotificationActionType.fromId('ACTION_DONE'), equals(NotificationActionType.done));
      expect(NotificationActionType.fromId('done'), equals(NotificationActionType.done));
      expect(NotificationActionType.fromId('ACTION_SNOOZE_10'), equals(NotificationActionType.snooze10));
      expect(NotificationActionType.fromId('snooze_10m'), equals(NotificationActionType.snooze10));
      expect(NotificationActionType.fromId('ACTION_MUTE'), equals(NotificationActionType.mute));
      expect(NotificationActionType.fromId('mute voice'), equals(NotificationActionType.mute));
      expect(NotificationActionType.fromId('invalid_action'), isNull);
    });

    test('Daily reminder resets itself for next occurrence when marked done', () {
      final provider = ReminderProvider();
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final dailyReminder = Reminder(
        id: 'daily-meds-1',
        title: 'Take daily meds',
        dueDate: yesterday,
        recurrence: RecurrenceType.daily,
        isCompleted: true,
        lastCompletedAt: yesterday,
      );

      provider.addReminder(dailyReminder);
      provider.checkDueRemindersNow();

      final updated = provider.reminders.firstWhere((r) => r.id == 'daily-meds-1');
      expect(updated.isCompleted, isFalse);
      expect(updated.dueDate.isAfter(yesterday), isTrue);
    });

    test('toggleReminder toggles completion state cleanly', () {
      final provider = ReminderProvider();
      final reminder = Reminder(
        id: 'toggle-test-1',
        title: 'Evening Walk',
        dueDate: DateTime.now().add(const Duration(hours: 2)),
      );

      provider.addReminder(reminder);
      expect(provider.reminders.first.isCompleted, isFalse);

      provider.toggleReminder('toggle-test-1');
      expect(provider.reminders.first.isCompleted, isTrue);

      provider.toggleReminder('toggle-test-1');
      expect(provider.reminders.first.isCompleted, isFalse);
    });
  });
}
