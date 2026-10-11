import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import '../core/constants/app_constants.dart';
import '../services/hive_service.dart';

class AppLockProvider extends ChangeNotifier {
  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _isLockEnabled = false;
  String _lockMode = AppConstants.lockModeDevice;
  String _customPassword = '';
  bool _isUnlocked = true;

  bool get isLockEnabled => _isLockEnabled;
  String get lockMode => _lockMode;
  bool get isDeviceLock => _lockMode == AppConstants.lockModeDevice;
  bool get isCustomPasswordLock => _lockMode == AppConstants.lockModeCustomPassword;
  bool get isUnlocked => _isUnlocked;
  bool get requiresUnlock => _isLockEnabled && !_isUnlocked;
  bool get hasCustomPassword => _customPassword.isNotEmpty;
  int get configuredPinLength => _customPassword.length == 6 ? 6 : 4;

  AppLockProvider() {
    loadSettings();
  }

  void loadSettings() {
    try {
      final box = HiveService.settingsBox;
      _isLockEnabled = box.get(AppConstants.keyAppLockEnabled, defaultValue: false);
      _lockMode = box.get(AppConstants.keyAppLockMode, defaultValue: AppConstants.lockModeDevice);
      _customPassword = box.get(AppConstants.keyAppLockPassword, defaultValue: '');

      // On startup, if lock is enabled, user must authenticate
      if (_isLockEnabled) {
        _isUnlocked = false;
      } else {
        _isUnlocked = true;
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> canCheckBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheck || isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticateWithDevice() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to open Remindly',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
      if (authenticated) {
        _isUnlocked = true;
        notifyListeners();
      }
      return authenticated;
    } on PlatformException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  bool verifyPassword(String input) {
    if (input.trim() == _customPassword.trim()) {
      _isUnlocked = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  void enableDeviceLock() {
    _isLockEnabled = true;
    _lockMode = AppConstants.lockModeDevice;
    _isUnlocked = true;

    final box = HiveService.settingsBox;
    box.put(AppConstants.keyAppLockEnabled, true);
    box.put(AppConstants.keyAppLockMode, AppConstants.lockModeDevice);
    notifyListeners();
  }

  void enableCustomPasswordLock(String password) {
    _isLockEnabled = true;
    _lockMode = AppConstants.lockModeCustomPassword;
    _customPassword = password.trim();
    _isUnlocked = true;

    final box = HiveService.settingsBox;
    box.put(AppConstants.keyAppLockEnabled, true);
    box.put(AppConstants.keyAppLockMode, AppConstants.lockModeCustomPassword);
    box.put(AppConstants.keyAppLockPassword, _customPassword);
    notifyListeners();
  }

  void disableLock() {
    _isLockEnabled = false;
    _isUnlocked = true;

    final box = HiveService.settingsBox;
    box.put(AppConstants.keyAppLockEnabled, false);
    notifyListeners();
  }

  void lockApp() {
    if (_isLockEnabled) {
      _isUnlocked = false;
      notifyListeners();
    }
  }

  void unlockApp() {
    _isUnlocked = true;
    notifyListeners();
  }
}
