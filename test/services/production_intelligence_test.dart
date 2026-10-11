import 'package:flutter_test/flutter_test.dart';
import 'package:remindly/models/parsed_input.dart';
import 'package:remindly/models/recurrence_rule.dart';
import 'package:remindly/models/reminder.dart';
import 'package:remindly/services/command_parser.dart';
import 'package:remindly/services/entity_extractor.dart';
import 'package:remindly/services/reminder_scheduler.dart';

void main() {
  group('Production Intelligence Test Suite (Section 40 Mandatory Cases)', () {
    late CommandParser parser;
    final fixedNow = DateTime(2026, 9, 20, 10, 0); // 10:00 AM Sunday

    setUp(() {
      parser = CommandParser();
    });

    test('1. "remind me tomorrow at 7 pm to call mom"', () {
      final res = parser.parse('remind me tomorrow at 7 pm to call mom', referenceNow: fixedNow);
      expect(res.intent, equals(IntentType.reminder));
      expect(res.title.toLowerCase(), contains('call mom'));
      expect(res.dueDate, isNotNull);
      expect(res.dueDate!.hour, equals(19));
      expect(res.dueDate!.minute, equals(0));
    });

    test('2. "tomorrow at 7 pm call mom"', () {
      final res = parser.parse('tomorrow at 7 pm call mom', referenceNow: fixedNow);
      expect(res.intent, equals(IntentType.reminder));
      expect(res.title.toLowerCase(), contains('call mom'));
      expect(res.dueDate, isNotNull);
      expect(res.dueDate!.hour, equals(19));
    });

    test('3. "don\'t let me forget to call mom tomorrow"', () {
      final res = parser.parse("don't let me forget to call mom tomorrow", referenceNow: fixedNow);
      expect(res.intent, equals(IntentType.reminder));
      expect(res.title.toLowerCase(), contains('call mom'));
      expect(res.dueDate, isNotNull);
    });

    test('4. "call mom tomorrow"', () {
      final res = parser.parse('call mom tomorrow', referenceNow: fixedNow);
      expect(res.intent, equals(IntentType.reminder));
      expect(res.title.toLowerCase(), contains('call mom'));
      expect(res.dueDate, isNotNull);
    });

    test('5. "i have to call mom tomorrow"', () {
      final res = parser.parse('i have to call mom tomorrow', referenceNow: fixedNow);
      expect(res.intent, equals(IntentType.reminder));
      expect(res.title.toLowerCase(), contains('call mom'));
      expect(res.dueDate, isNotNull);
    });

    test('6. "tomorrow is my mother\'s birthday" (future event, NOT reminder)', () {
      final res = parser.parse("tomorrow is my mother's birthday", referenceNow: fixedNow);
      expect(res.intent, equals(IntentType.futureEvent));
      expect(res.intent, isNot(equals(IntentType.reminder)));
    });

    test('7. "today was my mother\'s birthday" (diary)', () {
      final res = parser.parse("today was my mother's birthday", referenceNow: fixedNow);
      expect(res.intent, equals(IntentType.diary));
    });

    test('8. "i had a meeting today" (diary)', () {
      final res = parser.parse('i had a meeting today', referenceNow: fixedNow);
      expect(res.intent, equals(IntentType.diary));
    });

    test('9. "i have a meeting tomorrow" (future event, NOT reminder)', () {
      final res = parser.parse('i have a meeting tomorrow', referenceNow: fixedNow);
      expect(res.intent, equals(IntentType.futureEvent));
      expect(res.intent, isNot(equals(IntentType.reminder)));
    });

    test('10. "remind me about my meeting tomorrow" (reminder)', () {
      final res = parser.parse('remind me about my meeting tomorrow', referenceNow: fixedNow);
      expect(res.intent, equals(IntentType.reminder));
      expect(res.title.toLowerCase(), contains('meeting'));
    });

    test('11. "next Monday at 9 AM remind me to submit the report"', () {
      final res = parser.parse('next Monday at 9 AM remind me to submit the report', referenceNow: fixedNow);
      expect(res.intent, equals(IntentType.reminder));
      expect(res.title.toLowerCase(), contains('submit the report'));
      expect(res.dueDate, isNotNull);
      expect(res.dueDate!.hour, equals(9));
    });

    test('12. "remind me in 20 minutes to check the oven"', () {
      final res = parser.parse('remind me in 20 minutes to check the oven', referenceNow: fixedNow);
      expect(res.intent, equals(IntentType.reminder));
      expect(res.title.toLowerCase(), contains('check the oven'));
      expect(res.dueDate, isNotNull);
      expect(res.dueDate!.difference(fixedNow).inMinutes, equals(20));
    });

    test('13. "remind me in two hours"', () {
      final res = parser.parse('remind me in 2 hours', referenceNow: fixedNow);
      expect(res.intent, equals(IntentType.reminder));
      expect(res.dueDate, isNotNull);
      expect(res.dueDate!.difference(fixedNow).inHours, equals(2));
    });

    test('14. "remind me at 7" (ambiguous time detected)', () {
      final res = parser.parse('remind me at 7', referenceNow: fixedNow);
      expect(res.intent, equals(IntentType.reminder));
      expect(res.isAmbiguousTime, isTrue);
      expect(res.clarificationPrompt, contains('7 AM or 7 PM'));
    });

    test('15. "remind me tomorrow morning"', () {
      final res = parser.parse('remind me tomorrow morning', referenceNow: fixedNow);
      expect(res.intent, equals(IntentType.reminder));
      expect(res.dueDate, isNotNull);
      expect(res.dueDate!.hour, equals(9)); // 9 AM default for morning
    });

    test('16. "remind me tonight"', () {
      final res = parser.parse('remind me tonight', referenceNow: fixedNow);
      expect(res.intent, equals(IntentType.reminder));
      expect(res.dueDate, isNotNull);
      expect(res.dueDate!.hour, equals(20)); // 8 PM default for tonight
    });

    test('17. "every Monday at 9"', () {
      final res = parser.parse('every Monday at 9 am remind me about standup', referenceNow: fixedNow);
      expect(res.intent, equals(IntentType.reminder));
      expect(res.recurrence, equals(RecurrenceType.weekly));
      expect(res.dueDate!.hour, equals(9));
    });

    test('18. "every weekend remind me to call home"', () {
      final res = parser.parse('every weekend remind me to call home', referenceNow: fixedNow);
      expect(res.intent, equals(IntentType.reminder));
      expect(res.recurrence, equals(RecurrenceType.weekly));
      expect(res.title.toLowerCase(), contains('call home'));
    });

    test('19. "give me a python program to sort an array" (off-topic)', () {
      final res = parser.parse('give me a python program to sort an array', referenceNow: fixedNow);
      expect(res.intent, equals(IntentType.offTopic));
      expect(res.intent, isNot(equals(IntentType.diary)));
      expect(res.intent, isNot(equals(IntentType.reminder)));
    });

    test('20. "what is machine learning" (off-topic)', () {
      final res = parser.parse('what is machine learning', referenceNow: fixedNow);
      expect(res.intent, equals(IntentType.offTopic));
    });

    test('21. "today I completed my project" (diary)', () {
      final res = parser.parse('today I completed my project', referenceNow: fixedNow);
      expect(res.intent, equals(IntentType.diary));
    });

    test('22. "today was a difficult day" (diary)', () {
      final res = parser.parse('today was a difficult day', referenceNow: fixedNow);
      expect(res.intent, equals(IntentType.diary));
    });

    test('23. "my exam is next Friday" (future event)', () {
      final res = parser.parse('my exam is next Friday', referenceNow: fixedNow);
      expect(res.intent, equals(IntentType.futureEvent));
    });

    test('24. "remind me next Friday about my exam" (reminder)', () {
      final res = parser.parse('remind me next Friday about my exam', referenceNow: fixedNow);
      expect(res.intent, equals(IntentType.reminder));
      expect(res.title.toLowerCase(), contains('exam'));
    });
  });

  group('Validation & Disambiguation Tests', () {
    test('Past date/time detection: when requested time has passed today, flag isPastTime and suggest tomorrow', () {
      // Current time is 10:00 PM (22:00)
      final nightTime = DateTime(2026, 9, 20, 22, 0);
      final res = EntityExtractor.extract('remind me today at 5 pm to call dad', referenceNow: nightTime);

      expect(res.isPastTime, isTrue);
      expect(res.suggestedAlternativeDate, isNotNull);
      expect(res.suggestedAlternativeDate!.day, equals(nightTime.day + 1));
      expect(res.suggestedAlternativeDate!.hour, equals(17));
      expect(res.clarificationPrompt, contains('has already passed'));
      expect(res.clarificationPrompt, contains('tomorrow at 5:00 PM'));
    });

    test('Title and Description intelligent separation: preserves context without bloating title', () {
      final res = EntityExtractor.extract(
        'Remind me tomorrow at 6 PM to submit the project report to Professor Ahmed before the deadline.',
      );

      expect(res.title, equals('Submit project report'));
      expect(res.description, contains('Professor Ahmed before the deadline'));
    });

    test('Doctor appointment title extraction cleans filler and command words', () {
      final res = EntityExtractor.extract('At 5 PM tomorrow I need to go to the doctor.');
      expect(res.title, equals('Doctor appointment'));
    });

    test('Snooze 10 minutes advances dueDate by exactly 10 minutes and increments count', () {
      final original = Reminder(
        id: 'test_rem_1',
        title: 'Meeting',
        dueDate: DateTime.now().subtract(const Duration(minutes: 1)),
      );

      final before = DateTime.now();
      final snoozed = ReminderScheduler.snooze(original, 10);
      final after = DateTime.now();

      expect(snoozed.snoozeCount, equals(1));
      expect(snoozed.dueDate.isAfter(before.add(const Duration(minutes: 9, seconds: 50))), isTrue);
      expect(snoozed.dueDate.isBefore(after.add(const Duration(minutes: 10, seconds: 10))), isTrue);
    });

    test('Snooze 15 minutes advances dueDate by exactly 15 minutes', () {
      final original = Reminder(
        id: 'test_rem_2',
        title: 'Call Doctor',
        dueDate: DateTime.now(),
      );

      final before = DateTime.now();
      final snoozed = ReminderScheduler.snooze(original, 15);
      expect(snoozed.dueDate.isAfter(before.add(const Duration(minutes: 14, seconds: 50))), isTrue);
    });

    test('Mute reminder sets muted flag without modifying other properties', () {
      final original = Reminder(
        id: 'test_rem_3',
        title: 'Workout',
        dueDate: DateTime.now().add(const Duration(hours: 2)),
        muted: false,
      );

      final muted = ReminderScheduler.mute(original);
      expect(muted.muted, isTrue);
      expect(muted.id, equals(original.id));
      expect(muted.title, equals(original.title));
      expect(muted.dueDate, equals(original.dueDate));
    });
  });
}
