import '../core/utils/input_sanitizer.dart';
import 'recurrence_rule.dart';

enum SourceType {
  manual,
  text,
  voice;

  static SourceType fromString(String? val) {
    if (val == null) return SourceType.manual;
    return SourceType.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => SourceType.manual,
    );
  }
}

class Reminder {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  bool isCompleted;
  bool isArchived;
  final RecurrenceType recurrence;
  final SourceType sourceType;
  final String? sourceText;
  final double confidence;
  final bool notificationEnabled;
  final bool voiceEnabled;
  bool muted;
  int snoozeCount;
  DateTime? lastTriggeredAt;
  DateTime? lastCompletedAt;
  String category;
  final int remindBeforeMinutes;

  Reminder({
    required this.id,
    required String title,
    String description = '',
    required this.dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isCompleted = false,
    this.isArchived = false,
    this.recurrence = RecurrenceType.none,
    this.sourceType = SourceType.manual,
    this.sourceText,
    this.confidence = 1.0,
    this.notificationEnabled = true,
    this.voiceEnabled = true,
    this.muted = false,
    this.snoozeCount = 0,
    this.lastTriggeredAt,
    this.lastCompletedAt,
    this.category = 'Work',
    this.remindBeforeMinutes = 15,
  })  : title = InputSanitizer.sanitize(title),
        description = InputSanitizer.sanitize(description),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Reminder copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isCompleted,
    bool? isArchived,
    RecurrenceType? recurrence,
    SourceType? sourceType,
    String? sourceText,
    double? confidence,
    bool? notificationEnabled,
    bool? voiceEnabled,
    bool? muted,
    int? snoozeCount,
    DateTime? lastTriggeredAt,
    DateTime? lastCompletedAt,
    bool clearLastCompletedAt = false,
    String? category,
    int? remindBeforeMinutes,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isCompleted: isCompleted ?? this.isCompleted,
      isArchived: isArchived ?? this.isArchived,
      recurrence: recurrence ?? this.recurrence,
      sourceType: sourceType ?? this.sourceType,
      sourceText: sourceText ?? this.sourceText,
      confidence: confidence ?? this.confidence,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      voiceEnabled: voiceEnabled ?? this.voiceEnabled,
      muted: muted ?? this.muted,
      snoozeCount: snoozeCount ?? this.snoozeCount,
      lastTriggeredAt: lastTriggeredAt ?? this.lastTriggeredAt,
      lastCompletedAt: clearLastCompletedAt
          ? null
          : (lastCompletedAt ?? this.lastCompletedAt),
      category: category ?? this.category,
      remindBeforeMinutes: remindBeforeMinutes ?? this.remindBeforeMinutes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isCompleted': isCompleted,
      'isArchived': isArchived,
      'recurrence': recurrence.name,
      'sourceType': sourceType.name,
      'sourceText': sourceText,
      'confidence': confidence,
      'notificationEnabled': notificationEnabled,
      'voiceEnabled': voiceEnabled,
      'muted': muted,
      'snoozeCount': snoozeCount,
      'lastTriggeredAt': lastTriggeredAt?.toIso8601String(),
      'lastCompletedAt': lastCompletedAt?.toIso8601String(),
      'category': category,
      'remindBeforeMinutes': remindBeforeMinutes,
      'schemaVersion': 3,
    };
  }

  factory Reminder.fromMap(Map<dynamic, dynamic> map) {
    DateTime parsedDueDate;
    if (map['dueDate'] is String) {
      parsedDueDate =
          DateTime.tryParse(map['dueDate'] as String) ?? DateTime.now();
    } else if (map['dueDate'] is DateTime) {
      parsedDueDate = map['dueDate'] as DateTime;
    } else {
      parsedDueDate = DateTime.now();
    }

    DateTime parsedCreatedAt;
    if (map['createdAt'] is String) {
      parsedCreatedAt =
          DateTime.tryParse(map['createdAt'] as String) ?? parsedDueDate;
    } else {
      parsedCreatedAt = DateTime.now();
    }

    DateTime parsedUpdatedAt;
    if (map['updatedAt'] is String) {
      parsedUpdatedAt =
          DateTime.tryParse(map['updatedAt'] as String) ?? parsedCreatedAt;
    } else {
      parsedUpdatedAt = parsedCreatedAt;
    }

    DateTime? parsedLastTriggered;
    if (map['lastTriggeredAt'] is String) {
      parsedLastTriggered = DateTime.tryParse(map['lastTriggeredAt'] as String);
    }

    DateTime? parsedLastCompleted;
    if (map['lastCompletedAt'] is String) {
      parsedLastCompleted = DateTime.tryParse(map['lastCompletedAt'] as String);
    }

    return Reminder(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      dueDate: parsedDueDate,
      createdAt: parsedCreatedAt,
      updatedAt: parsedUpdatedAt,
      isCompleted: map['isCompleted'] == true,
      isArchived: map['isArchived'] == true,
      recurrence: RecurrenceType.fromString(map['recurrence']?.toString()),
      sourceType: SourceType.fromString(map['sourceType']?.toString()),
      sourceText: map['sourceText']?.toString(),
      confidence: (map['confidence'] is num)
          ? (map['confidence'] as num).toDouble()
          : 1.0,
      notificationEnabled: map['notificationEnabled'] != false,
      voiceEnabled: map['voiceEnabled'] != false,
      muted: map['muted'] == true,
      snoozeCount:
          (map['snoozeCount'] is num) ? (map['snoozeCount'] as num).toInt() : 0,
      lastTriggeredAt: parsedLastTriggered,
      lastCompletedAt: parsedLastCompleted,
      category: map['category']?.toString() ?? 'Work',
      remindBeforeMinutes: (map['remindBeforeMinutes'] is num)
          ? (map['remindBeforeMinutes'] as num).toInt()
          : 15,
    );
  }
}
