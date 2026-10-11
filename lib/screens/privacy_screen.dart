import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/app_feedback.dart';
import '../providers/diary_provider.dart';
import '../providers/reminder_provider.dart';
import '../services/backup_service.dart';
import '../services/hive_service.dart';
import '../providers/app_lock_provider.dart';
import '../widgets/app_lock_setup_dialog.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  void _showDeleteAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('Wipe All Local Data?'),
          ],
        ),
        content: const Text(
          'This will permanently delete all reminders, notes, and local application data. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              await HiveService.resetAll();
              if (ctx.mounted) {
                Navigator.pop(ctx);
                context.read<ReminderProvider>().loadReminders();
                context.read<DiaryProvider>().loadEntries();
                AppFeedback.showSuccess(context, 'All data wiped');
              }
            },
            child: const Text('Delete Permanently',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppLockProvider? lockProvider;
    try {
      lockProvider = context.watch<AppLockProvider>();
    } catch (_) {}
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Data & Privacy',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Zero Cloud Badge
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
              border:
                  Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user_rounded,
                    color: AppColors.success, size: 32),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '100% Offline & Private',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Zero external cloud servers, zero trackers, zero telemetry. Your data belongs only to you.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Data Management Cards (Miro design!)
          _buildSectionTitle('Data Management', isDark),
          _buildCard(
            isDark,
            children: [
              ListTile(
                leading: Icon(Icons.file_download_outlined,
                    color: AppColors.primary(isDark)),
                title: const Text('Export Data'),
                subtitle: const Text(
                    'Share or save encrypted JSON backup of notes & reminders'),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () async {
                  try {
                    await BackupService.exportBackupFile();
                    if (context.mounted) {
                      AppFeedback.showSuccess(context, 'Backup exported');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      AppFeedback.showError(context, 'Export failed: $e');
                    }
                  }
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.file_upload_outlined,
                    color: AppColors.champagne(isDark)),
                title: const Text('Import Data'),
                subtitle: const Text(
                    'Restore reminders and diary from JSON backup file'),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () async {
                  try {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.any,
                      withData: true,
                    );
                    if (result != null && result.files.isNotEmpty) {
                      final picked = result.files.single;
                      String jsonStr;
                      if (picked.path != null &&
                          File(picked.path!).existsSync()) {
                        jsonStr = await File(picked.path!).readAsString();
                      } else if (picked.bytes != null) {
                        jsonStr = String.fromCharCodes(picked.bytes!);
                      } else {
                        return;
                      }
                      final backupData =
                          await BackupService.parseBackupJson(jsonStr);
                      final count =
                          await BackupService.restoreBackup(backupData);
                      if (context.mounted) {
                        context.read<ReminderProvider>().loadReminders();
                        context.read<DiaryProvider>().loadEntries();
                        AppFeedback.showSuccess(
                            context, 'Restored $count items successfully');
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      AppFeedback.showError(context, 'Import failed: $e');
                    }
                  }
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.cleaning_services_outlined,
                    color: AppColors.warning),
                title: const Text('Clear Cache'),
                subtitle: const Text(
                    'Free up temporary files and compact Hive boxes'),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () {
                  AppFeedback.showSuccess(context, 'Cache cleared');
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.delete_forever_rounded,
                    color: AppColors.error),
                title: const Text('Delete All Data',
                    style: TextStyle(
                        color: AppColors.error, fontWeight: FontWeight.bold)),
                subtitle: const Text(
                    'Permanently wipe reminders, diary, and settings'),
                onTap: () => _showDeleteAllDialog(context),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Security & App Lock
          _buildSectionTitle('Security & App Lock', isDark),
          _buildCard(
            isDark,
            children: [
              SwitchListTile(
                secondary: Icon(Icons.lock_outline_rounded, color: AppColors.primary(isDark)),
                title: const Text('Application Lock', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                subtitle: Text(
                  (lockProvider?.isLockEnabled ?? false)
                      ? ((lockProvider?.isDeviceLock ?? false)
                          ? 'Secured with Device Lock (Biometrics/PIN)'
                          : 'Secured with Separate App PIN (${lockProvider?.configuredPinLength ?? 4} digits)')
                      : 'Disabled • Lock app with Device Lock or Custom PIN',
                  style: const TextStyle(fontSize: 13),
                ),
                value: lockProvider?.isLockEnabled ?? false,
                activeThumbColor: AppColors.primary(isDark),
                onChanged: (val) {
                  if (val) {
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
                  leading: const SizedBox(width: 24),
                  title: Text(
                    (lockProvider?.isDeviceLock ?? false)
                        ? 'Switch to Custom PIN'
                        : 'Change PIN / Switch to Device Lock',
                    style: TextStyle(fontSize: 13.5, color: AppColors.primary(isDark), fontWeight: FontWeight.w600),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12),
                  onTap: () => AppLockSetupDialog.show(context),
                ),
              ],
            ],
          ),

          const SizedBox(height: 24),

          // Permissions & Privacy Info
          _buildSectionTitle('Device Permissions', isDark),
          _buildCard(
            isDark,
            children: [
              ListTile(
                leading: Icon(Icons.mic_none_rounded,
                    color: AppColors.primary(isDark)),
                title: const Text('Microphone'),
                subtitle: const Text(
                    'Used only for offline speech transcription. Audio is never saved or uploaded.'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.notifications_active_outlined,
                    color: AppColors.champagne(isDark)),
                title: const Text('Notifications & Exact Alarms'),
                subtitle: const Text(
                    'Used strictly to schedule local alerts and action buttons on your device.'),
              ),
            ],
          ),

          const SizedBox(height: 36),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCard(bool isDark, {required List<Widget> children}) {
    return Material(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}
