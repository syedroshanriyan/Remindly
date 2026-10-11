import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../core/errors/app_exceptions.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/app_feedback.dart';
import '../providers/diary_provider.dart';
import '../providers/reminder_provider.dart';
import '../services/backup_service.dart';

class StorageBackupScreen extends StatefulWidget {
  const StorageBackupScreen({super.key});

  @override
  State<StorageBackupScreen> createState() => _StorageBackupScreenState();
}

class _StorageBackupScreenState extends State<StorageBackupScreen> {
  bool _autoBackup = true;
  String _lastBackup = 'Not performed yet';
  bool _isExporting = false;
  bool _isImporting = false;

  void _exportBackup() async {
    setState(() => _isExporting = true);
    try {
      final file = await BackupService.exportBackupFile();
      final sizeKb = (await file.length()) / 1024;
      final sizeStr = sizeKb >= 1024
          ? '${(sizeKb / 1024).toStringAsFixed(1)} MB'
          : '${sizeKb.toStringAsFixed(1)} KB';

      if (!mounted) return;
      setState(() {
        _lastBackup = 'Just now ($sizeStr)';
        _isExporting = false;
      });

      AppFeedback.showSuccess(context, 'Backup exported ($sizeStr)');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isExporting = false);
      AppFeedback.showError(context, 'Export failed: $e');
    }
  }

  void _restoreBackup() async {
    setState(() => _isImporting = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isImporting = false);
        return;
      }

      final pickedFile = result.files.single;
      String content;
      if (pickedFile.path != null && File(pickedFile.path!).existsSync()) {
        content = await File(pickedFile.path!).readAsString();
      } else if (pickedFile.bytes != null) {
        content = utf8.decode(pickedFile.bytes!);
      } else {
        throw const BackupException('Could not access selected file.');
      }

      if (!pickedFile.name.toLowerCase().endsWith('.json') &&
          !content.trim().startsWith('{')) {
        throw const BackupException('Please select a valid .json backup file.');
      }

      final backupData = await BackupService.parseBackupJson(content);

      if (!mounted) return;
      final isDark = Theme.of(context).brightness == Brightness.dark;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor:
              isDark ? AppColors.darkSurface : AppColors.lightSurface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              Icon(Icons.restore_page_rounded,
                  color: AppColors.primary(isDark)),
              const SizedBox(width: 8),
              const Text('Restore Backup?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('This backup contains:'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceVariant
                      : AppColors.lightSurfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.alarm_rounded,
                            size: 16, color: AppColors.primary(isDark)),
                        const SizedBox(width: 8),
                        Text(
                          '${backupData.reminders.length} Reminders',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.auto_stories_rounded,
                            size: 16, color: AppColors.champagne(isDark)),
                        const SizedBox(width: 8),
                        Text(
                          '${backupData.diaryEntries.length} Diary Entries',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Data will be merged into your local storage safely without deleting existing entries.',
                style: TextStyle(
                    fontSize: 12, color: AppColors.textSecondary(isDark)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary(isDark),
                foregroundColor:
                    isDark ? AppColors.darkOnPrimary : Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Restore Data'),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        setState(() => _isImporting = false);
        return;
      }

      final count = await BackupService.restoreBackup(backupData);
      if (!mounted) return;

      context.read<ReminderProvider>().loadReminders();
      context.read<DiaryProvider>().loadEntries();

      setState(() => _isImporting = false);
      AppFeedback.showSuccess(context, 'Restored $count items successfully');
    } catch (e) {
      setState(() => _isImporting = false);
      if (!mounted) return;
      AppFeedback.showError(context, 'Restore failed: $e');
    }
  }

  void _clearTemporaryCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
      if (!mounted) return;
      AppFeedback.showSuccess(context, 'Cache cleared');
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(context, 'Could not clear cache');
    }
  }

  @override
  Widget build(BuildContext context) {
    final reminderProvider = context.watch<ReminderProvider>();
    final diaryProvider = context.watch<DiaryProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final totalReminders = reminderProvider.reminders.length;
    final totalDiary = diaryProvider.entries.length;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Storage & Backup',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Database Overview Metrics Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color:
                        isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color:
                              AppColors.primary(isDark).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.storage_rounded,
                            color: AppColors.primary(isDark)),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Local Storage Status',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text('Offline Hive NoSQL Database',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary(isDark))),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          icon: Icons.alarm_rounded,
                          label: 'Reminders',
                          count: totalReminders.toString(),
                          color: AppColors.champagne(isDark),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricTile(
                          icon: Icons.book_outlined,
                          label: 'Diary Entries',
                          count: totalDiary.toString(),
                          color: AppColors.categoryPersonal,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Backup Actions Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color:
                        isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Backup & Restore',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    'Export your database as an encrypted JSON backup file or restore previously saved data.',
                    style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary),
                  ),
                  const SizedBox(height: 20),

                  // Export Button
                  ElevatedButton.icon(
                    icon: _isExporting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.upload_file_rounded),
                    label: const Text('Export JSON Backup',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary(isDark),
                      foregroundColor:
                          isDark ? AppColors.darkOnPrimary : Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _isExporting ? null : _exportBackup,
                  ),
                  const SizedBox(height: 12),

                  // Restore Button
                  OutlinedButton.icon(
                    icon: _isImporting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.download_rounded),
                    label: const Text('Restore from Backup File',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _isImporting ? null : _restoreBackup,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Backup Settings & Cache Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color:
                        isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: Icon(Icons.sync_rounded,
                        color: AppColors.champagne(isDark)),
                    title: const Text('Automatic Local Sync'),
                    subtitle: Text('Last backup: $_lastBackup'),
                    value: _autoBackup,
                    onChanged: (val) => setState(() => _autoBackup = val),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.cleaning_services_rounded,
                        color: AppColors.warning),
                    title: const Text('Clear Temporary Cache'),
                    subtitle: const Text(
                        'Frees up transient audio and scratch files'),
                    trailing: TextButton(
                      onPressed: _clearTemporaryCache,
                      child: const Text('Clean'),
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

  Widget _buildMetricTile({
    required IconData icon,
    required String label,
    required String count,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(count,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.darkTextSecondary)),
        ],
      ),
    );
  }
}
