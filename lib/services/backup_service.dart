import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/constants/app_constants.dart';
import '../core/errors/app_exceptions.dart';
import '../core/utils/input_sanitizer.dart';
import '../models/diary_entry.dart';
import '../models/reminder.dart';
import 'hive_service.dart';

class BackupData {
  final String exportDate;
  final String appVersion;
  final int schemaVersion;
  final List<Reminder> reminders;
  final List<DiaryEntry> diaryEntries;

  BackupData({
    required this.exportDate,
    required this.appVersion,
    required this.schemaVersion,
    required this.reminders,
    required this.diaryEntries,
  });

  Map<String, dynamic> toJson() => {
        'exportDate': exportDate,
        'appVersion': appVersion,
        'schemaVersion': schemaVersion,
        'reminders': reminders.map((r) => r.toMap()).toList(),
        'diaryEntries': diaryEntries.map((d) => d.toMap()).toList(),
      };

  factory BackupData.fromJson(Map<dynamic, dynamic> json) {
    final hasReminders =
        json.containsKey('reminders') && json['reminders'] is List;
    final hasDiaries =
        json.containsKey('diaryEntries') && json['diaryEntries'] is List;

    if (!hasReminders && !hasDiaries) {
      throw const BackupException(
          'Invalid backup file: no reminders or diary entries found.');
    }

    final remindersList = <Reminder>[];
    if (hasReminders) {
      for (final item in json['reminders'] as List) {
        if (item is Map) {
          try {
            final r = Reminder.fromMap(item);
            remindersList.add(r.copyWith(
              title: InputSanitizer.sanitize(r.title),
              description: InputSanitizer.sanitize(r.description),
            ));
          } catch (_) {}
        }
      }
    }

    final diaryList = <DiaryEntry>[];
    if (hasDiaries) {
      for (final item in json['diaryEntries'] as List) {
        if (item is Map) {
          try {
            final d = DiaryEntry.fromMap(item);
            diaryList.add(d.copyWith(
              title: InputSanitizer.sanitize(d.title),
              content: InputSanitizer.sanitize(d.content),
            ));
          } catch (_) {}
        }
      }
    }

    return BackupData(
      exportDate:
          json['exportDate']?.toString() ?? DateTime.now().toIso8601String(),
      appVersion: json['appVersion']?.toString() ?? AppConstants.appVersion,
      schemaVersion: (json['schemaVersion'] is num)
          ? (json['schemaVersion'] as num).toInt()
          : 1,
      reminders: remindersList,
      diaryEntries: diaryList,
    );
  }
}

class BackupService {
  static Future<String> generateBackupJson() async {
    final reminders = <Reminder>[];
    for (final item in HiveService.reminderBox.values) {
      if (item is Map) {
        try {
          reminders.add(Reminder.fromMap(item));
        } catch (_) {}
      }
    }

    final diaries = <DiaryEntry>[];
    for (final item in HiveService.diaryBox.values) {
      if (item is Map) {
        try {
          diaries.add(DiaryEntry.fromMap(item));
        } catch (_) {}
      }
    }

    final backup = BackupData(
      exportDate: DateTime.now().toIso8601String(),
      appVersion: AppConstants.appVersion,
      schemaVersion: 3,
      reminders: reminders,
      diaryEntries: diaries,
    );

    return const JsonEncoder.withIndent('  ').convert(backup.toJson());
  }

  static Future<File> exportBackupFile() async {
    final jsonStr = await generateBackupJson();
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'remindly_backup_$timestamp.json';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(jsonStr, flush: true);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json', name: fileName)],
      subject: 'Remindly Offline Backup ($timestamp)',
      text: 'Here is your private Remindly offline backup file.',
    );

    return file;
  }

  static Future<BackupData> parseBackupJson(String jsonStr) async {
    try {
      final decoded = json.decode(jsonStr);
      if (decoded is! Map) {
        throw const BackupException(
            'Selected file does not contain a valid JSON backup object.');
      }
      return BackupData.fromJson(decoded);
    } catch (e) {
      if (e is BackupException) rethrow;
      throw BackupException('Failed to parse backup data: $e');
    }
  }

  static Future<int> restoreBackup(BackupData data) async {
    int importedCount = 0;
    for (final reminder in data.reminders) {
      await HiveService.reminderBox.put(reminder.id, reminder.toMap());
      importedCount++;
    }
    for (final diary in data.diaryEntries) {
      await HiveService.diaryBox.put(diary.id, diary.toMap());
      importedCount++;
    }
    return importedCount;
  }
}
