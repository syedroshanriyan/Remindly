import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remindly/core/utils/app_feedback.dart';
import 'package:remindly/models/reminder.dart';
import 'package:remindly/widgets/bottom_nav_scope.dart';
import 'package:remindly/widgets/reminder_card.dart';

void main() {
  group('BottomNavScope & AppFeedback Tests', () {
    testWidgets('BottomNavScope calculates clearance properly', (tester) async {
      double calculatedClearance = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: BottomNavScope(
            hasBottomNav: true,
            child: Builder(
              builder: (context) {
                calculatedClearance = BottomNavScope.bottomClearance(context);
                return const Scaffold(body: Text('Test'));
              },
            ),
          ),
        ),
      );

      // Snug clearance directly above microphone: safeBottom (0) + bottomBarHeight (62) + fabClearance (36) = 98.0
      expect(calculatedClearance, equals(98.0));
    });

    testWidgets('AppFeedback.showAnnouncement creates floating SnackBar above microphone clearance', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BottomNavScope(
            hasBottomNav: true,
            child: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      AppFeedback.showAnnouncement(context, 'Playing test announcement out loud!');
                    },
                    child: const Text('Test Announcement'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Test Announcement'));
      await tester.pump(); // Start animation
      await tester.pump(const Duration(milliseconds: 300)); // Animate in

      expect(find.text('Playing test announcement out loud!'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.behavior, equals(SnackBarBehavior.floating));
      expect(snackBar.margin, isNotNull);
      final margin = snackBar.margin as EdgeInsets;
      expect(margin.bottom, greaterThanOrEqualTo(98.0));
    });

    testWidgets('AppFeedback replaces previous SnackBar without stacking', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Column(
                  children: [
                    ElevatedButton(
                      onPressed: () => AppFeedback.showSuccess(context, 'First message'),
                      child: const Text('First'),
                    ),
                    ElevatedButton(
                      onPressed: () => AppFeedback.showSuccess(context, 'Second message'),
                      child: const Text('Second'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('First'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('First message'), findsOneWidget);

      await tester.tap(find.text('Second'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Second message'), findsOneWidget);
      expect(find.text('First message'), findsNothing);
    });

    testWidgets('ReminderCard supports onArchive and onRestore callbacks', (tester) async {
      bool archived = false;
      bool restored = false;

      final activeReminder = Reminder(
        id: 'rem-1',
        title: 'Active Reminder',
        dueDate: DateTime.now().add(const Duration(hours: 1)),
      );

      final archivedReminder = Reminder(
        id: 'rem-2',
        title: 'Archived Reminder',
        dueDate: DateTime.now().add(const Duration(hours: 1)),
        isArchived: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ReminderCard(
                  reminder: activeReminder,
                  onArchive: () => archived = true,
                ),
                ReminderCard(
                  reminder: archivedReminder,
                  onRestore: () => restored = true,
                ),
              ],
            ),
          ),
        ),
      );

      // Open popup on active reminder
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      expect(find.text('Archive'), findsOneWidget);
      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();
      expect(archived, isTrue);

      // Open popup on archived reminder
      await tester.tap(find.byIcon(Icons.more_vert).last);
      await tester.pumpAndSettle();
      expect(find.text('Restore'), findsOneWidget);
      await tester.tap(find.text('Restore'));
      await tester.pumpAndSettle();
      expect(restored, isTrue);
    });
  });
}
