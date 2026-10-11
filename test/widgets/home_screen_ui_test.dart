import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:remindly/core/constants/app_constants.dart';
import 'package:remindly/models/diary_entry.dart';
import 'package:remindly/models/reminder.dart';
import 'package:remindly/providers/diary_provider.dart';
import 'package:remindly/providers/input_provider.dart';
import 'package:remindly/providers/reminder_provider.dart';
import 'package:remindly/providers/settings_provider.dart';
import 'package:remindly/providers/theme_provider.dart';
import 'package:remindly/providers/app_lock_provider.dart';
import 'package:remindly/screens/home_screen.dart';
import 'package:remindly/screens/main_navigation_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('remindly_test_home_');
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

  group('HomeScreen & MainNavigation UI Quality Tests', () {
    testWidgets('HomeScreen renders tagline, schedule, recent diary, and quick actions', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
            ChangeNotifierProvider(create: (_) => ReminderProvider()),
            ChangeNotifierProvider(create: (_) => DiaryProvider()),
            ChangeNotifierProvider(create: (_) => InputProvider()),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify tagline presence
      expect(find.text('Never miss what matters most.'), findsOneWidget);

      // Verify schedule and diary section headings
      expect(find.text("Today's Schedule"), findsOneWidget);
      expect(find.text('Recent Journal Entries'), findsOneWidget);

      // Verify quick capture actions
      expect(find.text('New Entry'), findsOneWidget);
      expect(find.text('Reminder'), findsOneWidget);
      expect(find.text('Voice Note'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('HomeScreen displays next upcoming reminder and recent journal entry when data exists', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final reminder = Reminder(
        id: 'rem-priority-1',
        title: 'Review Project Architecture',
        description: 'Verify quiet-luxury design tokens',
        dueDate: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 12, 0),
        category: 'Work',
        notificationEnabled: false,
      );
      final entry = DiaryEntry(
        id: 'diary-entry-1',
        title: 'Design System Reflections',
        content: 'Refined color tokens and semantic water-glass styling today.',
        createdAt: DateTime.now(),
      );
      await tester.runAsync(() async {
        await Hive.box(AppConstants.boxReminders).put(reminder.id, reminder.toMap());
        await Hive.box(AppConstants.boxDiaryEntries).put(entry.id, entry.toMap());
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
            ChangeNotifierProvider(create: (_) => ReminderProvider()),
            ChangeNotifierProvider(create: (_) => DiaryProvider()),
            ChangeNotifierProvider(create: (_) => InputProvider()),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify schedule and reminder is displayed
      expect(find.text("Today's Schedule"), findsOneWidget);
      expect(find.text('Review Project Architecture'), findsWidgets);

      // Verify recent diary entry is displayed
      expect(find.text('Design System Reflections'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('MainNavigationScreen preserves Home -> Diary -> Mic -> Reminders -> Settings', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
            ChangeNotifierProvider(create: (_) => ReminderProvider()),
            ChangeNotifierProvider(create: (_) => DiaryProvider()),
            ChangeNotifierProvider(create: (_) => InputProvider()),
            ChangeNotifierProvider(create: (_) => AppLockProvider()),
          ],
          child: const MaterialApp(
            home: MainNavigationScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify exact navigation labels
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Diary'), findsOneWidget);
      expect(find.text('Reminders'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      // Verify central Mic floating action button
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });
  });
}
