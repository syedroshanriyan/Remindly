import 'package:flutter/material.dart';
import '../core/utils/id_generator.dart';
import '../models/diary_entry.dart';
import '../models/parsed_input.dart';
import '../models/reminder.dart';
import '../services/command_parser.dart';
import '../services/speech_service.dart';
import 'diary_provider.dart';
import 'reminder_provider.dart';

enum VoiceMode {
  general,
  diary,
  reminder,
  task,
  search;

  String get displayName {
    switch (this) {
      case VoiceMode.general:
        return 'Voice Intelligence';
      case VoiceMode.diary:
        return 'Voice Diary';
      case VoiceMode.reminder:
        return 'Voice Reminder';
      case VoiceMode.task:
        return 'Voice Task';
      case VoiceMode.search:
        return 'Voice Search';
    }
  }

  String get promptText {
    switch (this) {
      case VoiceMode.general:
        return 'Tap the microphone to speak';
      case VoiceMode.diary:
        return 'Speak your thoughts, reflections or daily log';
      case VoiceMode.reminder:
        return 'Say "Remind me to..." with time and date';
      case VoiceMode.task:
        return 'Say your action item or todo';
      case VoiceMode.search:
        return 'Speak what you want to find';
    }
  }
}

enum VoiceProcessingState {
  idle,
  listening,
  processing,
  result,
  confirmation,
  success,
  error;

  String get statusMessage {
    switch (this) {
      case VoiceProcessingState.idle:
        return 'Tap microphone to start';
      case VoiceProcessingState.listening:
        return 'Listening...';
      case VoiceProcessingState.processing:
        return 'Understanding your reminder...';
      case VoiceProcessingState.result:
        return 'Ready for review';
      case VoiceProcessingState.confirmation:
        return 'Please confirm details';
      case VoiceProcessingState.success:
        return 'Saved successfully!';
      case VoiceProcessingState.error:
        return 'Could not process audio';
    }
  }
}

class InputProvider extends ChangeNotifier {
  final CommandParser _parser;
  final SpeechService _speechService;

  String _currentInput = '';
  ParsedInput? _parsedInput;
  bool _isProcessing = false;
  VoiceProcessingState _voiceState = VoiceProcessingState.idle;
  String _processingMessage = '';
  VoiceMode _activeMode = VoiceMode.general;
  String _lastSavedTitle = '';
  IntentType? _lastSavedType;
  bool _hasAutoSavedCurrent = false;

  InputProvider({
    CommandParser? parser,
    SpeechService? speechService,
  })  : _parser = parser ?? CommandParser(),
        _speechService = speechService ?? SpeechService();

  String get currentInput => _currentInput;
  ParsedInput? get parsedInput => _parsedInput;
  bool get isProcessing => _isProcessing;
  bool get isListening => _speechService.isListening;
  VoiceProcessingState get voiceState => _voiceState;
  String get processingMessage => _processingMessage.isNotEmpty
      ? _processingMessage
      : _voiceState.statusMessage;
  SpeechState get speechState => _speechService.state;
  String get speechError => _speechService.lastError;
  double get soundLevel => _speechService.soundLevel;
  VoiceMode get activeMode => _activeMode;
  String get lastSavedTitle => _lastSavedTitle;
  IntentType? get lastSavedType => _lastSavedType;

  void setVoiceMode(VoiceMode mode) {
    _activeMode = mode;
    notifyListeners();
  }

  void setInputText(String text) {
    _currentInput = text;
    notifyListeners();
  }

  void updateTranscript(String editedTranscript) {
    _currentInput = editedTranscript;
    if (editedTranscript.trim().isNotEmpty) {
      _parsedInput =
          _parser.parse(editedTranscript, sourceType: SourceType.voice);
    }
    notifyListeners();
  }

  Future<ParsedInput> processTextInput(String text) async {
    _currentInput = text;
    _isProcessing = true;
    _voiceState = VoiceProcessingState.processing;
    _processingMessage = 'Understanding your input...';
    notifyListeners();

    final result = _parser.parse(text, sourceType: SourceType.text);
    _parsedInput = result;
    _isProcessing = false;
    _voiceState = (result.needsConfirmation || result.needsClarification)
        ? VoiceProcessingState.confirmation
        : VoiceProcessingState.result;
    _processingMessage = '';
    notifyListeners();

    return result;
  }

  Future<void> startVoiceListening({
    ReminderProvider? reminderProvider,
    DiaryProvider? diaryProvider,
    bool autoSaveOnFinish = false,
  }) async {
    _currentInput = '';
    _parsedInput = null;
    _lastSavedTitle = '';
    _lastSavedType = null;
    _hasAutoSavedCurrent = false;
    _voiceState = VoiceProcessingState.listening;
    _processingMessage = 'Listening...';
    notifyListeners();

    await _speechService.startListening(
      onResult: (transcript, isFinal) {
        _currentInput = transcript;
        if (transcript.trim().isNotEmpty) {
          // Live interim parse using the unified pipeline
          _parsedInput =
              _parser.parse(transcript, sourceType: SourceType.voice);
        }
        notifyListeners();
      },
      onDone: () async {
        if (_currentInput.trim().isNotEmpty) {
          await _handleVoiceFinalTranscript(
            transcript: _currentInput,
            reminderProvider: reminderProvider,
            diaryProvider: diaryProvider,
            autoSaveOnFinish: autoSaveOnFinish,
          );
        }
      },
    );
  }

