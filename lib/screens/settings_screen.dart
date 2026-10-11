import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/app_feedback.dart';
import '../providers/diary_provider.dart';
import '../providers/reminder_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import '../services/hive_service.dart';
import '../services/tts_service.dart';
import '../widgets/user_avatar.dart';
import 'about_screen.dart';
import 'privacy_screen.dart';
import 'profile_screen.dart';
import 'storage_backup_screen.dart';
import '../providers/app_lock_provider.dart';
import '../widgets/app_lock_setup_dialog.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final reminderProvider = context.watch<ReminderProvider>();
    final diaryProvider = context.watch<DiaryProvider>();
    AppLockProvider? lockProvider;
    try {
      lockProvider = context.watch<AppLockProvider>();
    } catch (_) {}
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final reminderCount = reminderProvider.reminders.length;
    final diaryCount = diaryProvider.entries.length;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // 1. Profile Header Card
          _buildProfileCard(context, isDark, settingsProvider),

          const SizedBox(height: 20),

          // 2. Section: Appearance & Display
          _buildSectionHeader('APPEARANCE & DISPLAY', isDark),
          _buildCard(
            isDark,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary(isDark)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.palette_outlined,
                              color: AppColors.primary(isDark), size: 18),
                        ),
                        const SizedBox(width: 10),
                        const Text('Theme Mode',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        const Spacer(),
                        Text(
                          themeProvider.themeMode == ThemeMode.system
                              ? 'System Default'
                              : (themeProvider.themeMode == ThemeMode.dark
                                  ? 'Dark Mode'
                                  : 'Light Mode'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.champagne(isDark),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _buildThemeOption(
                          context,
                          label: 'System',
                          icon: Icons.brightness_auto_rounded,
                          selected: themeProvider.themeMode == ThemeMode.system,
                          isDark: isDark,
                          onTap: () => themeProvider.setSystemTheme(),
                        ),
                        const SizedBox(width: 8),
                        _buildThemeOption(
                          context,
                          label: 'Light',
                          icon: Icons.light_mode_rounded,
                          selected: themeProvider.themeMode == ThemeMode.light,
                          isDark: isDark,
                          onTap: () => themeProvider.setLightTheme(),
                        ),
                        const SizedBox(width: 8),
                        _buildThemeOption(
                          context,
                          label: 'Dark',
                          icon: Icons.dark_mode_rounded,
                          selected: themeProvider.themeMode == ThemeMode.dark,
                          isDark: isDark,
                          onTap: () => themeProvider.setDarkTheme(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 3. Section: Voice & Intelligence
          _buildSectionHeader('VOICE & OFFLINE INTELLIGENCE', isDark),
          _buildCard(
            isDark,
            children: [
              SwitchListTile(
                secondary: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary(isDark).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.record_voice_over_rounded,
                      color: AppColors.primary(isDark), size: 18),
                ),
                title: const Text('Voice Announcements',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                subtitle: const Text(
                    'Read reminder aloud when due using on-device speech engine',
                    style: TextStyle(fontSize: 12)),
                value: settingsProvider.voiceAnnouncement,
                activeThumbColor: AppColors.primary(isDark),
                onChanged: settingsProvider.setVoiceAnnouncement,
              ),
              const Divider(height: 1),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Speech Speed',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary(isDark)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${(settingsProvider.ttsSpeechRate * 2).toStringAsFixed(1)}x',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary(isDark)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Slider(
                      value: settingsProvider.ttsSpeechRate,
                      min: 0.2,
                      max: 0.8,
                      divisions: 6,
                      activeColor: AppColors.primary(isDark),
                      onChanged: settingsProvider.setTtsSpeechRate,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.champagne(isDark).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.volume_up_rounded,
                      color: AppColors.champagne(isDark), size: 18),
                ),
                title: const Text('Test Announcement',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Hear a sample spoken reminder preview',
                    style: TextStyle(fontSize: 12)),
                trailing: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary(isDark),
                    foregroundColor:
                        isDark ? AppColors.darkOnPrimary : Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  onPressed: () {
                    TTSService().testVoiceAnnouncement();
                    AppFeedback.showAnnouncement(
                        context, 'Playing test announcement out loud!');
                  },
                  icon: const Icon(Icons.play_arrow_rounded, size: 16),
                  label: const Text('Test',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
              const Divider(height: 1),
              // Offline AI Badge
              Padding(
                padding: const EdgeInsets.all(14),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_rounded,
                          color: AppColors.success, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '100% Offline AI Processing',
                              style: TextStyle(
                                  fontSize: 14.5, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Intent detection, time parsing, and voice run locally on-device without cloud servers.',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary(isDark)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 4. Section: Reminders & Alerts
          _buildSectionHeader('REMINDERS & NOTIFICATIONS', isDark),
          _buildCard(
            isDark,
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.notifications_active_rounded,
                      color: AppColors.warning, size: 18),
                ),
                title: const Text('Notification Permissions',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                subtitle: const Text(
                    'Exact alarms & priority channels active for prompt alerts',
                    style: TextStyle(fontSize: 13)),
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Active',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success)),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary(isDark).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.snooze_rounded,
                      color: AppColors.primary(isDark), size: 18),
                ),
                title: const Text('Snooze Options',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text(
                    'Actions available in notifications: 10 min, 15 min & Mute',
                    style: TextStyle(fontSize: 12)),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 5. Section: Data, Storage & Privacy
          _buildSectionHeader('DATA & PRIVACY', isDark),
          _buildCard(
            isDark,
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.champagne(isDark).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.storage_rounded,
                      color: AppColors.champagne(isDark), size: 18),
                ),
                title: const Text('Storage & Encrypted Backup',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text(
                    '$reminderCount Reminders • $diaryCount Diary Entries',
                    style: const TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const StorageBackupScreen()),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.shield_outlined,
                      color: AppColors.success, size: 18),
                ),
                title: const Text('Privacy & Security',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text(
                    '100% offline data integrity • Zero analytics or tracking',
                    style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PrivacyScreen()),
                  );
                },
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary(isDark).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.lock_outline_rounded,
                      color: AppColors.primary(isDark), size: 18),
                ),
                title: const Text('App Lock',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                subtitle: Text(
                  (lockProvider?.isLockEnabled ?? false)
                      ? ((lockProvider?.isDeviceLock ?? false)
                          ? 'Protected by Device Lock (Biometrics/PIN)'
                          : 'Protected by Separate App PIN (${lockProvider?.configuredPinLength ?? 4} digits)')
                      : 'Disabled • Tap to protect Remindly with Device Lock or PIN',
                  style: const TextStyle(fontSize: 13),
                ),
                value: lockProvider?.isLockEnabled ?? false,
                activeThumbColor: AppColors.primary(isDark),
                onChanged: (enabled) {
                  if (enabled) {
                    AppLockSetupDialog.show(context);
                  } else {
                    lockProvider?.disableLock();
                    AppFeedback.showInfo(context, 'App lock disabled');
                  }
                },
              ),
              if (lockProvider?.isLockEnabled ?? false) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const SizedBox(width: 30),
                  title: Text(
                    (lockProvider?.isDeviceLock ?? false)
                        ? 'Switch to Custom App PIN'
                        : 'Change App PIN / Switch to Device Lock',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary(isDark),
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12),
                  onTap: () => AppLockSetupDialog.show(context),
                ),
              ],
            ],
          ),

          const SizedBox(height: 20),

          // 6. Section: Danger Zone (Destructive Actions)
          _buildSectionHeader('DATA MANAGEMENT', isDark),
          _buildCard(
            isDark,
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.cleaning_services_rounded,
                      color: AppColors.warning, size: 18),
                ),
                title: const Text('Clear Completed Reminders',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text(
                    'Remove all finished reminders while keeping active ones',
                    style: TextStyle(fontSize: 12)),
                onTap: () => _confirmClearCompleted(context, reminderProvider),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_forever_rounded,
                      color: AppColors.error, size: 18),
                ),
                title: const Text('Delete All App Data',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.error)),
                subtitle: const Text(
                    'Wipe all reminders, diary logs, and reset settings',
                    style: TextStyle(fontSize: 12)),
                onTap: () => _confirmDeleteAll(context),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 7. Section: About
          _buildSectionHeader('ABOUT', isDark),
          _buildCard(
            isDark,
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.champagne(isDark).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.info_outline_rounded,
                      color: AppColors.champagne(isDark), size: 18),
                ),
                title: const Text('About Remindly',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text(
                    'Version 2.0.0 (Production) • Offline AI Smart Diary',
                    style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AboutScreen()),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildProfileCard(
      BuildContext context, bool isDark, SettingsProvider settingsProvider) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            UserAvatar(
              radius: 30,
              imagePath: settingsProvider.profileImagePath,
              initial: settingsProvider.userInitial,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        settingsProvider.userName,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color:
                              AppColors.primary(isDark).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('OFFLINE',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary(isDark))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    settingsProvider.userEmail.isNotEmpty
                        ? settingsProvider.userEmail
                        : 'Tap to view and edit profile',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: AppColors.textSecondary(isDark)),
          ],
        ),
      ),
    );
  }

  void _confirmClearCompleted(BuildContext context, ReminderProvider provider) {
    final completed = provider.completedReminders;
    if (completed.isEmpty) {
      AppFeedback.showInfo(context, 'No completed reminders to clear.');
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.cleaning_services_rounded, color: AppColors.warning),
            SizedBox(width: 8),
            Text('Clear Completed?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          'This will permanently delete ${completed.length} completed reminder(s). Active reminders will remain safe.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final count = completed.length;
              for (final r in completed) {
                provider.deleteReminder(r.id);
              }
              Navigator.pop(ctx);
              AppFeedback.showSuccess(
                  context, 'Cleared $count completed reminder(s).');
            },
            child: const Text('Clear Completed'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAll(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('Reset All Data?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: const Text(
          'This action is irreversible. All reminders, journal entries, and local profile preferences will be permanently wiped from this device.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              await HiveService.resetAll();
              if (ctx.mounted) {
                Navigator.pop(ctx);
                context.read<ReminderProvider>().loadReminders();
                context.read<DiaryProvider>().loadEntries();
                context.read<SettingsProvider>().loadSettings();
                AppFeedback.showSuccess(
                    context, 'All data has been reset to factory defaults.');
              }
            },
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: isDark
              ? AppColors.darkTextSecondary.withValues(alpha: 0.8)
              : AppColors.lightTextSecondary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool selected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: selected ? AppGradients.subtleCard(isDark) : null,
            color: selected
                ? null
                : (isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.03)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppColors.primary(isDark)
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: selected
                    ? AppColors.primary(isDark)
                    : AppColors.textSecondary(isDark),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected
                      ? AppColors.primary(isDark)
                      : AppColors.textPrimary(isDark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(bool isDark, {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      ),
    );
  }
}
