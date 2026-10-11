import 'package:flutter_test/flutter_test.dart';
import 'package:remindly/models/recurrence_rule.dart';

void main() {
  group('RecurrenceRule Tests', () {
    test('daily recurrence advances by exactly 1 day', () {
      final start = DateTime(2026, 9, 17, 10, 0);
      final next = RecurrenceType.daily.nextOccurrence(start);
      expect(next, equals(DateTime(2026, 9, 18, 10, 0)));
    });

    test('weekly recurrence advances by exactly 7 days', () {
      final start = DateTime(2026, 9, 17, 10, 0);
      final next = RecurrenceType.weekly.nextOccurrence(start);
      expect(next, equals(DateTime(2026, 9, 24, 10, 0)));
    });

    test('monthly recurrence advances to the next month', () {
      final start = DateTime(2026, 9, 17, 10, 0);
      final next = RecurrenceType.monthly.nextOccurrence(start);
      expect(next, equals(DateTime(2026, 10, 17, 10, 0)));
    });

    test('weekdays skips Saturday and Sunday', () {
      // 2026-09-18 is Friday
      final friday = DateTime(2026, 9, 18, 9, 0);
      final next = RecurrenceType.weekdays.nextOccurrence(friday);
      // Next weekday after Friday should be Monday (2026-09-21)
      expect(next!.weekday, equals(DateTime.monday));
      expect(next.day, equals(21));
    });

    test('none recurrence returns null', () {
      final start = DateTime(2026, 9, 17, 10, 0);
      expect(RecurrenceType.none.nextOccurrence(start), isNull);
    });
  });
}