  Future<void> _handleVoiceFinalTranscript({
    required String transcript,
    ReminderProvider? reminderProvider,
    DiaryProvider? diaryProvider,
    required bool autoSaveOnFinish,
  }) async {
    _voiceState = VoiceProcessingState.processing;
    _processingMessage = 'Analyzing your note...';
    notifyListeners();

    // Small delay for clean UX feedback
    await Future.delayed(const Duration(milliseconds: 250));
    _processingMessage = 'Checking date, time and details...';
    notifyListeners();

    final result = _parser.parse(transcript, sourceType: SourceType.voice);
    _parsedInput = result;

    // Check if clarification or past time confirmation is required
    final requiresUserIntervention = result.isPastTime ||
        result.isAmbiguousTime ||
        result.needsClarification ||
        result.needsConfirmation ||
        result.intent == IntentType.futureEvent ||
        result.intent == IntentType.offTopic;

    if (requiresUserIntervention) {
      _voiceState = VoiceProcessingState.confirmation;
      _processingMessage = '';
      notifyListeners();
      return;
    }

    if (autoSaveOnFinish &&
        reminderProvider != null &&
        diaryProvider != null &&
        result.isAutoApproved) {
      _executeAutoSave(
        input: result,
        reminderProvider: reminderProvider,
        diaryProvider: diaryProvider,
      );
      _voiceState = VoiceProcessingState.success;
      _processingMessage = '';
    } else {
      _voiceState = VoiceProcessingState.result;
      _processingMessage = 'Complete! Choose action below:';
    }
    notifyListeners();
  }

  Future<void> stopVoiceListening({
    ReminderProvider? reminderProvider,
    DiaryProvider? diaryProvider,
    bool autoSaveOnFinish = false,
  }) async {
    await _speechService.stopListening();
    if (_currentInput.trim().isNotEmpty) {
      await _handleVoiceFinalTranscript(
        transcript: _currentInput,
        reminderProvider: reminderProvider,
        diaryProvider: diaryProvider,
        autoSaveOnFinish: autoSaveOnFinish,
      );
    } else {
      _voiceState = VoiceProcessingState.idle;
      _processingMessage = '';
    }
    notifyListeners();
  }

  void _executeAutoSave({
    required ParsedInput input,
    required ReminderProvider reminderProvider,
    required DiaryProvider diaryProvider,
  }) {
    if (_hasAutoSavedCurrent) return;
    _hasAutoSavedCurrent = true;

    if (input.intent == IntentType.reminder) {
      final dueDate =
          input.dueDate ?? DateTime.now().add(const Duration(hours: 1));
      final reminder = Reminder(
        id: IdGenerator.newId(),
        title: input.title.isNotEmpty ? input.title : input.originalText,
        description: input.description,
        dueDate: dueDate,
        recurrence: input.recurrence,
        sourceType: input.sourceType,
        sourceText: input.originalText,
        confidence: input.confidence,
        voiceEnabled: true,
      );
      reminderProvider.addReminder(reminder);
      _lastSavedTitle = reminder.title;
      _lastSavedType = IntentType.reminder;
    } else if (input.intent == IntentType.diary ||
        input.intent == IntentType.futureEvent) {
      final diary = DiaryEntry(
        id: IdGenerator.newId(),
        title: input.title.isNotEmpty ? input.title : 'Voice Note',
        content: input.originalText,
        tags: input.tags.isNotEmpty ? input.tags : ['Voice'],
        sourceType: input.sourceType,
        confidence: input.confidence,
      );
      diaryProvider.addEntry(diary);
      _lastSavedTitle = diary.title;
      _lastSavedType = IntentType.diary;
    }
    notifyListeners();
  }

  Future<void> cancelVoiceListening() async {
    await _speechService.cancelListening();
    _currentInput = '';
    _parsedInput = null;
    _hasAutoSavedCurrent = false;
    _voiceState = VoiceProcessingState.idle;
    _processingMessage = '';
    _speechService.reset();
    notifyListeners();
  }

  void saveConfirmedInput({
    required ParsedInput input,
    required ReminderProvider reminderProvider,
    required DiaryProvider diaryProvider,
    DateTime? overrideDueDate,
  }) {
    if (input.intent == IntentType.reminder ||
        input.intent == IntentType.futureEvent) {
      final dueDate = overrideDueDate ??
          input.dueDate ??
          DateTime.now().add(const Duration(hours: 1));
      final reminder = Reminder(
        id: IdGenerator.newId(),
        title: input.title.isNotEmpty ? input.title : input.originalText,
        description: input.description,
        dueDate: dueDate,
        recurrence: input.recurrence,
        sourceType: input.sourceType,
        sourceText: input.originalText,
        confidence: input.confidence,
        voiceEnabled: true,
      );
      reminderProvider.addReminder(reminder);
      _lastSavedTitle = reminder.title;
      _lastSavedType = IntentType.reminder;
    } else {
      final diary = DiaryEntry(
        id: IdGenerator.newId(),
        title: input.title.isNotEmpty ? input.title : 'Voice Note',
        content: input.description.isNotEmpty
            ? input.description
            : input.originalText,
        tags: input.tags.isNotEmpty ? input.tags : ['Voice'],
        sourceType: input.sourceType,
        confidence: input.confidence,
      );
      diaryProvider.addEntry(diary);
      _lastSavedTitle = diary.title;
      _lastSavedType = IntentType.diary;
    }

    _currentInput = '';
    _parsedInput = null;
    _voiceState = VoiceProcessingState.success;
    _processingMessage = 'Saved!';
    notifyListeners();
  }

  void clear() {
    _currentInput = '';
    _parsedInput = null;
    _isProcessing = false;
    _lastSavedTitle = '';
    _lastSavedType = null;
    _hasAutoSavedCurrent = false;
    _voiceState = VoiceProcessingState.idle;
    _processingMessage = '';
    _speechService.reset();
    notifyListeners();
  }
}
