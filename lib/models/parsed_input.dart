import 'recurrence_rule.dart';
import 'reminder.dart';

enum IntentType {
  reminder,
  diary,
  ambiguous,
  futureEvent,
  offTopic;

  String get displayName {
    switch (this) {
      case IntentType.reminder:
        return 'Reminder';
      case IntentType.diary:
        return 'Diary';
      case IntentType.ambiguous:
        return 'Needs Clarification';
      case IntentType.futureEvent:
        return 'Future Event';
      case IntentType.offTopic:
        return 'General Query';
    }
  }
}

class ParsedInput {
  final IntentType intent;
  final String originalText;
  final double confidence;
  final String title;
  final String description;
  final DateTime? dueDate;
  final RecurrenceType recurrence;
  final List<String> tags;
  final SourceType sourceType;
  final String explanation;
  final bool isPastTime;
  final bool isAmbiguousTime;
  final DateTime? suggestedAlternativeDate;
  final String? clarificationPrompt;

  ParsedInput({
    required this.intent,
    required this.originalText,
    required this.confidence,
    required this.title,
    this.description = '',
    this.dueDate,
    this.recurrence = RecurrenceType.none,
    this.tags = const [],
    this.sourceType = SourceType.text,
    this.explanation = '',
    this.isPastTime = false,
    this.isAmbiguousTime = false,
    this.suggestedAlternativeDate,
    this.clarificationPrompt,
  });

  bool get isAutoApproved =>
      confidence >= 0.85 &&
      intent == IntentType.reminder &&
      !isPastTime &&
      !isAmbiguousTime &&
      dueDate != null;

  bool get needsConfirmation =>
      (confidence >= 0.60 && confidence < 0.85) ||
      isPastTime ||
      isAmbiguousTime ||
      intent == IntentType.futureEvent ||
      intent == IntentType.offTopic;

  bool get needsClarification =>
      confidence < 0.60 || intent == IntentType.ambiguous || isAmbiguousTime;

  ParsedInput copyWith({
    IntentType? intent,
    String? originalText,
    double? confidence,
    String? title,
    String? description,
    DateTime? dueDate,
    RecurrenceType? recurrence,
    List<String>? tags,
    SourceType? sourceType,
    String? explanation,
    bool? isPastTime,
    bool? isAmbiguousTime,
    DateTime? suggestedAlternativeDate,
    String? clarificationPrompt,
  }) {
    return ParsedInput(
      intent: intent ?? this.intent,
      originalText: originalText ?? this.originalText,
      confidence: confidence ?? this.confidence,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      recurrence: recurrence ?? this.recurrence,
      tags: tags ?? this.tags,
      sourceType: sourceType ?? this.sourceType,
      explanation: explanation ?? this.explanation,
      isPastTime: isPastTime ?? this.isPastTime,
      isAmbiguousTime: isAmbiguousTime ?? this.isAmbiguousTime,
      suggestedAlternativeDate:
          suggestedAlternativeDate ?? this.suggestedAlternativeDate,
      clarificationPrompt: clarificationPrompt ?? this.clarificationPrompt,
    );
  }
}
