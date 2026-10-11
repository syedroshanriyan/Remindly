import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

enum SpeechState {
  idle,
  listening,
  processing,
  done,
  error;

  String get displayLabel {
    switch (this) {
      case SpeechState.idle:
        return 'Tap microphone to speak';
      case SpeechState.listening:
        return 'Listening...';
      case SpeechState.processing:
        return 'Understanding...';
      case SpeechState.done:
        return 'Completed';
      case SpeechState.error:
        return 'Tap to retry voice';
    }
  }
}

class SpeechService extends ChangeNotifier {
  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;
  SpeechService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isAvailable = false;
  SpeechState _state = SpeechState.idle;
  String _currentTranscript = '';
  String _lastError = '';
  double _soundLevel = 0.0;
  bool _preferOnDevice = true;

  // Continuous Session & Long Pause Management
  bool _isSessionActive = false;
  String _sessionAccumulatedText = '';
  String _currentSegmentText = '';
  Timer? _silenceTimer;
  Function(String transcript, bool isFinal)? _currentResultCallback;
  VoidCallback? _onDoneCallback;
  String? _currentLocaleId;

  // 5.5 seconds of unbroken silence represents a deliberate long pause (like Google Gemini)
  static const Duration silenceTimeout = Duration(milliseconds: 5500);

  bool _isRestarting = false;
  int _restartAttempts = 0;

  bool get isAvailable => _isAvailable;
  bool get isListening => _state == SpeechState.listening;
  SpeechState get state => _state;
  String get currentTranscript => _currentTranscript;
  String get lastError => _lastError;
  double get soundLevel => _soundLevel;

  Future<bool> initialize() async {
    if (_isAvailable) return true;

    try {
      _isAvailable = await _speech.initialize(
        onStatus: _handleStatusChange,
        onError: (errorNotification) {
          debugPrint('SpeechService error: ${errorNotification.errorMsg}');
          if (_preferOnDevice) {
            _preferOnDevice = false;
          }
          if (_isSessionActive) {
            // Android speech engine returns transient error codes on short pauses
            // e.g. error_no_match (7), error_speech_timeout (6), error_busy (8), error_client (5).
            // Do NOT terminate the continuous session! Keep accumulated speech safe,
            // commit the current segment, and smoothly resume listening.
            _commitCurrentSegment();
            _restartNativeListening();
            return;
          }
          _lastError = errorNotification.errorMsg;
          _state = SpeechState.error;
          notifyListeners();
        },
        debugLogging: kDebugMode,
      );
      notifyListeners();
      return _isAvailable;
    } catch (e) {
      _lastError = 'Failed to initialize speech recognizer: $e';
      _isAvailable = false;
      _state = SpeechState.error;
      notifyListeners();
      return false;
    }
  }

  void _handleStatusChange(String status) {
    if (status == 'listening') {
      _state = SpeechState.listening;
      notifyListeners();
    } else if (status == 'notListening' || status == 'done') {
      if (_isSessionActive) {
        // Native OS stopped due to a short 1.5 - 2s silence.
        // Commit current segment to accumulated text and auto-restart listening
        // so the session stays open until a real long pause (5.5s) or explicit user tap.
        _commitCurrentSegment();
        _restartNativeListening();
      } else {
        if (_state == SpeechState.listening) {
          _state = SpeechState.done;
          notifyListeners();
          _onDoneCallback?.call();
        }
      }
    }
  }

  String _combineText(String accumulated, String segment) {
    final acc = accumulated.trim();
    final seg = segment.trim();
    if (acc.isEmpty) return seg;
    if (seg.isEmpty) return acc;

    final lowerAcc = acc.toLowerCase();
    final lowerSeg = seg.toLowerCase();

    // If segment is already a cumulative transcript that starts with accumulated text,
    // use the newer full transcript directly to avoid repeating sentences.
    if (lowerSeg.startsWith(lowerAcc)) {
      return seg;
    }

    // If accumulated text already ends with this segment, avoid duplicate append.
    if (lowerAcc.endsWith(lowerSeg)) {
      return acc;
    }

    return '$acc $seg';
  }

  void _commitCurrentSegment() {
    final trimmed = _currentSegmentText.trim();
    if (trimmed.isNotEmpty) {
      _sessionAccumulatedText = _combineText(_sessionAccumulatedText, trimmed);
      _currentSegmentText = '';
      _currentTranscript = _sessionAccumulatedText;
      _currentResultCallback?.call(_currentTranscript, false);
      notifyListeners();
    }
  }

