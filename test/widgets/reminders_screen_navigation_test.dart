import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:remindly/core/constants/app_constants.dart';
import 'package:remindly/providers/reminder_provider.dart';
import 'package:remindly/screens/add_edit_reminder_screen.dart';
import 'package:remindly/screens/reminders_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('remindly_test_reminders_');
    Hive.init(tempDir.path);
    await Hive.openBox(AppConstants.boxSettings);
    await Hive.openBox(AppConstants.boxReminders);
    await Hive.openBox(AppConstants.boxDiaryEntries);
    await Hive.openBox(AppConstants.boxNotificationHistory);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Widget createRemindersScreen() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ReminderProvider()),
      ],
      child: const MaterialApp(
        home: RemindersScreen(),
      ),
    );
  }

  Widget createAddEditReminderScreen() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ReminderProvider()),
      ],
      child: const MaterialApp(
        home: AddEditReminderScreen(),
      ),
    );
  }

  group('RemindersScreen Tab Navigation Tests', () {
    testWidgets('RemindersScreen opens with Today tab selected by default and correct tab order', (tester) async {
      await tester.pumpWidget(createRemindersScreen());
      await tester.pumpAndSettle();

      // Verify the 3 tabs are present
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Upcoming'), findsOneWidget);

      // Verify TabController starts at index 1 (Today)
      final TabBar tabBar = tester.widget(find.byType(TabBar));
      expect(tabBar.controller?.index, equals(1));

      // In the Today view, empty state should show "No reminders due today"
      expect(find.text('No reminders due today'), findsOneWidget);
    });

    testWidgets('Swiping left from Today opens Upcoming, swiping right from Today opens Completed', (tester) async {
      await tester.pumpWidget(createRemindersScreen());
      await tester.pumpAndSettle();

      final TabBar tabBar = tester.widget(find.byType(TabBar));
      expect(tabBar.controller?.index, equals(1));

      // Swipe finger left (fling right-to-left) to reveal Upcoming (index 2)
      await tester.fling(find.byType(TabBarView), const Offset(-400, 0), 1000);
      await tester.pumpAndSettle();

      expect(tabBar.controller?.index, equals(2));
      expect(find.text('No upcoming reminders'), findsOneWidget);

      // Swipe finger right (fling left-to-right) back to Today (index 1)
      await tester.fling(find.byType(TabBarView), const Offset(400, 0), 1000);
      await tester.pumpAndSettle();

      expect(tabBar.controller?.index, equals(1));

      // Swipe finger right (fling left-to-right) to reveal Completed (index 0)
      await tester.fling(find.byType(TabBarView), const Offset(400, 0), 1000);
      await tester.pumpAndSettle();

      expect(tabBar.controller?.index, equals(0));
      expect(find.text('No completed reminders yet'), findsOneWidget);
    });
  });

  group('AddEditReminderScreen Prior Notification Default Tests', () {
    testWidgets('Prior notification defaults to 15 minutes before', (tester) async {
      await tester.pumpWidget(createAddEditReminderScreen());
      await tester.pumpAndSettle();

      // Scroll until the Remind dropdown is visible in the ListView
      await tester.scrollUntilVisible(
        find.text('15 minutes before'),
        100.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Find the dropdown displaying '15 minutes before'
      expect(find.text('15 minutes before'), findsOneWidget);
      expect(find.text('Remind'), findsOneWidget);
    });
  });
}
