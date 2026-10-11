import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../services/hive_service.dart';
import '../services/tts_service.dart';

class SettingsProvider extends ChangeNotifier {
  bool _voiceAnnouncement = true;
  double _ttsSpeechRate = 0.48;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _hasSeenOnboarding = false;

  String _profileImagePath = '';
  String _userName = '';
  String _userEmail = '';
  String _userPhone = '';
  String _userDob = '';
  String _userGender = 'Prefer not to say';
  bool _hasCompletedProfile = false;

  bool get voiceAnnouncement => _voiceAnnouncement;
  double get ttsSpeechRate => _ttsSpeechRate;
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  bool get hasSeenOnboarding => _hasSeenOnboarding;

  String get profileImagePath => _profileImagePath;
  String get userName => _userName.isNotEmpty ? _userName : 'User';
  String get rawUserName => _userName;
  String get userEmail => _userEmail;
  String get userPhone => _userPhone;
  String get userDob => _userDob;
  String get userGender => _userGender;
  bool get hasCompletedProfile => _hasCompletedProfile;

  String get userInitial {
    if (_userName.trim().isEmpty) return 'U';
    return _userName.trim().substring(0, 1).toUpperCase();
  }

  SettingsProvider() {
    loadSettings();
  }

  void loadSettings() {
    try {
      final box = HiveService.settingsBox;
      _voiceAnnouncement =
          box.get(AppConstants.keyVoiceAnnouncement, defaultValue: true);
      _ttsSpeechRate =
          box.get(AppConstants.keyTtsSpeechRate, defaultValue: 0.48);
      _soundEnabled = box.get(AppConstants.keySoundEnabled, defaultValue: true);
      _vibrationEnabled =
          box.get(AppConstants.keyVibrationEnabled, defaultValue: true);
      _hasSeenOnboarding =
          box.get(AppConstants.keyHasSeenOnboarding, defaultValue: false);

      _profileImagePath = box.get('user_profile_image', defaultValue: '');
      _userName = box.get('user_name', defaultValue: '');
      _userEmail = box.get('user_email', defaultValue: '');
      _userPhone = box.get('user_phone', defaultValue: '');
      _userDob = box.get('user_dob', defaultValue: '');
      _userGender = box.get('user_gender', defaultValue: 'Prefer not to say');
      _hasCompletedProfile =
          box.get('has_completed_profile', defaultValue: false);

      notifyListeners();
    } catch (_) {}
  }

  void saveProfile({
    required String name,
    String email = '',
    String phone = '',
    String dob = '',
    String gender = 'Prefer not to say',
    String? profileImagePath,
  }) {
    _userName = name.trim();
    _userEmail = email.trim();
    _userPhone = phone.trim();
    _userDob = dob.trim();
    _userGender = gender;
    if (profileImagePath != null) {
      _profileImagePath = profileImagePath;
    }
    _hasCompletedProfile = _userName.isNotEmpty;

    final box = HiveService.settingsBox;
    box.put('user_profile_image', _profileImagePath);
    box.put('user_name', _userName);
    box.put('user_email', _userEmail);
    box.put('user_phone', _userPhone);
    box.put('user_dob', _userDob);
    box.put('user_gender', _userGender);
    box.put('has_completed_profile', _hasCompletedProfile);

    notifyListeners();
  }

  void setProfileImage(String path) {
    _profileImagePath = path;
    HiveService.settingsBox.put('user_profile_image', path);
    notifyListeners();
  }

  void removeProfileImage() {
    _profileImagePath = '';
    HiveService.settingsBox.delete('user_profile_image');
    notifyListeners();
  }

  void setVoiceAnnouncement(bool enabled) {
    _voiceAnnouncement = enabled;
    HiveService.settingsBox.put(AppConstants.keyVoiceAnnouncement, enabled);
    notifyListeners();
  }

  void setTtsSpeechRate(double rate) {
    _ttsSpeechRate = rate;
    HiveService.settingsBox.put(AppConstants.keyTtsSpeechRate, rate);
    TTSService().setSpeechRate(rate);
    notifyListeners();
  }

  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
    HiveService.settingsBox.put(AppConstants.keySoundEnabled, enabled);
    notifyListeners();
  }

  void setVibrationEnabled(bool enabled) {
    _vibrationEnabled = enabled;
    HiveService.settingsBox.put(AppConstants.keyVibrationEnabled, enabled);
    notifyListeners();
  }

  void completeOnboarding() {
    _hasSeenOnboarding = true;
    HiveService.settingsBox.put(AppConstants.keyHasSeenOnboarding, true);
    notifyListeners();
  }
}
