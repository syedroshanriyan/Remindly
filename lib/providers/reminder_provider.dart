import 'dart:async';
import 'package:flutter/material.dart';
import '../core/utils/id_generator.dart';
import '../models/notification_action.dart';
import '../models/recurrence_rule.dart';
import '../models/reminder.dart';
import '../services/hive_service.dart';
import '../services/notification_service.dart';
import '../services/reminder_scheduler.dart';
import '../services/tts_service.dart';

class ReminderProvider extends ChangeNotifier {
  final List<Reminder> _reminders = [];
  final Set<String> _announcedKeys = {};
  Timer? _reminderTicker;

  List<Reminder> get reminders => List.unmodifiable(_reminders);

  ReminderProvider() {
    loadReminders();
    _setupNotificationListener();
    _startActiveReminderMonitor();
  }

  void _setupNotificationListener() {
    NotificationService.onActionReceived =
        (reminderId, action, {notificationId}) {
      handleNotificationAction(reminderId, action,
          notificationId: notificationId);
    };
    NotificationService.onNotificationTapped = (reminderId) {
      final reminder = _reminders.cast<Reminder?>().firstWhere(
            (r) => r?.id == reminderId,
            orElse: () => null,
          );
      if (reminder != null && reminder.voiceEnabled && !reminder.muted) {
        speakReminder(reminder);
      }
    };
  }

