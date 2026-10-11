import 'package:flutter_test/flutter_test.dart';
import 'package:remindly/models/diary_entry.dart';
import 'package:remindly/models/reminder.dart';

void main() {
  group('DiaryEntry Model Tests', () {
    test('DiaryEntry serialization toMap and fromMap works correctly', () {
      final now = DateTime.now();
      final entry = DiaryEntry(
        id: 'diary-uuid-1',
        title: 'Reflections on Product Launch',
        content: 'Today was an incredible milestone for our team. We released with 0 bugs.',
        createdAt: now,
        updatedAt: now,
        tags: ['milestone', 'product', 'gratitude'],
        sourceType: SourceType.text,
        confidence: 0.98,
        isArchived: false,
      );

      final map = entry.toMap();
      final restored = DiaryEntry.fromMap(map);

      expect(restored.id, equals(entry.id));
      expect(restored.title, equals(entry.title));
      expect(restored.content, equals(entry.content));
      expect(restored.tags, containsAll(['milestone', 'product', 'gratitude']));
      expect(restored.isArchived, isFalse);
    });

    test('copyWith properly mutates fields', () {
      final entry = DiaryEntry(
        id: 'diary-2',
        title: 'Morning Walk',
        content: 'Walked in the park.',
      );

      final modified = entry.copyWith(
        title: 'Morning Walk & Run',
        tags: ['health', 'morning'],
        isArchived: true,
      );

      expect(modified.title, equals('Morning Walk & Run'));
      expect(modified.tags, equals(['health', 'morning']));
      expect(modified.isArchived, isTrue);
      expect(modified.id, equals('diary-2'));
    });
  });
}
