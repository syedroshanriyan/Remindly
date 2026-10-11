import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    loadTheme();
  }

  void loadTheme() {
    final box = Hive.box('settings');

    final saved = box.get(
      'theme',
      defaultValue: 'system',
    );

    switch (saved) {
      case 'light':
        _themeMode = ThemeMode.light;
        break;

      case 'dark':
        _themeMode = ThemeMode.dark;
        break;

      default:
        _themeMode = ThemeMode.system;
    }

    notifyListeners();
  }

  void setSystemTheme() {
    _themeMode = ThemeMode.system;

    Hive.box('settings').put(
      'theme',
      'system',
    );

    notifyListeners();
  }

  void setLightTheme() {
    _themeMode = ThemeMode.light;

    Hive.box('settings').put(
      'theme',
      'light',
    );

    notifyListeners();
  }

  void setDarkTheme() {
    _themeMode = ThemeMode.dark;

    Hive.box('settings').put(
      'theme',
      'dark',
    );

    notifyListeners();
  }
}