  void _startActiveReminderMonitor() {
    _reminderTicker?.cancel();
    // 1-second interval ensures voice trigger fires at the exact moment without delay
    _reminderTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      _checkDueRemindersAndAnnounce();
    });
  }

  void _resetRecurringRemindersIfNeeded() {
    final now = DateTime.now();
    bool changed = false;

    for (int i = 0; i < _reminders.length; i++) {
      final r = _reminders[i];
      if (r.isArchived || r.recurrence == RecurrenceType.none) continue;

      bool shouldReset = false;

      if (r.isCompleted) {
        // Has a new day arrived since it was marked completed?
        if (r.lastCompletedAt != null) {
          final completedDay = DateTime(
            r.lastCompletedAt!.year,
            r.lastCompletedAt!.month,
            r.lastCompletedAt!.day,
          );
          final today = DateTime(now.year, now.month, now.day);
          if (today.isAfter(completedDay)) {
            shouldReset = true;
          }
        } else if (now.isAfter(r.dueDate)) {
          shouldReset = true;
        }
      } else {
        // If not completed, but dueDate is from a previous calendar day, advance to current/next cycle
        final dueDay = DateTime(r.dueDate.year, r.dueDate.month, r.dueDate.day);
        final today = DateTime(now.year, now.month, now.day);
        if (today.isAfter(dueDay) && now.isAfter(r.dueDate)) {
          shouldReset = true;
        }
      }

      if (shouldReset) {
        DateTime nextDue = r.dueDate;
        while (nextDue.isBefore(now)) {
          final next = r.recurrence.nextOccurrence(nextDue);
          if (next == null || next == nextDue) break;
          nextDue = next;
        }

        final updated = r.copyWith(
          dueDate: nextDue,
          isCompleted: false,
          snoozeCount: 0,
          clearLastCompletedAt: true,
        );

        _reminders[i] = updated;
        HiveService.reminderBox.put(updated.id, updated.toMap());
        ReminderScheduler.schedule(updated);
        changed = true;
      }
    }

    if (changed) {
      _sortReminders();
      notifyListeners();
    }
  }

  void _checkDueRemindersAndAnnounce() {
    _resetRecurringRemindersIfNeeded();
    final now = DateTime.now();
    for (final reminder in _reminders) {
      if (!reminder.isCompleted &&
          !reminder.isArchived &&
          reminder.voiceEnabled &&
          !reminder.muted) {
        final diff = now.difference(reminder.dueDate);
        // Trigger immediately at exact due time without delay (within last 10 minutes)
        if (diff.inSeconds >= 0 && diff.inMinutes < 10) {
          final key = '${reminder.id}_${reminder.dueDate.millisecondsSinceEpoch}';
          if (!_announcedKeys.contains(key)) {
            _announcedKeys.add(key);
            TTSService().announceReminder(reminder.title,
                notes: reminder.description, isMuted: reminder.muted);
          }
        }
      }
    }
  }

  void checkDueRemindersNow() {
    _resetRecurringRemindersIfNeeded();
    _checkDueRemindersAndAnnounce();
  }

  Future<void> speakReminder(Reminder reminder) async {
    await TTSService().announceReminder(reminder.title,
        notes: reminder.description, isMuted: reminder.muted);
  }

  void loadReminders() {
    try {
      final stored = HiveService.reminderBox.values.toList();
      _reminders.clear();
      for (final item in stored) {
        try {
          if (item is Map) {
            _reminders.add(Reminder.fromMap(item));
          }
        } catch (_) {}
      }
      _resetRecurringRemindersIfNeeded();
      _sortReminders();
      ReminderScheduler.rescheduleAll(_reminders);
      _checkDueRemindersAndAnnounce();
      notifyListeners();
    } catch (_) {}
  }

  List<Reminder> get activeReminders =>
      _reminders.where((r) => !r.isCompleted && !r.isArchived).toList();

  List<Reminder> get todayReminders {
    final now = DateTime.now();
    return _reminders.where((r) {
      return !r.isCompleted &&
          !r.isArchived &&
          r.dueDate.year == now.year &&
          r.dueDate.month == now.month &&
          r.dueDate.day == now.day;
    }).toList();
  }

  List<Reminder> get upcomingReminders {
    final now = DateTime.now();
    return _reminders.where((r) {
      return !r.isCompleted && !r.isArchived && r.dueDate.isAfter(now);
    }).toList();
  }

  List<Reminder> get completedReminders =>
      _reminders.where((r) => r.isCompleted && !r.isArchived).toList();

  List<Reminder> get archivedReminders =>
      _reminders.where((r) => r.isArchived).toList();

  Reminder? get nextUpcomingReminder {
    final upcoming = upcomingReminders;
    if (upcoming.isEmpty) return null;
    return upcoming.first;
  }

  double get completionProgress {
    final total = _reminders.where((r) => !r.isArchived).length;
    if (total == 0) return 0.0;
    final completed = completedReminders.length;
    return completed / total;
  }

  void addReminder(Reminder reminder) {
    _reminders.add(reminder);
    HiveService.reminderBox.put(reminder.id, reminder.toMap());
    ReminderScheduler.schedule(reminder);
    _sortReminders();
    _checkDueRemindersAndAnnounce();
    notifyListeners();
  }

  void updateReminder(Reminder reminder) {
    final index = _reminders.indexWhere((r) => r.id == reminder.id);
    if (index == -1) return;

    _announcedKeys.removeWhere((k) => k.startsWith('${reminder.id}_'));
    _reminders[index] = reminder;
    HiveService.reminderBox.put(reminder.id, reminder.toMap());
    ReminderScheduler.schedule(reminder);
    _sortReminders();
    _checkDueRemindersAndAnnounce();
    notifyListeners();
  }

  void deleteReminder(String id) {
    _reminders.removeWhere((r) => r.id == id);
    _announcedKeys.removeWhere((k) => k.startsWith('${id}_'));
    HiveService.reminderBox.delete(id);
    ReminderScheduler.cancel(id);
    notifyListeners();
  }

  void completeReminder(String id) {
    final index = _reminders.indexWhere((r) => r.id == id);
    if (index == -1) return;

    final current = _reminders[index];
    current.isCompleted = true;
    current.lastCompletedAt = DateTime.now();
    HiveService.reminderBox.put(current.id, current.toMap());
    ReminderScheduler.cancel(id);
    TTSService().stop();

    // If recurring, pre-schedule next occurrence notification directly with same reminder!
    if (current.recurrence != RecurrenceType.none) {
      final nextDue = current.recurrence.nextOccurrence(current.dueDate);
      if (nextDue != null) {
        final nextOccurrence = current.copyWith(
          dueDate: nextDue,
          isCompleted: false,
          snoozeCount: 0,
        );
        NotificationService.scheduleReminderNotifications(nextOccurrence);
      }
    }

    notifyListeners();
  }

  void toggleReminder(String id) {
    final index = _reminders.indexWhere((r) => r.id == id);
    if (index == -1) return;

    final current = _reminders[index];
    if (current.isCompleted) {
      current.isCompleted = false;
      current.lastCompletedAt = null;
      HiveService.reminderBox.put(current.id, current.toMap());
      ReminderScheduler.schedule(current);
      _checkDueRemindersAndAnnounce();
      notifyListeners();
    } else {
      completeReminder(id);
    }
  }

  void snoozeReminder(String id, {int minutes = 10}) {
    final index = _reminders.indexWhere((r) => r.id == id);
    if (index == -1) return;

    final updated = ReminderScheduler.snooze(_reminders[index], minutes);
    _reminders[index] = updated;
    _announcedKeys.removeWhere((k) => k.startsWith('${id}_')); // Allow re-announcement at snoozed time
    HiveService.reminderBox.put(updated.id, updated.toMap());
    _sortReminders();
    notifyListeners();
  }

  void muteReminder(String id) {
    final index = _reminders.indexWhere((r) => r.id == id);
    if (index == -1) return;

    final current = _reminders[index];
    current.muted = true;
    HiveService.reminderBox.put(current.id, current.toMap());
    notifyListeners();
  }

  void unmuteReminder(String id) {
    final index = _reminders.indexWhere((r) => r.id == id);
    if (index == -1) return;

    final current = _reminders[index];
    current.muted = false;
    HiveService.reminderBox.put(current.id, current.toMap());
    notifyListeners();
  }

  void toggleMute(String id) {
    final index = _reminders.indexWhere((r) => r.id == id);
    if (index == -1) return;

    final current = _reminders[index];
    current.muted = !current.muted;
    HiveService.reminderBox.put(current.id, current.toMap());
    notifyListeners();
  }

  void archiveReminder(String id) {
    final index = _reminders.indexWhere((r) => r.id == id);
    if (index == -1) return;

    _reminders[index].isArchived = true;
    HiveService.reminderBox
        .put(_reminders[index].id, _reminders[index].toMap());
    ReminderScheduler.cancel(id);
    notifyListeners();
  }

  void restoreReminder(String id) {
    final index = _reminders.indexWhere((r) => r.id == id);
    if (index == -1) return;

    _reminders[index].isArchived = false;
    HiveService.reminderBox
        .put(_reminders[index].id, _reminders[index].toMap());
    ReminderScheduler.schedule(_reminders[index]);
    _sortReminders();
    notifyListeners();
  }

  void handleNotificationAction(
      String reminderId, NotificationActionType action,
      {int? notificationId}) {
    String targetId = reminderId;
    if (targetId.isEmpty && notificationId != null) {
      for (final r in _reminders) {
        final baseId = IdGenerator.uuidToNotificationId(r.id);
        if (notificationId == baseId ||
            notificationId == baseId + 1 ||
            notificationId == baseId + 2) {
          targetId = r.id;
          break;
        }
      }
    }

    if (targetId.isEmpty) return;

    if (!_reminders.any((r) => r.id == targetId)) {
      loadReminders();
    }

    switch (action) {
      case NotificationActionType.done:
        completeReminder(targetId);
        TTSService().stop();
        break;
      case NotificationActionType.snooze10:
        snoozeReminder(targetId, minutes: 10);
        TTSService().stop();
        break;
      case NotificationActionType.snooze15:
        snoozeReminder(targetId, minutes: 15);
        TTSService().stop();
        break;
      case NotificationActionType.mute:
        muteReminder(targetId);
        TTSService().stop();
        break;
    }
  }

  void _sortReminders() {
    _reminders.sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  @override
  void dispose() {
    _reminderTicker?.cancel();
    super.dispose();
  }
}
