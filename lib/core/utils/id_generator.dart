import 'dart:convert';
import 'package:uuid/uuid.dart';

class IdGenerator {
  static const Uuid _uuid = Uuid();

  /// Generates a unique UUID v4 string for entities.
  static String newId() => _uuid.v4();

  /// Generates a stable, deterministic 31-bit positive integer from a UUID string
  /// using FNV-1a 32-bit hashing algorithm.
  /// This ensures platform independence and avoids Dart's unstable object hashCode.
  static int uuidToNotificationId(String uuid, {int offset = 0}) {
    final bytes = utf8.encode(uuid);
    var hash = 0x811c9dc5; // 2166136261 (FNV offset basis)
    for (final b in bytes) {
      hash ^= b;
      hash = (hash * 0x01000193) & 0xFFFFFFFF; // 16777619 (FNV prime)
    }
    // Ensure positive 31-bit integer safe for Android Notification Manager (max: 2,147,483,647)
    final positive = (hash & 0x7FFFFFFF) % 2000000000;
    return positive + offset;
  }
}
