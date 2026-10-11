import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:remindly/core/errors/app_exceptions.dart';
import 'package:remindly/models/diary_entry.dart';
import 'package:remindly/models/reminder.dart';
import 'package:remindly/services/backup_service.dart';

void main() {
  group('BackupService Tests', () {
    test('BackupData correctly serializes and parses valid JSON schema', () async {
      final sampleBackup = BackupData(
        exportDate: DateTime.now().toIso8601String(),
        appVersion: '1.0.0',
        schemaVersion: 1,
        reminders: [
          Reminder(
            id: 'r1',
            title: 'Backup Reminder',
            dueDate: DateTime.now().add(const Duration(days: 2)),
          ),
        ],
        diaryEntries: [
          DiaryEntry(
            id: 'd1',
            title: 'Backup Diary',
            content: 'Journal content here.',
            tags: ['test'],
          ),
        ],
      );

      final jsonStr = jsonEncode(sampleBackup.toJson());
      final parsed = await BackupService.parseBackupJson(jsonStr);

      expect(parsed.schemaVersion, equals(1));
      expect(parsed.reminders.length, equals(1));
      expect(parsed.reminders.first.title, equals('Backup Reminder'));
      expect(parsed.diaryEntries.length, equals(1));
      expect(parsed.diaryEntries.first.title, equals('Backup Diary'));
    });

    test('parseBackupJson throws BackupException on malformed data', () async {
      expect(
        () => BackupService.parseBackupJson('invalid json string {['),
        throwsA(isA<BackupException>()),
      );

      expect(
        () => BackupService.parseBackupJson('{"randomField": 123}'),
        throwsA(isA<BackupException>()),
      );
    });

    test('parseBackupJson gracefully handles backups with only reminders or only diary entries', () async {
      final onlyRemindersJson = jsonEncode({
        'exportDate': DateTime.now().toIso8601String(),
        'schemaVersion': 2,
        'reminders': [
          {
            'id': 'rem-only-1',
            'title': 'Only Reminder',
            'dueDate': DateTime.now().toIso8601String(),
          }
        ],
      });

      final parsedReminders = await BackupService.parseBackupJson(onlyRemindersJson);
      expect(parsedReminders.reminders.length, equals(1));
      expect(parsedReminders.diaryEntries.length, equals(0));

      final onlyDiaryJson = jsonEncode({
        'exportDate': DateTime.now().toIso8601String(),
        'schemaVersion': 2,
        'diaryEntries': [
          {
            'id': 'diary-only-1',
            'title': 'Only Diary Entry',
            'content': 'Some diary thoughts.',
          }
        ],
      });

      final parsedDiary = await BackupService.parseBackupJson(onlyDiaryJson);
      expect(parsedDiary.diaryEntries.length, equals(1));
      expect(parsedDiary.reminders.length, equals(0));
    });
  });
}
