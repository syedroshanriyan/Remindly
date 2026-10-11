import 'package:flutter_test/flutter_test.dart';
import 'package:remindly/models/parsed_input.dart';
import 'package:remindly/models/reminder.dart';
import 'package:remindly/services/command_parser.dart';

void main() {
  group('CommandParser Tests', () {
    late CommandParser parser;

    setUp(() {
      parser = CommandParser();
    });

    test('parses high-confidence voice reminder with time', () {
      final input = parser.parse(
        'remind me to call the plumber tomorrow at 3 pm',
        sourceType: SourceType.voice,
      );

      expect(input.intent, equals(IntentType.reminder));
      expect(input.title.toLowerCase(), contains('call the plumber'));
      expect(input.dueDate, isNotNull);
      expect(input.dueDate!.hour, equals(15));
      expect(input.isAutoApproved, isTrue);
    });

    test('parses diary entry with contextual tags and title generation', () {
      final input = parser.parse(
        'Today was a very productive day at work. Completed the notification module bug fix.',
        sourceType: SourceType.text,
      );

      expect(input.intent, equals(IntentType.diary));
      expect(input.title, isNotEmpty);
      expect(input.tags, contains('work'));
    });

    test('downgrades reminder without time to request user confirmation', () {
      final input = parser.parse(
        'remind me to fix bicycle',
        sourceType: SourceType.text,
      );

      expect(input.intent, equals(IntentType.reminder));
      expect(input.needsConfirmation, isTrue,
          reason: 'A reminder without an explicit due time should require user confirmation');
    });
  });
}
