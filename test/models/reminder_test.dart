import 'package:flutter_test/flutter_test.dart';
import 'package:remindly/models/recurrence_rule.dart';
import 'package:remindly/models/reminder.dart';

void main() {
  group('Reminder Model Tests', () {
    test('Serialization toMap and deserialization fromMap preserves integrity', () {
      final now = DateTime.now();
      final reminder = Reminder(
        id: 'test-uuid-1234',
        title: 'Doctor Appointment',
        description: 'Bring medical insurance card',
        dueDate: now.add(const Duration(days: 1)),
        isCompleted: false,
        isArchived: false,
        recurrence: RecurrenceType.weekly,
        sourceType: SourceType.voice,
        sourceText: 'remind me tomorrow to visit doctor',
        confidence: 0.96,
        notificationEnabled: true,
        voiceEnabled: true,
        muted: false,
        snoozeCount: 0,
      );

      final map = reminder.toMap();
      final fromMap = Reminder.fromMap(map);

      expect(fromMap.id, equals(reminder.id));
      expect(fromMap.title, equals(reminder.title));
      expect(fromMap.description, equals(reminder.description));
      expect(fromMap.isCompleted, isFalse);
      expect(fromMap.recurrence, equals(RecurrenceType.weekly));
      expect(fromMap.sourceType, equals(SourceType.voice));
      expect(fromMap.confidence, closeTo(0.96, 0.001));
    });

    test('copyWith properly updates specific fields', () {
      final reminder = Reminder(
        id: '123',
        title: 'Original Title',
        dueDate: DateTime.now(),
      );

      final updated = reminder.copyWith(
        title: 'Updated Title',
        isCompleted: true,
        snoozeCount: 2,
      );

      expect(updated.title, equals('Updated Title'));
      expect(updated.isCompleted, isTrue);
      expect(updated.snoozeCount, equals(2));
      expect(updated.id, equals('123'));
    });

    test('fromMap gracefully handles legacy or missing fields', () {
      final legacyMap = {
        'id': 'legacy-1',
        'title': 'Legacy Reminder',
        'description': 'Old description',
        'dueDate': DateTime.now().toIso8601String(),
        'isCompleted': false,
      };

      final reminder = Reminder.fromMap(legacyMap);
      expect(reminder.id, equals('legacy-1'));
      expect(reminder.title, equals('Legacy Reminder'));
      expect(reminder.recurrence, equals(RecurrenceType.none));
      expect(reminder.sourceType, equals(SourceType.manual));
      expect(reminder.snoozeCount, equals(0));
      expect(reminder.remindBeforeMinutes, equals(15));
    });

    test('remindBeforeMinutes defaults to 15 and persists through serialization', () {
      final defaultReminder = Reminder(
        id: 'test-default',
        title: 'Meeting',
        dueDate: DateTime.now(),
      );
      expect(defaultReminder.remindBeforeMinutes, equals(15));

      final customReminder = defaultReminder.copyWith(remindBeforeMinutes: 30);
      expect(customReminder.remindBeforeMinutes, equals(30));

      final map = customReminder.toMap();
      expect(map['remindBeforeMinutes'], equals(30));

      final fromMap = Reminder.fromMap(map);
      expect(fromMap.remindBeforeMinutes, equals(30));
    });
  });
}
