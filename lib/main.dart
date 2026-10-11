import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/app_lock_provider.dart';
import 'providers/diary_provider.dart';
import 'providers/input_provider.dart';
import 'providers/reminder_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/app_lock_screen.dart';
import 'screens/splash_screen.dart';
import 'services/hive_service.dart';
import 'services/intent_classifier.dart';
import 'services/notification_service.dart';
import 'services/tts_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize local Hive boxes
  await HiveService.init();

  // Initialize local notification service & channels
  await NotificationService.initialize();

  // Initialize device text-to-speech engine
  await TTSService().init();

  // Initialize on-device intent classifier with bundled weights
  await IntentClassifier().initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => ReminderProvider()),
        ChangeNotifierProvider(create: (_) => DiaryProvider()),
        ChangeNotifierProvider(create: (_) => InputProvider()),
        ChangeNotifierProvider(create: (_) => AppLockProvider()),
      ],
      child: const RemindlyApp(),
    ),
  );
}

class RemindlyApp extends StatefulWidget {
  const RemindlyApp({super.key});

  @override
  State<RemindlyApp> createState() => _RemindlyAppState();
}

class _RemindlyAppState extends State<RemindlyApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      context.read<AppLockProvider>().lockApp();
    } else if (state == AppLifecycleState.resumed) {
      final reminderProvider = context.read<ReminderProvider>();
      reminderProvider.loadReminders();
      reminderProvider.checkDueRemindersNow();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final lockProvider = context.watch<AppLockProvider>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Remindly',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: const SplashScreen(),
      builder: (context, child) {
        if (lockProvider.requiresUnlock) {
          return const AppLockScreen();
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