  void _restartNativeListening() {
    if (!_isSessionActive || _isRestarting) return;
    _isRestarting = true;

    // Android SpeechRecognizer takes ~350ms to release audio hardware cleanly
    Future.delayed(const Duration(milliseconds: 350), () async {
      _isRestarting = false;
      if (!_isSessionActive) return;

      try {
        if (_speech.isListening) {
          await _speech.stop();
          await Future.delayed(const Duration(milliseconds: 150));
        }
        if (_isSessionActive && !_speech.isListening) {
          await _listenNative();
          _restartAttempts = 0;
        }
      } catch (e) {
        debugPrint('SpeechService restart error: $e');
        if (_isSessionActive && _restartAttempts < 6) {
          _restartAttempts++;
          Future.delayed(Duration(milliseconds: 300 * _restartAttempts), () {
            _restartNativeListening();
          });
        }
      }
    });
  }

  void _resetSilenceTimer() {
    _silenceTimer?.cancel();
    if (!_isSessionActive) return;
    _silenceTimer = Timer(silenceTimeout, () {
      if (_isSessionActive) {
        _finishSession();
      }
    });
  }

  Future<void> _listenNative() async {
    if (!_isAvailable) return;

    void onResultCallback(dynamic result) {
      _resetSilenceTimer();
      final recognized = result.recognizedWords.trim();
      _currentSegmentText = recognized;

      final fullText = _combineText(_sessionAccumulatedText, _currentSegmentText);

      _currentTranscript = fullText;
      _currentResultCallback?.call(fullText, false);
      notifyListeners();

      if (result.finalResult) {
        _commitCurrentSegment();
      }
    }

    void onSoundLevelCallback(double level) {
      _soundLevel = level;
      if (level > 1.8) {
        _resetSilenceTimer();
      }
      notifyListeners();
    }

    try {
      await _speech.listen(
        onResult: onResultCallback,
        onSoundLevelChange: onSoundLevelCallback,
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          cancelOnError: false,
          partialResults: true,
          onDevice: _preferOnDevice,
          listenFor: const Duration(seconds: 180),
          pauseFor: const Duration(seconds: 10),
          localeId: _currentLocaleId,
        ),
      );
    } catch (e) {
      debugPrint('SpeechService listen exception: $e');
      if (_preferOnDevice) {
        _preferOnDevice = false;
        try {
          await _speech.listen(
            onResult: onResultCallback,
            onSoundLevelChange: onSoundLevelCallback,
            listenOptions: stt.SpeechListenOptions(
              listenMode: stt.ListenMode.dictation,
              cancelOnError: false,
              partialResults: true,
              onDevice: false,
              listenFor: const Duration(seconds: 180),
              pauseFor: const Duration(seconds: 10),
              localeId: _currentLocaleId,
            ),
          );
        } catch (_) {}
      }
    }
  }

  Future<void> startListening({
    required Function(String transcript, bool isFinal) onResult,
    VoidCallback? onDone,
    String? localeId,
  }) async {
    _silenceTimer?.cancel();
    _currentTranscript = '';
    _sessionAccumulatedText = '';
    _currentSegmentText = '';
    _lastError = '';
    _soundLevel = 0.0;
    _onDoneCallback = onDone;
    _currentResultCallback = onResult;
    _currentLocaleId = localeId;
    _isSessionActive = true;

    if (!_isAvailable) {
      final ok = await initialize();
      if (!ok) {
        _isSessionActive = false;
        _lastError = 'Microphone permission or speech engine unavailable.';
        _state = SpeechState.error;
        notifyListeners();
        return;
      }
    }

    _state = SpeechState.listening;
    notifyListeners();
    _resetSilenceTimer();

    await _listenNative();
  }

  Future<void> _finishSession() async {
    _silenceTimer?.cancel();
    if (!_isSessionActive && _state != SpeechState.listening) return;

    _isSessionActive = false;
    _commitCurrentSegment();

    final finalTranscript = _sessionAccumulatedText.trim();
    _currentTranscript = finalTranscript;
    _state = SpeechState.processing;
    notifyListeners();

    try {
      if (_speech.isListening) {
        await _speech.stop();
      }
    } catch (_) {}

    _state = SpeechState.done;
    _currentResultCallback?.call(finalTranscript, true);
    notifyListeners();
    _onDoneCallback?.call();
  }

  Future<void> stopListening() async {
    await _finishSession();
  }

  Future<void> cancelListening() async {
    _silenceTimer?.cancel();
    _isSessionActive = false;
    _sessionAccumulatedText = '';
    _currentSegmentText = '';
    _currentTranscript = '';
    try {
      if (_speech.isListening) {
        await _speech.cancel();
      }
    } catch (_) {}
    _state = SpeechState.idle;
    notifyListeners();
  }

  void reset() {
    _silenceTimer?.cancel();
    _isSessionActive = false;
    _sessionAccumulatedText = '';
    _currentSegmentText = '';
    _state = SpeechState.idle;
    _currentTranscript = '';
    _lastError = '';
    _soundLevel = 0.0;
    notifyListeners();
  }
}
