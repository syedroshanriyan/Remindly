import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/app_feedback.dart';
import '../models/diary_entry.dart';
import '../models/reminder.dart';
import '../providers/diary_provider.dart';
import '../providers/reminder_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import 'add_edit_reminder_screen.dart';
import 'archive_screen.dart';
import 'diary_editor_screen.dart';
import 'diary_screen.dart';
import 'privacy_screen.dart';
import 'profile_screen.dart';
import 'reminders_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'storage_backup_screen.dart';
import 'voice_screen.dart';
import '../widgets/user_avatar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reminderProvider = context.watch<ReminderProvider>();
    final diaryProvider = context.watch<DiaryProvider>();
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final todaySchedule = reminderProvider.todayReminders;
    final recentEntries = diaryProvider.activeEntries.take(3).toList();
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : (hour < 17 ? 'Good afternoon' : 'Good evening');

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      drawer: _buildSideDrawer(context, isDark, settings),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                letterSpacing: 0.2,
              ),
            ),
            Text(
              settings.userName,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Search',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16, left: 6),
            child: UserAvatar(
              radius: 18,
              imagePath: settings.profileImagePath,
              initial: settings.userInitial,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            // Tagline Header Banner — Quiet Luxury & Editorial
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 16, top: 4),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 16,
                    decoration: BoxDecoration(
                      gradient: AppGradients.signature(isDark),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Never miss what matters most.',
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Quick Capture Action Row
            _buildQuickCaptureBar(context, isDark),

            const SizedBox(height: 24),

            // 4. Today's Schedule Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Today's Schedule",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RemindersScreen()),
                    );
                  },
                  child: const Text('View All',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (todaySchedule.isEmpty)
              _buildEmptyScheduleState(context, isDark)
            else
              ...todaySchedule.map((reminder) => _buildScheduleItem(
                  context, reminder, isDark, reminderProvider)),

            const SizedBox(height: 24),

            // 5. Recent Diary Reflections (Primary Product!)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Journal Entries',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DiaryScreen()),
                    );
                  },
                  child: const Text('View All',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (recentEntries.isEmpty)
              _buildEmptyDiaryState(context, isDark)
            else
              ...recentEntries.map(
                  (entry) => _buildRecentDiaryItem(context, entry, isDark)),

            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickCaptureBar(BuildContext context, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionButton(
            context,
            icon: Icons.edit_note_rounded,
            label: 'New Entry',
            isDark: isDark,
            onTap: () async {
              final res = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DiaryEditorScreen()),
              );
              if (res != null && context.mounted) {
                AppFeedback.showSuccess(context, res as String);
              }
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildQuickActionButton(
            context,
            icon: Icons.alarm_add_rounded,
            label: 'Reminder',
            isDark: isDark,
            onTap: () async {
              final res = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AddEditReminderScreen()),
              );
              if (res != null && context.mounted) {
                AppFeedback.showSuccess(context, res as String);
              }
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildQuickActionButton(
            context,
            icon: Icons.mic_none_rounded,
            label: 'Voice Note',
            isDark: isDark,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VoiceScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildQuickActionButton(
            context,
            icon: Icons.search_rounded,
            label: 'Search',
            isDark: isDark,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: AppColors.primary(isDark)),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyScheduleState(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_available_rounded,
            size: 36,
            color: isDark ? Colors.white24 : Colors.black26,
          ),
          const SizedBox(height: 8),
          const Text(
            'No reminders due today',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Your schedule is clear. Tap below or use voice to schedule a reminder.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary(isDark),
              side: BorderSide(color: AppColors.primary(isDark)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            ),
            onPressed: () async {
              final res = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AddEditReminderScreen()),
              );
              if (res != null && context.mounted) {
                AppFeedback.showSuccess(context, res as String);
              }
            },
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Reminder', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(
    BuildContext context,
    Reminder reminder,
    bool isDark,
    ReminderProvider provider,
  ) {
    final catColor = AppColors.getCategoryColor(reminder.category);
    final timeStr = DateFormat('hh:mm a').format(reminder.dueDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            final res = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddEditReminderScreen(reminder: reminder),
              ),
            );
            if (res != null && context.mounted) {
              AppFeedback.showSuccess(context, res as String);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    final wasCompleted = reminder.isCompleted;
                    provider.toggleReminder(reminder.id);
                    AppFeedback.showSuccess(
                      context,
                      wasCompleted ? 'Marked incomplete' : 'Completed',
                    );
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: reminder.isCompleted
                          ? AppColors.success
                          : Colors.transparent,
                      border: Border.all(
                        color:
                            reminder.isCompleted ? AppColors.success : catColor,
                        width: 1.8,
                      ),
                    ),
                    child: reminder.isCompleted
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          decoration: reminder.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: reminder.isCompleted
                              ? (isDark
                                  ? AppColors.darkTextTertiary
                                  : AppColors.lightTextTertiary)
                              : (isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    reminder.category,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: catColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyDiaryState(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        children: [
          Icon(
            Icons.auto_stories_rounded,
            size: 36,
            color: isDark ? Colors.white24 : Colors.black26,
          ),
          const SizedBox(height: 8),
          const Text(
            'Your Journal is Empty',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Write down your daily moments, thoughts, or reflective ideas.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary(isDark),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            ),
            onPressed: () async {
              final res = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DiaryEditorScreen()),
              );
              if (res != null && context.mounted) {
                AppFeedback.showSuccess(context, res as String);
              }
            },
            icon: const Icon(Icons.edit_note_rounded, size: 16),
            label:
                const Text('Write First Note', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentDiaryItem(
      BuildContext context, DiaryEntry entry, bool isDark) {
    final dateStr =
        DateFormat('MMM dd, yyyy • hh:mm a').format(entry.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            final res = await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => DiaryEditorScreen(entry: entry)),
            );
            if (res != null && context.mounted) {
              AppFeedback.showSuccess(context, res as String);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    if (entry.isPinned)
                      const Icon(Icons.star_rounded,
                          size: 16, color: AppColors.warning),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  entry.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                if (entry.content.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    entry.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSideDrawer(
      BuildContext context, bool isDark, SettingsProvider settings) {
    final themeProvider = context.watch<ThemeProvider>();

    return Drawer(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      child: SafeArea(
        child: Column(
          children: [
            InkWell(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()));
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color:
                          isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    UserAvatar(
                      radius: 26,
                      imagePath: settings.profileImagePath,
                      initial: settings.userInitial,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  settings.userName,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.edit_outlined,
                                  size: 14, color: AppColors.primary(isDark)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            settings.userEmail.isNotEmpty
                                ? settings.userEmail
                                : 'Tap to manage profile & backup',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  ListTile(
                    leading: const Icon(Icons.home_outlined),
                    title: const Text('Home'),
                    onTap: () => Navigator.pop(context),
                  ),
                  ListTile(
                    leading: const Icon(Icons.auto_stories_outlined),
                    title: const Text('Diary'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const DiaryScreen()));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.alarm_outlined),
                    title: const Text('Reminders'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RemindersScreen()));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.person_outline_rounded),
                    title: const Text('My Profile'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ProfileScreen()));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.storage_rounded),
                    title: const Text('Storage & Backup'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const StorageBackupScreen()));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.shield_outlined),
                    title: const Text('Privacy & Security'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PrivacyScreen()));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.archive_outlined),
                    title: const Text('Archive'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ArchiveScreen()));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings_outlined),
                    title: const Text('Settings'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SettingsScreen()));
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        themeProvider.themeMode == ThemeMode.system
                            ? Icons.brightness_auto_rounded
                            : (themeProvider.themeMode == ThemeMode.dark
                                ? Icons.dark_mode_rounded
                                : Icons.light_mode_rounded),
                        size: 20,
                        color: AppColors.primary(isDark),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        themeProvider.themeMode == ThemeMode.system
                            ? 'System Mode'
                            : (themeProvider.themeMode == ThemeMode.dark
                                ? 'Dark Mode'
                                : 'Light Mode'),
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () {
                      if (themeProvider.themeMode == ThemeMode.system) {
                        themeProvider.setDarkTheme();
                      } else if (themeProvider.themeMode == ThemeMode.dark) {
                        themeProvider.setLightTheme();
                      } else {
                        themeProvider.setSystemTheme();
                      }
                    },
                    child: const Text('Switch',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
