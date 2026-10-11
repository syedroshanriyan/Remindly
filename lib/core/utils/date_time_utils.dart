import 'package:intl/intl.dart';

class DateTimeUtils {
  static final DateFormat _timeFormat = DateFormat('h:mm a');
  static final DateFormat _dateFormat = DateFormat('EEE, MMM d');
  static final DateFormat _fullDateFormat = DateFormat('MMMM d, yyyy');
  static final DateFormat _isoFormat = DateFormat('yyyy-MM-dd HH:mm');

  static String formatTime(DateTime dt) => _timeFormat.format(dt);

  static String formatDate(DateTime dt) {
    if (isToday(dt)) return 'Today';
    if (isTomorrow(dt)) return 'Tomorrow';
    if (isYesterday(dt)) return 'Yesterday';
    return _dateFormat.format(dt);
  }

  static String formatFullDate(DateTime dt) => _fullDateFormat.format(dt);

  static String formatDateTime(DateTime dt) {
    return '${formatDate(dt)} at ${formatTime(dt)}';
  }

  static String formatIso(DateTime dt) => _isoFormat.format(dt);

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool isToday(DateTime dt) {
    return isSameDay(dt, DateTime.now());
  }

  static bool isTomorrow(DateTime dt) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return isSameDay(dt, tomorrow);
  }

  static bool isYesterday(DateTime dt) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(dt, yesterday);
  }

  static bool isPast(DateTime dt) {
    return dt.isBefore(DateTime.now());
  }
}
