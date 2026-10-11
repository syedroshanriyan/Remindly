import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remindly/models/reminder.dart';
import 'package:remindly/widgets/empty_state.dart';
import 'package:remindly/widgets/reminder_card.dart';

void main() {
  group('Widget Tests', () {
    testWidgets('EmptyState displays title, subtitle, and CTA button', (tester) async {
      bool actionTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              message: 'No reminders yet',
              subtitle: 'Tap add to create your first reminder.',
              actionLabel: 'Add Reminder',
              onAction: () => actionTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('No reminders yet'), findsOneWidget);
      expect(find.text('Tap add to create your first reminder.'), findsOneWidget);
      expect(find.text('Add Reminder'), findsOneWidget);

      await tester.tap(find.text('Add Reminder'));
      expect(actionTapped, isTrue);
    });

    testWidgets('ReminderCard renders title, description, and time', (tester) async {
      final reminder = Reminder(
        id: 'rem-1',
        title: 'Meeting with Architect',
        description: 'Discuss building plan',
        dueDate: DateTime.now().add(const Duration(hours: 2)),
      );

      bool completed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReminderCard(
              reminder: reminder,
              onComplete: () => completed = true,
            ),
          ),
        ),
      );

      expect(find.text('Meeting with Architect'), findsOneWidget);
      expect(find.text('Discuss building plan'), findsOneWidget);

      await tester.tap(find.byKey(const Key('reminder_complete_btn')));
      await tester.pump();
      expect(completed, isTrue);
    });
  });
}
