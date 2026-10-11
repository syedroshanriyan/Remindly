import 'package:flutter/material.dart';
import '../screens/about_screen.dart';
import '../screens/archive_screen.dart';
import '../screens/diary_editor_screen.dart';
import '../screens/diary_screen.dart';
import '../screens/home_screen.dart';
import '../screens/main_navigation_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/privacy_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/reminders_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/storage_backup_screen.dart';
import '../screens/voice_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String main = '/main';
  static const String home = '/home';
  static const String diary = '/diary';
  static const String diaryEditor = '/diary-editor';
  static const String reminders = '/reminders';
  static const String voice = '/voice';
  static const String settings = '/settings';
  static const String profile = '/profile';
  static const String storageBackup = '/storage-backup';
  static const String privacy = '/privacy';
  static const String archive = '/archive';
  static const String about = '/about';

  static Route<dynamic>? onGenerateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case main:
        return MaterialPageRoute(builder: (_) => const MainNavigationScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case diary:
        return MaterialPageRoute(builder: (_) => const DiaryScreen());
      case diaryEditor:
        return MaterialPageRoute(builder: (_) => const DiaryEditorScreen());
      case reminders:
        return MaterialPageRoute(builder: (_) => const RemindersScreen());
      case voice:
        return MaterialPageRoute(builder: (_) => const VoiceScreen());
      case settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case storageBackup:
        return MaterialPageRoute(builder: (_) => const StorageBackupScreen());
      case privacy:
        return MaterialPageRoute(builder: (_) => const PrivacyScreen());
      case archive:
        return MaterialPageRoute(builder: (_) => const ArchiveScreen());
      case about:
        return MaterialPageRoute(builder: (_) => const AboutScreen());
      default:
        return MaterialPageRoute(builder: (_) => const MainNavigationScreen());
    }
  }
}
