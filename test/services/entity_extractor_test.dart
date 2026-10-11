import 'package:flutter_test/flutter_test.dart';
import 'package:remindly/models/recurrence_rule.dart';
import 'package:remindly/services/entity_extractor.dart';

void main() {
  group('EntityExtractor Tests', () {
    test('extracts relative duration "in 10 minutes"', () {
      final now = DateTime.now();
      final result = EntityExtractor.extract('in 10 minutes submit project');

      expect(result.dueDate, isNotNull);
      expect(result.hasExplicitTime, isTrue);
      expect(result.dueDate!.difference(now).inMinutes, inInclusiveRange(9, 11));
      expect(result.title.toLowerCase(), contains('submit project'));
    });

    test('extracts relative duration "in 2 hours"', () {
      final now = DateTime.now();
      final result = EntityExtractor.extract('remind me in 2 hours to take tablet');

      expect(result.dueDate, isNotNull);
      expect(result.dueDate!.difference(now).inHours, inInclusiveRange(1, 2));
      expect(result.title.toLowerCase(), contains('take tablet'));
    });

    test('extracts clock time and day "tomorrow at 7 pm"', () {
      final now = DateTime.now();
      final result = EntityExtractor.extract('remind me to call mom tomorrow at 7 pm');

      expect(result.dueDate, isNotNull);
      expect(result.hasExplicitTime, isTrue);
      expect(result.hasExplicitDate, isTrue);
      expect(result.dueDate!.hour, equals(19));
      expect(result.dueDate!.minute, equals(0));
      expect(result.dueDate!.day, equals(now.add(const Duration(days: 1)).day));
      expect(result.title.toLowerCase(), contains('call mom'));
    });

    test('extracts daily recurrence "every day at 8 am"', () {
      final result = EntityExtractor.extract('remind me every day at 8 am to drink water');

      expect(result.recurrence, equals(RecurrenceType.daily));
      expect(result.dueDate?.hour, equals(8));
      expect(result.title.toLowerCase(), contains('drink water'));
    });

    test('extracts weekly recurrence "every week"', () {
      final result = EntityExtractor.extract('every week clean the house');

      expect(result.recurrence, equals(RecurrenceType.weekly));
      expect(result.title.toLowerCase(), contains('clean the house'));
    });

    test('handles input without explicit time gracefully', () {
      final result = EntityExtractor.extract('buy groceries');

      expect(result.hasExplicitTime, isFalse);
      expect(result.title.toLowerCase(), equals('buy groceries'));
    });

    test('extracts space-separated minutes "at 7 55 pm" and cleans title', () {
      final result = EntityExtractor.extract('remind me to call mom at 7 55 pm');

      expect(result.dueDate, isNotNull);
      expect(result.hasExplicitTime, isTrue);
      expect(result.dueDate!.hour, equals(19));
      expect(result.dueDate!.minute, equals(55));
      expect(result.title.toLowerCase(), equals('call mom'));
    });

    test('extracts standalone space-separated "7 55 pm"', () {
      final result = EntityExtractor.extract('7 55 pm');

      expect(result.dueDate, isNotNull);
      expect(result.hasExplicitTime, isTrue);
      expect(result.dueDate!.hour, equals(19));
      expect(result.dueDate!.minute, equals(55));
    });

    test('extracts spoken word minutes "7 fifty five pm" and cleans title', () {
      final result = EntityExtractor.extract('remind me to take medicine at 7 fifty five pm');

      expect(result.dueDate, isNotNull);
      expect(result.hasExplicitTime, isTrue);
      expect(result.dueDate!.hour, equals(19));
      expect(result.dueDate!.minute, equals(55));
      expect(result.title.toLowerCase(), equals('take medicine'));
    });

    test('extracts dot-separated time "at 7.55 am"', () {
      final result = EntityExtractor.extract('meeting tomorrow at 7.55 am');

      expect(result.dueDate, isNotNull);
      expect(result.hasExplicitTime, isTrue);
      expect(result.dueDate!.hour, equals(7));
      expect(result.dueDate!.minute, equals(55));
      expect(result.title.toLowerCase(), equals('meeting'));
    });

    test('extracts relative expression "half past 7 pm"', () {
      final result = EntityExtractor.extract('dinner at half past 7 pm');

      expect(result.dueDate, isNotNull);
      expect(result.hasExplicitTime, isTrue);
      expect(result.dueDate!.hour, equals(19));
      expect(result.dueDate!.minute, equals(30));
      expect(result.title.toLowerCase(), equals('dinner'));
    });

    test('extracts voice input with spaced colon and single digit minute "8 :5 pm today"', () {
      final ref = DateTime(2026, 10, 11, 10, 0); // 10:00 AM
      final result = EntityExtractor.extract('8 :5 pm today', referenceNow: ref);

      expect(result.dueDate, isNotNull);
      expect(result.hasExplicitTime, isTrue);
      expect(result.dueDate!.hour, equals(20)); // 8 PM = 20
      expect(result.dueDate!.minute, equals(5)); // 5 minutes
      expect(result.dueDate!.day, equals(ref.day));
      expect(result.title, equals('Reminder'));
    });

    test('extracts single digit minute "8:5 pm today"', () {
      final ref = DateTime(2026, 10, 11, 10, 0);
      final result = EntityExtractor.extract('8:5 pm today', referenceNow: ref);

      expect(result.dueDate, isNotNull);
      expect(result.hasExplicitTime, isTrue);
      expect(result.dueDate!.hour, equals(20));
      expect(result.dueDate!.minute, equals(5));
      expect(result.title, equals('Reminder'));
    });

    test('extracts voice space-separated "8 5 pm today"', () {
      final ref = DateTime(2026, 10, 11, 10, 0);
      final result = EntityExtractor.extract('8 5 pm today', referenceNow: ref);

      expect(result.dueDate, isNotNull);
      expect(result.hasExplicitTime, isTrue);
      expect(result.dueDate!.hour, equals(20));
      expect(result.dueDate!.minute, equals(5));
    });

    test('extracts "remind me at 8 :5 pm today to call mom" and cleans title', () {
      final ref = DateTime(2026, 10, 11, 10, 0);
      final result = EntityExtractor.extract('remind me at 8 :5 pm today to call mom', referenceNow: ref);

      expect(result.dueDate, isNotNull);
      expect(result.hasExplicitTime, isTrue);
      expect(result.dueDate!.hour, equals(20));
      expect(result.dueDate!.minute, equals(5));
      expect(result.title.toLowerCase(), contains('call mom'));
      expect(result.title.contains('8 :5'), isFalse);
    });

    test('extracts morning single digit minute "8 :5 am today"', () {
      final ref = DateTime(2026, 10, 11, 6, 0); // 6:00 AM
      final result = EntityExtractor.extract('8 :5 am today', referenceNow: ref);

      expect(result.dueDate, isNotNull);
      expect(result.hasExplicitTime, isTrue);
      expect(result.dueDate!.hour, equals(8));
      expect(result.dueDate!.minute, equals(5));
      expect(result.dueDate!.day, equals(ref.day));
    });

    test('extracts speech-to-text dotted "8:05 p.m." as 20:05 PM (never AM)', () {
      final ref = DateTime(2026, 10, 11, 10, 0);
      final result = EntityExtractor.extract('remind me at 8:05 p.m. to take pills', referenceNow: ref);

      expect(result.dueDate, isNotNull);
      expect(result.hasExplicitTime, isTrue);
      expect(result.dueDate!.hour, equals(20)); // 8 PM = 20:00
      expect(result.dueDate!.minute, equals(5));
      expect(result.title.toLowerCase(), contains('take pills'));
      expect(result.title.contains('p.m'), isFalse);
    });

    test('extracts speech-to-text spaced dotted "8 p. m." as 20:00 PM', () {
      final ref = DateTime(2026, 10, 11, 10, 0);
      final result = EntityExtractor.extract('remind me at 8 p. m. to meet alex', referenceNow: ref);

      expect(result.dueDate, isNotNull);
      expect(result.hasExplicitTime, isTrue);
      expect(result.dueDate!.hour, equals(20));
      expect(result.dueDate!.minute, equals(0));
      expect(result.title.toLowerCase(), contains('meet alex'));
    });

    test('extracts "remind me at 8 tonight to call John" as 20:00 PM', () {
      final ref = DateTime(2026, 10, 11, 10, 0);
      final result = EntityExtractor.extract('remind me at 8 tonight to call John', referenceNow: ref);

      expect(result.dueDate, isNotNull);
      expect(result.hasExplicitTime, isTrue);
      expect(result.dueDate!.hour, equals(20));
      expect(result.dueDate!.minute, equals(0));
      expect(result.title.toLowerCase(), contains('call john'));
    });

    test('extracts "remind me at 8 in the morning" as 08:00 AM', () {
      final ref = DateTime(2026, 10, 11, 6, 0);
      final result = EntityExtractor.extract('remind me at 8 in the morning to exercise', referenceNow: ref);

      expect(result.dueDate, isNotNull);
      expect(result.hasExplicitTime, isTrue);
      expect(result.dueDate!.hour, equals(8));
      expect(result.dueDate!.minute, equals(0));
      expect(result.title.toLowerCase(), contains('exercise'));
    });

    test('auto-forwards to tomorrow when time has already passed today and no date specified', () {
      final ref = DateTime(2026, 10, 11, 22, 15); // 10:15 PM
      final result = EntityExtractor.extract('remind me at 8:05 pm to check gates', referenceNow: ref);

      expect(result.dueDate, isNotNull);
      expect(result.hasExplicitTime, isTrue);
      expect(result.dueDate!.hour, equals(20));
      expect(result.dueDate!.minute, equals(5));
      expect(result.dueDate!.day, equals(12)); // Scheduled for tomorrow (Oct 12)
    });
  });
}
