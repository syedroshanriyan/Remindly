import '../core/constants/app_constants.dart';

enum NotificationActionType {
  done,
  snooze10,
  snooze15,
  mute;

  static NotificationActionType? fromId(String? id) {
    if (id == null) return null;
    final normalized = id.trim().toUpperCase();
    switch (normalized) {
      case AppConstants.actionDone:
      case 'DONE':
        return NotificationActionType.done;
      case AppConstants.actionSnooze10:
      case 'ACTION_SNOOZE10':
      case 'SNOOZE_10':
      case 'SNOOZE_10M':
      case 'SNOOZE 10M':
        return NotificationActionType.snooze10;
      case AppConstants.actionSnooze15:
      case 'ACTION_SNOOZE15':
      case 'SNOOZE_15':
      case 'SNOOZE_15M':
      case 'SNOOZE 15M':
        return NotificationActionType.snooze15;
      case AppConstants.actionMute:
      case 'MUTE':
      case 'MUTE_VOICE':
      case 'MUTE VOICE':
      case 'ACTION_MUTE_VOICE':
        return NotificationActionType.mute;
      default:
        return null;
    }
  }

  String get actionId {
    switch (this) {
      case NotificationActionType.done:
        return AppConstants.actionDone;
      case NotificationActionType.snooze10:
        return AppConstants.actionSnooze10;
      case NotificationActionType.snooze15:
        return AppConstants.actionSnooze15;
      case NotificationActionType.mute:
        return AppConstants.actionMute;
    }
  }

  String get label {
    switch (this) {
      case NotificationActionType.done:
        return 'Done';
      case NotificationActionType.snooze10:
        return 'Snooze 10m';
      case NotificationActionType.snooze15:
        return 'Snooze 15m';
      case NotificationActionType.mute:
        return 'Mute';
    }
  }
}
