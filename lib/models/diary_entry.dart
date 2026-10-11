import '../core/utils/input_sanitizer.dart';
import 'reminder.dart';

class DiaryEntry {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags;
  final SourceType sourceType;
  final double confidence;
  bool isArchived;
  bool isPinned;
  String category;
  final List<String> attachments;

  DiaryEntry({
    required this.id,
    required String title,
    required String content,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    this.sourceType = SourceType.manual,
    this.confidence = 1.0,
    this.isArchived = false,
    this.isPinned = false,
    this.category = 'Notes',
    List<String>? attachments,
  })  : title = InputSanitizer.sanitize(title),
        content = InputSanitizer.sanitize(content),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        tags = tags ?? const [],
        attachments = attachments ?? const [];

  DiaryEntry copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    SourceType? sourceType,
    double? confidence,
    bool? isArchived,
    bool? isPinned,
    String? category,
    List<String>? attachments,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      tags: tags ?? this.tags,
      sourceType: sourceType ?? this.sourceType,
      confidence: confidence ?? this.confidence,
      isArchived: isArchived ?? this.isArchived,
      isPinned: isPinned ?? this.isPinned,
      category: category ?? this.category,
      attachments: attachments ?? this.attachments,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'tags': tags,
      'sourceType': sourceType.name,
      'confidence': confidence,
      'isArchived': isArchived,
      'isPinned': isPinned,
      'category': category,
      'attachments': attachments,
      'schemaVersion': 2,
    };
  }

  factory DiaryEntry.fromMap(Map<dynamic, dynamic> map) {
    DateTime parsedCreatedAt;
    if (map['createdAt'] is String) {
      parsedCreatedAt =
          DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now();
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

    List<String> parsedTags = [];
    if (map['tags'] is List) {
      parsedTags = (map['tags'] as List).map((e) => e.toString()).toList();
    }

    List<String> parsedAttachments = [];
    if (map['attachments'] is List) {
      parsedAttachments =
          (map['attachments'] as List).map((e) => e.toString()).toList();
    }

    return DiaryEntry(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      content: map['content']?.toString() ?? '',
      createdAt: parsedCreatedAt,
      updatedAt: parsedUpdatedAt,
      tags: parsedTags,
      sourceType: SourceType.fromString(map['sourceType']?.toString()),
      confidence: (map['confidence'] is num)
          ? (map['confidence'] as num).toDouble()
          : 1.0,
      isArchived: map['isArchived'] == true,
      isPinned: map['isPinned'] == true,
      category: map['category']?.toString() ?? 'Notes',
      attachments: parsedAttachments,
    );
  }
}
