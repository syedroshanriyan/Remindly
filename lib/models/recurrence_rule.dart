enum RecurrenceType {
  none,
  daily,
  weekdays,
  weekly,
  monthly,
  yearly;

  static RecurrenceType fromString(String? val) {
    if (val == null) return RecurrenceType.none;
    return RecurrenceType.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => RecurrenceType.none,
    );
  }

  String get displayName {
    switch (this) {
      case RecurrenceType.none:
        return 'Does not repeat';
      case RecurrenceType.daily:
        return 'Every day';
      case RecurrenceType.weekdays:
        return 'Every weekday (Mon-Fri)';
      case RecurrenceType.weekly:
        return 'Every week';
      case RecurrenceType.monthly:
        return 'Every month';
      case RecurrenceType.yearly:
        return 'Every year';
    }
  }

  DateTime? nextOccurrence(DateTime from) {
    switch (this) {
      case RecurrenceType.none:
        return null;
      case RecurrenceType.daily:
        return from.add(const Duration(days: 1));
      case RecurrenceType.weekdays:
        var next = from.add(const Duration(days: 1));
        while (next.weekday == DateTime.saturday ||
            next.weekday == DateTime.sunday) {
          next = next.add(const Duration(days: 1));
        }
        return next;
      case RecurrenceType.weekly:
        return from.add(const Duration(days: 7));
      case RecurrenceType.monthly:
        return DateTime(
          from.year,
          from.month + 1,
          from.day,
          from.hour,
          from.minute,
        );
      case RecurrenceType.yearly:
        return DateTime(
          from.year + 1,
          from.month,
          from.day,
          from.hour,
          from.minute,
        );
    }
  }
}
