import '../models/parsed_input.dart';
import '../models/reminder.dart';
import 'entity_extractor.dart';
import 'intent_classifier.dart';

class CommandParser {
  final IntentClassifier _classifier;

  CommandParser({IntentClassifier? classifier})
      : _classifier = classifier ?? IntentClassifier();

  ParsedInput parse(
    String rawText, {
    SourceType sourceType = SourceType.text,
    DateTime? referenceNow,
  }) {
    final text = rawText.trim();
    if (text.isEmpty) {
      return ParsedInput(
        intent: IntentType.ambiguous,
        originalText: rawText,
        confidence: 0.0,
        title: '',
        explanation: 'Input was empty.',
        sourceType: sourceType,
      );
    }

    // 1. Intent Detection
    final classification = _classifier.classify(text);
    final intent = classification.intent;
    final confidence = classification.confidence;
    final now = referenceNow ?? DateTime.now();

    // 2. Routing based on Intent
    if (intent == IntentType.reminder) {
      final entities = EntityExtractor.extract(text, referenceNow: now);
      final dueDate = entities.dueDate;

      double effectiveConfidence = confidence;
      String explanation = 'Classified as Reminder.';

      if (entities.isPastTime) {
        effectiveConfidence = 0.60;
        explanation = entities.clarificationPrompt ??
            'The requested time today has already passed.';
      } else if (entities.isAmbiguousTime) {
        effectiveConfidence = 0.60;
        explanation =
            entities.clarificationPrompt ?? 'Time or day needs clarification.';
      } else if (dueDate == null) {
        effectiveConfidence = 0.65;
        explanation = 'Reminder detected, but date and time need confirmation.';
      }

      return ParsedInput(
        intent: IntentType.reminder,
        originalText: text,
        confidence: effectiveConfidence,
        title: entities.title.isNotEmpty ? entities.title : text,
        description: entities.description,
        dueDate: dueDate,
        recurrence: entities.recurrence,
        sourceType: sourceType,
        explanation: explanation,
        isPastTime: entities.isPastTime,
        isAmbiguousTime: entities.isAmbiguousTime,
        suggestedAlternativeDate: entities.suggestedAlternativeDate,
        clarificationPrompt: entities.clarificationPrompt,
      );
    } else if (intent == IntentType.futureEvent) {
      // Future event in diary entry
      final entities = EntityExtractor.extract(text, referenceNow: now);
      final dueDate = entities.dueDate;
      final isFuture = dueDate != null && dueDate.isAfter(now);

      return ParsedInput(
        intent: isFuture ? IntentType.futureEvent : IntentType.diary,
        originalText: text,
        confidence: confidence,
        title: entities.title.isNotEmpty
            ? entities.title
            : _generateDiaryTitle(text),
        description: text,
        dueDate: isFuture ? dueDate : null,
        recurrence: entities.recurrence,
        tags: _extractTags(text),
        sourceType: sourceType,
        explanation: isFuture
            ? 'I noticed this is a future event. Would you like to create a reminder?'
            : 'Classified as Personal Diary Entry.',
      );
    } else if (intent == IntentType.offTopic) {
      return ParsedInput(
        intent: IntentType.offTopic,
        originalText: text,
        confidence: confidence,
        title: _generateDiaryTitle(text),
        description: text,
        tags: ['General'],
        sourceType: sourceType,
        explanation:
            "This doesn't appear to be a diary entry. Would you like to save it in your diary anyway?",
      );
    } else if (intent == IntentType.diary) {
      final tags = _extractTags(text);
      final title = _generateDiaryTitle(text);

      return ParsedInput(
        intent: IntentType.diary,
        originalText: text,
        confidence: confidence,
        title: title,
        description: text,
        tags: tags,
        sourceType: sourceType,
        explanation: 'Classified as Personal Diary Entry.',
      );
    } else {
      // Ambiguous
      final entities = EntityExtractor.extract(text, referenceNow: now);
      return ParsedInput(
        intent: IntentType.ambiguous,
        originalText: text,
        confidence: confidence,
        title: entities.title.isNotEmpty ? entities.title : text,
        dueDate: entities.dueDate,
        recurrence: entities.recurrence,
        sourceType: sourceType,
        explanation:
            'Input is ambiguous. Did you mean to save a reminder or journal this?',
        isPastTime: entities.isPastTime,
        isAmbiguousTime: entities.isAmbiguousTime,
        clarificationPrompt: entities.clarificationPrompt,
      );
    }
  }

  List<String> _extractTags(String text) {
    final tagMatches = RegExp(r'#(\w+)').allMatches(text);
    final tags = tagMatches.map((m) => m.group(1)!.toLowerCase()).toList();

    // Contextual tag suggestions if no explicit hashtags
    if (tags.isEmpty) {
      final lower = text.toLowerCase();
      if (lower.contains('work') ||
          lower.contains('project') ||
          lower.contains('meeting')) {
        tags.add('work');
      }
      if (lower.contains('family') ||
          lower.contains('mom') ||
          lower.contains('dad')) {
        tags.add('family');
      }
      if (lower.contains('grateful') ||
          lower.contains('peace') ||
          lower.contains('calm')) {
        tags.add('gratitude');
      }
      if (lower.contains('workout') ||
          lower.contains('run') ||
          lower.contains('gym')) {
        tags.add('health');
      }
      if (tags.isEmpty) {
        tags.add('daily');
      }
    }
    return tags;
  }

  String _generateDiaryTitle(String text) {
    final firstSentence = text.split(RegExp(r'[.\n!?]')).first.trim();
    if (firstSentence.length <= 40 && firstSentence.isNotEmpty) {
      return firstSentence[0].toUpperCase() + firstSentence.substring(1);
    }
    final words = text.split(RegExp(r'\s+')).take(6).join(' ');
    if (words.isNotEmpty) {
      return '${words[0].toUpperCase()}${words.substring(1)}...';
    }
    return 'Journal Entry';
  }
}
