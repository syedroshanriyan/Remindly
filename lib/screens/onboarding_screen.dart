import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/design_tokens.dart';
import '../core/utils/app_feedback.dart';
import '../providers/settings_provider.dart';
import '../services/speech_service.dart';
import '../widgets/user_avatar.dart';
import 'main_navigation_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Profile Setup Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String _selectedGender = 'Prefer not to say';
  bool _micPermissionGranted = false;
  String? _profileImagePath;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _requestMicPermission() async {
    final speech = SpeechService();
    final ok = await speech.initialize();
    setState(() => _micPermissionGranted = ok);
    if (!mounted) return;
    if (ok) {
      AppFeedback.showSuccess(context, 'Microphone permission active');
    } else {
      AppFeedback.showError(context, 'Microphone permission required');
    }
  }

  void _pickProfileImage() async {
    try {
      final result = await FilePicker.platform
          .pickFiles(type: FileType.image, allowMultiple: false);
      if (result != null &&
          result.files.isNotEmpty &&
          result.files.single.path != null) {
        setState(() {
          _profileImagePath = result.files.single.path!;
        });
      }
    } catch (_) {}
  }

  void _finishProfileSetup() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      AppFeedback.showError(context, 'Please enter your name');
      return;
    }

    final settings = context.read<SettingsProvider>();
    settings.saveProfile(
      name: name,
      email: _emailController.text.trim(),
      gender: _selectedGender,
      profileImagePath: _profileImagePath,
    );
    settings.completeOnboarding();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Step Counter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceVariant
                          : AppColors.lightSurfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_currentPage + 1}/4',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ),
                  if (_currentPage < 3)
                    TextButton(
                      onPressed: () => _pageController.animateToPage(
                        3,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                      child: Text(
                        'Skip to Profile',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                children: [
                  _buildSlide1(isDark),
                  _buildSlide2(isDark),
                  _buildSlide3(isDark),
                  _buildProfileSlide(isDark),
                ],
              ),
            ),

            // Bottom Navigation Dots & Next Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(
                      4,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(right: 6),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: _currentPage == index
                              ? AppColors.primary(isDark)
                              : (isDark ? Colors.white24 : Colors.black12),
                        ),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary(isDark),
                      foregroundColor:
                          isDark ? AppColors.darkOnPrimary : Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      if (_currentPage < 3) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _finishProfileSetup();
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentPage == 3 ? 'Get Started' : 'Next',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide1(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              boxShadow: DesignTokens.themeCardShadow(isDark),
            ),
            child: Center(
              child: Icon(Icons.auto_stories_rounded,
                  size: 52, color: AppColors.primary(isDark)),
            ),
          ),
          const SizedBox(height: 36),
          Text(
            'Your Smart Personal Diary',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Organize your thoughts, daily logs, and inspirations in a private journal that works completely offline.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide2(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              boxShadow: DesignTokens.themeCardShadow(isDark),
            ),
            child: Center(
              child: Icon(Icons.record_voice_over_rounded,
                  size: 52, color: AppColors.champagne(isDark)),
            ),
          ),
          const SizedBox(height: 36),
          Text(
            'Speak Naturally',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Voice recognition and on-device natural language understanding automatically schedule reminders or format notes.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide3(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              boxShadow: DesignTokens.themeCardShadow(isDark),
            ),
            child: const Center(
              child: Icon(Icons.shield_outlined,
                  size: 52, color: AppColors.success),
            ),
          ),
          const SizedBox(height: 36),
          Text(
            '100% Private & Offline',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No cloud servers, no account required, and no data tracking. Your personal data stays encrypted and local to your device.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSlide(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                UserAvatar(
                  radius: 38,
                  imagePath: _profileImagePath,
                  initial: _nameController.text.isNotEmpty
                      ? _nameController.text.substring(0, 1)
                      : 'U',
                  showCameraBadge: true,
                  onTap: _pickProfileImage,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _pickProfileImage,
                  child: Text(
                    _profileImagePath != null
                        ? 'Change Profile Photo'
                        : 'Add Profile Photo (Optional)',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Complete Your Profile',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'Personalize your Remindly experience',
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Name Input
          Text(
            'Your Name *',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: TextField(
              controller: _nameController,
              style: const TextStyle(fontSize: 15),
              decoration: const InputDecoration(
                hintText: 'e.g. John Doe',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Email Input (Optional)
          Text(
            'Email Address (for local backup)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(fontSize: 15),
              decoration: const InputDecoration(
                hintText: 'e.g. john@example.com',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Gender Dropdown
          Text(
            'Gender',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: DropdownButton<String>(
              value: _selectedGender,
              isExpanded: true,
              underline: const SizedBox(),
              dropdownColor:
                  isDark ? AppColors.darkSurfaceVariant : Colors.white,
              items: ['Prefer not to say', 'Male', 'Female', 'Other']
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedGender = val);
              },
            ),
          ),

          const SizedBox(height: 18),

          // Permissions Pre-flight Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceVariant
                  : AppColors.lightSurfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  _micPermissionGranted
                      ? Icons.check_circle_rounded
                      : Icons.mic_rounded,
                  color: _micPermissionGranted
                      ? AppColors.success
                      : AppColors.primary(isDark),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _micPermissionGranted
                        ? 'Microphone enabled'
                        : 'Enable voice transcription',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                if (!_micPermissionGranted)
                  TextButton(
                    onPressed: _requestMicPermission,
                    child: const Text('Allow',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
