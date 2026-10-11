import '../models/reminder.dart';
import 'notification_service.dart';

class ReminderScheduler {
  static Future<void> schedule(Reminder reminder) async {
    try {
      await NotificationService.cancelReminderNotifications(reminder.id);
      if (!reminder.isCompleted &&
          !reminder.isArchived &&
          reminder.notificationEnabled) {
        await NotificationService.scheduleReminderNotifications(reminder);
      }
    } catch (_) {}
  }

  static Future<void> cancel(String reminderId) async {
    await NotificationService.cancelReminderNotifications(reminderId);
  }

  static Future<void> rescheduleAll(List<Reminder> reminders) async {
    await NotificationService.cancelAllNotifications();
    final now = DateTime.now();
    for (final reminder in reminders) {
      if (!reminder.isCompleted &&
          !reminder.isArchived &&
          reminder.dueDate.isAfter(now)) {
        await NotificationService.scheduleReminderNotifications(reminder);
      }
    }
  }

  static Reminder snooze(Reminder reminder, int minutes) {
    final newDueDate = DateTime.now().add(Duration(minutes: minutes));
    final updated = reminder.copyWith(
      dueDate: newDueDate,
      snoozeCount: reminder.snoozeCount + 1,
      isCompleted: false,
    );
    NotificationService.cancelReminderNotifications(reminder.id);
    NotificationService.scheduleReminderNotifications(updated);
    return updated;
  }

  static Reminder mute(Reminder reminder) {
    return reminder.copyWith(muted: true);
  }
}
