import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../core/constants/app_constants.dart';
import '../core/utils/id_generator.dart';
import '../models/notification_action.dart';
import '../models/recurrence_rule.dart';
import '../models/reminder.dart';
import 'tts_service.dart';

@pragma('vm:entry-point')
Future<void> notificationTapBackground(
    NotificationResponse notificationResponse) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Try to forward to the active main UI isolate first
  final sendPort =
      IsolateNameServer.lookupPortByName(NotificationService.portName);
  if (sendPort != null) {
    sendPort.send({
      'reminderId': notificationResponse.payload,
      'actionId': notificationResponse.actionId,
      'notificationId': notificationResponse.id,
    });
    return;
  }

  // App was killed/terminated: execute action directly in this background isolate
  await NotificationService.handleActionResponse(notificationResponse);
}

class NotificationService {
  static const String portName = 'remindly_notification_action_port';
  static ReceivePort? _actionReceivePort;

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Function(String reminderId, NotificationActionType action,
      {int? notificationId})? onActionReceived;
  static Function(String reminderId)? onNotificationTapped;

  static bool _timezonesInitialized = false;
  static String? _lastActionKey;
  static DateTime? _lastActionTime;

  static Future<void> _ensureTimezonesInitialized() async {
    if (_timezonesInitialized) return;
    try {
      tz.initializeTimeZones();
      try {
        final timezone = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(timezone));
      } catch (_) {
        try {
          tz.setLocalLocation(tz.getLocation('UTC'));
        } catch (_) {
          tz.setLocalLocation(tz.UTC);
        }
      }
      _timezonesInitialized = true;
    } catch (_) {}
  }

  static tz.Location get _tzLocation {
    try {
      return tz.local;
    } catch (_) {
      try {
        tz.initializeTimeZones();
        return tz.getLocation('UTC');
      } catch (_) {
        return tz.UTC;
      }
    }
  }

  static void _setupPortCommunication() {
    _actionReceivePort?.close();
    _actionReceivePort = ReceivePort();
    IsolateNameServer.removePortNameMapping(portName);
    IsolateNameServer.registerPortWithName(
      _actionReceivePort!.sendPort,
      portName,
    );

    _actionReceivePort!.listen((message) {
      if (message is Map) {
        final reminderId = message['reminderId']?.toString();
        final actionId = message['actionId']?.toString();
        final notificationId = message['notificationId'] as int?;
        if (actionId != null) {
          _handlePortMessage(reminderId, actionId, notificationId);
        } else if (reminderId != null && reminderId.isNotEmpty) {
          onNotificationTapped?.call(reminderId);
        }
      }
    });
  }

  static bool _shouldDebounce(String reminderId, String actionId) {
    final key = '$reminderId:$actionId';
    final now = DateTime.now();
    if (_lastActionKey == key &&
        _lastActionTime != null &&
        now.difference(_lastActionTime!).inMilliseconds < 1500) {
      return true;
    }
    _lastActionKey = key;
    _lastActionTime = now;
    return false;
  }

  static Future<void> _handlePortMessage(
      String? reminderId, String actionId, int? notificationId) async {
    final actionType = NotificationActionType.fromId(actionId);
    if (actionType == null) return;

    final effectiveId = reminderId ?? '';
    if (effectiveId.isNotEmpty && _shouldDebounce(effectiveId, actionId)) {
      return;
    }

    if (onActionReceived != null) {
      onActionReceived!(effectiveId, actionType, notificationId: notificationId);
    } else {
      await _executeDirectAction(reminderId, actionType,
          notificationId: notificationId);
    }
  }

  static Future<void> initialize() async {
    await _ensureTimezonesInitialized();
    _setupPortCommunication();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          'remindly_reminder_category',
          actions: [
            DarwinNotificationAction.plain(AppConstants.actionDone, 'Done'),
            DarwinNotificationAction.plain(
                AppConstants.actionSnooze10, 'Snooze 10m'),
            DarwinNotificationAction.plain(
                AppConstants.actionMute, 'Mute Voice'),
          ],
        ),
      ],
    );

    final settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        handleActionResponse(response);
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    if (Platform.isAndroid) {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        const channel = AndroidNotificationChannel(
          AppConstants.notificationChannelId,
          AppConstants.notificationChannelName,
          description: AppConstants.notificationChannelDesc,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          showBadge: true,
        );
        await androidPlugin.createNotificationChannel(channel);
      }
    }

    final launchDetails =
        await _notifications.getNotificationAppLaunchDetails();
    if (launchDetails != null &&
        launchDetails.didNotificationLaunchApp &&
        launchDetails.notificationResponse != null) {
      handleActionResponse(launchDetails.notificationResponse!);
    }

    await _requestPermissions();
  }

  static Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final android = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
      try {
        await android?.requestExactAlarmsPermission();
      } catch (_) {}
    } else if (Platform.isIOS) {
      final ios = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  static Future<void> handleActionResponse(
      NotificationResponse response) async {
    final actionId = response.actionId;
    if (actionId == null) {
      // User tapped notification body
      final reminderId = response.payload;
      if (reminderId != null && reminderId.isNotEmpty) {
        onNotificationTapped?.call(reminderId);
      }
      return;
    }

    final actionType = NotificationActionType.fromId(actionId);
    if (actionType == null) return;

    final reminderId = response.payload;
    final notificationId = response.id;

    if (reminderId != null &&
        reminderId.isNotEmpty &&
        _shouldDebounce(reminderId, actionId)) {
      return;
    }

    if (onActionReceived != null) {
      onActionReceived!(reminderId ?? '', actionType,
          notificationId: notificationId);
    } else {
      await _executeDirectAction(reminderId, actionType,
          notificationId: notificationId);
    }
  }

  static Reminder? _findReminder(
      Box box, String? reminderId, int? notificationId) {
    if (reminderId != null && reminderId.isNotEmpty) {
      final raw = box.get(reminderId);
      if (raw != null && raw is Map) {
        return Reminder.fromMap(raw);
      }
    }
    for (final val in box.values) {
      if (val is Map) {
        final r = Reminder.fromMap(val);
        if (reminderId != null && r.id == reminderId) return r;
        if (notificationId != null) {
          final baseId = IdGenerator.uuidToNotificationId(r.id);
          if (notificationId == baseId ||
              notificationId == baseId + 1 ||
              notificationId == baseId + 2) {
            return r;
          }
        }
      }
    }
    return null;
  }

  static Future<void> _executeDirectAction(
      String? reminderId, NotificationActionType action,
      {int? notificationId}) async {
    try {
      await _ensureTimezonesInitialized();
      await Hive.initFlutter();

      Box box;
      if (Hive.isBoxOpen(AppConstants.boxReminders)) {
        box = Hive.box(AppConstants.boxReminders);
      } else {
        box = await Hive.openBox(AppConstants.boxReminders);
      }

      final reminder = _findReminder(box, reminderId, notificationId);
      if (reminder == null) return;

      switch (action) {
        case NotificationActionType.done:
          final updated = reminder.copyWith(
            isCompleted: true,
            lastCompletedAt: DateTime.now(),
          );
          await box.put(updated.id, updated.toMap());
          await cancelReminderNotifications(updated.id);
          if (notificationId != null) {
            try {
              await _notifications.cancel(notificationId);
            } catch (_) {}
          }
          try {
            await TTSService().stop();
          } catch (_) {}

          // If recurring, pre-schedule next occurrence notification so it fires on time even if app is closed!
          if (updated.recurrence != RecurrenceType.none) {
            final nextDue = updated.recurrence.nextOccurrence(updated.dueDate);
            if (nextDue != null) {
              final nextOccurrence = updated.copyWith(
                dueDate: nextDue,
                isCompleted: false,
                snoozeCount: 0,
              );
              await scheduleReminderNotifications(nextOccurrence);
            }
          }
          break;

        case NotificationActionType.snooze10:
          final updated10 = reminder.copyWith(
            dueDate: DateTime.now().add(const Duration(minutes: 10)),
            snoozeCount: reminder.snoozeCount + 1,
            isCompleted: false,
          );
          await box.put(updated10.id, updated10.toMap());
          await cancelReminderNotifications(updated10.id);
          if (notificationId != null) {
            try {
              await _notifications.cancel(notificationId);
            } catch (_) {}
          }
          try {
            await TTSService().stop();
          } catch (_) {}
          await scheduleReminderNotifications(updated10);
          break;

        case NotificationActionType.snooze15:
          final updated15 = reminder.copyWith(
            dueDate: DateTime.now().add(const Duration(minutes: 15)),
            snoozeCount: reminder.snoozeCount + 1,
            isCompleted: false,
          );
          await box.put(updated15.id, updated15.toMap());
          await cancelReminderNotifications(updated15.id);
          if (notificationId != null) {
            try {
              await _notifications.cancel(notificationId);
            } catch (_) {}
          }
          try {
            await TTSService().stop();
          } catch (_) {}
          await scheduleReminderNotifications(updated15);
          break;

        case NotificationActionType.mute:
          final updatedMute = reminder.copyWith(muted: true);
          await box.put(updatedMute.id, updatedMute.toMap());
          try {
            await TTSService().stop();
          } catch (_) {}
          break;
      }
    } catch (e) {
      debugPrint('Notification executeDirectAction error: $e');
    }
  }

  static NotificationDetails _notificationDetails(
      {required String reminderId}) {
    final actions = [
      AndroidNotificationAction(
        AppConstants.actionDone,
        'Done',
        showsUserInterface: false,
        cancelNotification: true,
      ),
      AndroidNotificationAction(
        AppConstants.actionSnooze10,
        'Snooze 10m',
        showsUserInterface: false,
        cancelNotification: true,
      ),
      AndroidNotificationAction(
        AppConstants.actionMute,
        'Mute Voice',
        showsUserInterface: false,
        cancelNotification: false,
      ),
      AndroidNotificationAction(
        AppConstants.actionSnooze15,
        'Snooze 15m',
        showsUserInterface: false,
        cancelNotification: true,
      ),
    ];

    final android = AndroidNotificationDetails(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      channelDescription: AppConstants.notificationChannelDesc,
      importance: Importance.max,
      priority: Priority.max,
      actions: actions,
      category: AndroidNotificationCategory.alarm,
      enableVibration: true,
      playSound: true,
      autoCancel: true,
      visibility: NotificationVisibility.public,
      ticker: 'Reminder',
    );

    const darwin = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: 'remindly_reminder_category',
    );

    return NotificationDetails(android: android, iOS: darwin);
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _notifications.show(
      id,
      title,
      body,
      _notificationDetails(reminderId: payload ?? ''),
      payload: payload,
    );
  }

  static Future<void> scheduleReminderNotifications(Reminder reminder) async {
    if (!reminder.notificationEnabled || reminder.isArchived) {
      return;
    }

    DateTime targetDueDate = reminder.dueDate;
    // If recurring reminder is marked completed for today, schedule its next occurrence!
    if (reminder.isCompleted) {
      if (reminder.recurrence != RecurrenceType.none) {
        final next = reminder.recurrence.nextOccurrence(reminder.dueDate);
        if (next != null) {
          targetDueDate = next;
        } else {
          return;
        }
      } else {
        return;
      }
    }

    final now = DateTime.now();
    final baseId = IdGenerator.uuidToNotificationId(reminder.id);

    // 1 Day Before
    final oneDayBefore = targetDueDate.subtract(const Duration(days: 1));
    if (oneDayBefore.isAfter(now)) {
      await _schedule(
        id: baseId + 1,
        dateTime: oneDayBefore,
        title: 'Tomorrow: ${reminder.title}',
        body: reminder.description.isNotEmpty
            ? reminder.description
            : 'Scheduled for tomorrow',
        payload: reminder.id,
      );
    }

    // Configurable Prior Notification (Default 15 minutes before event)
    final priorMinutes = reminder.remindBeforeMinutes;
    if (priorMinutes > 0 && priorMinutes != 1440) {
      final priorTime = targetDueDate.subtract(Duration(minutes: priorMinutes));
      if (priorTime.isAfter(now)) {
        final timeLabel = priorMinutes >= 60
            ? (priorMinutes % 60 == 0
                ? '${priorMinutes ~/ 60}h'
                : '$priorMinutes mins')
            : '$priorMinutes mins';
        await _schedule(
          id: baseId + 2,
          dateTime: priorTime,
          title: 'Upcoming in $timeLabel: ${reminder.title}',
          body:
              'Upcoming voice announcement. Tap Mute Voice to silence or Snooze to delay.',
          payload: reminder.id,
        );
      }
    }

    // Exactly at Due Date
    if (targetDueDate.isAfter(now)) {
      await _schedule(
        id: baseId,
        dateTime: targetDueDate,
        title: 'Reminder: ${reminder.title}',
        body: reminder.description.isNotEmpty
            ? reminder.description
            : 'Scheduled for right now',
        payload: reminder.id,
      );
    } else if (now.difference(targetDueDate).inSeconds.abs() <= 60 &&
        !reminder.isCompleted) {
      await showNotification(
        id: baseId,
        title: 'Reminder: ${reminder.title}',
        body: reminder.description.isNotEmpty
            ? reminder.description
            : 'Scheduled for right now',
        payload: reminder.id,
      );
    }
  }

  static Future<void> _schedule({
    required int id,
    required DateTime dateTime,
    required String title,
    required String body,
    required String payload,
  }) async {
    try {
      final now = DateTime.now();
      if (dateTime.isBefore(now)) {
        if (now.difference(dateTime).inSeconds <= 60) {
          await showNotification(
            id: id,
            title: title,
            body: body,
            payload: payload,
          );
        }
        return;
      }

      final location = _tzLocation;
      final tzDateTime = tz.TZDateTime.from(dateTime, location);

      try {
        await _notifications.zonedSchedule(
          id,
          title,
          body,
          tzDateTime,
          _notificationDetails(reminderId: payload),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: payload,
        );
      } catch (_) {
        // Fallback to inexact if exact alarms permission is not granted on certain devices
        await _notifications.zonedSchedule(
          id,
          title,
          body,
          tzDateTime,
          _notificationDetails(reminderId: payload),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: payload,
        );
      }
    } catch (_) {
      // Gracefully ignore headless unit test platform channel absence
    }
  }

  static Future<void> cancelReminderNotifications(String reminderId) async {
    try {
      final baseId = IdGenerator.uuidToNotificationId(reminderId);
      await _notifications.cancel(baseId);
      await _notifications.cancel(baseId + 1);
      await _notifications.cancel(baseId + 2);
    } catch (_) {}
  }

  static Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
    } catch (_) {}
  }
}
