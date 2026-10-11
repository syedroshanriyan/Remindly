import 'package:flutter_test/flutter_test.dart';
import 'package:remindly/core/utils/id_generator.dart';

void main() {
  group('IdGenerator Tests', () {
    test('generateUuid produces unique strings', () {
      final id1 = IdGenerator.newId();
      final id2 = IdGenerator.newId();
      expect(id1, isNotEmpty);
      expect(id2, isNotEmpty);
      expect(id1, isNot(equals(id2)));
    });

    test('uuidToNotificationId is deterministic and within 31-bit limit', () {
      const sampleUuid = '550e8400-e29b-41d4-a716-446655440000';
      final idA = IdGenerator.uuidToNotificationId(sampleUuid);
      final idB = IdGenerator.uuidToNotificationId(sampleUuid);

      expect(idA, equals(idB), reason: 'Notification ID must be 100% deterministic');
      expect(idA, greaterThanOrEqualTo(0));
      expect(idA, lessThan(2147483647));

      final offsetId = IdGenerator.uuidToNotificationId(sampleUuid, offset: 1);
      expect(offsetId, equals(idA + 1));
    });
  });
}
