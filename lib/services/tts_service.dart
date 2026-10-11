import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await _flutterTts.setSpeechRate(0.48);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.awaitSynthCompletion(false);
      try {
        await _flutterTts.setQueueMode(0);
      } catch (_) {}
      _isInitialized = true;
    } catch (e) {
      debugPrint('TTSService init warning: $e');
      _isInitialized = false;
    }
  }

  Future<void> setSpeechRate(double rate) async {
    try {
      await _flutterTts.setSpeechRate(rate);
    } catch (_) {}
  }

  /// Intelligently formats reminder titles into natural, conversational spoken announcements.
  /// E.g.:
  /// - "medicine" -> "It's time to take your medicine."
  /// - "take medicine" -> "It's time to take your medicine."
  /// - "water" -> "It's time to drink water."
  /// - "call mom" -> "It's time to call your mom."
  /// - "doctor appointment" -> "It's time for your doctor appointment."
  /// - "team standup" -> "It's time for team standup."
  /// - "gym" -> "It's time to hit the gym."
  /// - "pay electricity bill" -> "It's time to pay your electricity bill."
  static String formatAnnouncement(String rawTitle,
      {String? notes, String? userName}) {
    if (rawTitle.trim().isEmpty) {
      return "It's time for your scheduled reminder.";
    }

    String text = rawTitle.trim();

    // 1. Strip trailing punctuation
    text = text.replaceAll(RegExp(r'[\.!?,;:]+$'), '').trim();

    // 2. Strip leading voice / reminder trigger prefixes
    final prefixPatterns = [
      RegExp(r'^(please\s+)?remind\s+me\s+to\s+', caseSensitive: false),
      RegExp(r'^(please\s+)?remind\s+me\s+for\s+', caseSensitive: false),
      RegExp(r'^(please\s+)?remind\s+me\s+about\s+', caseSensitive: false),
      RegExp(r'^(please\s+)?remind\s+me\s+', caseSensitive: false),
      RegExp(r'^reminder\s+to\s+', caseSensitive: false),
      RegExp(r'^reminder\s+for\s+', caseSensitive: false),
      RegExp(r'^reminder\s+about\s+', caseSensitive: false),
      RegExp(r'^reminder\s*:\s*', caseSensitive: false),
      RegExp(r'^remember\s+to\s+', caseSensitive: false),
      RegExp(r'^remember\s+for\s+', caseSensitive: false),
      RegExp(r"^don'?t\s+forget\s+to\s+", caseSensitive: false),
      RegExp(r"^it'?s\s+time\s+to\s+", caseSensitive: false),
      RegExp(r"^it'?s\s+time\s+for\s+", caseSensitive: false),
      RegExp(r'^time\s+to\s+', caseSensitive: false),
      RegExp(r'^time\s+for\s+', caseSensitive: false),
    ];

    for (final pattern in prefixPatterns) {
      if (text.contains(pattern)) {
        text = text.replaceFirst(pattern, '').trim();
      }
    }

    if (text.isEmpty) {
      return "It's time for your reminder.";
    }

    // 3. Normalize first-person pronouns to second-person ("call my mom" -> "call your mom")
    text = text.replaceAll(RegExp(r'\bmy\b', caseSensitive: false), 'your');
    text = text.replaceAll(RegExp(r'\bme\b', caseSensitive: false), 'you');

    final lower = text.toLowerCase();
    String speech = '';

    // Domain A: Medication & Health
    final medKeywords = [
      'medicine',
      'medication',
      'meds',
      'pill',
      'pills',
      'tablet',
      'tablets',
      'dose',
      'dosage',
      'insulin',
      'drops',
      'syrup',
      'antibiotic',
      'antibiotics',
      'vitamin',
      'vitamins',
      'supplement',
      'supplements',
      'inhaler',
      'prescription'
    ];
    bool isMed = medKeywords.any((k) =>
        lower.split(RegExp(r'\s+')).contains(k) ||
        lower.endsWith(k) ||
        lower == k);
    if (isMed) {
      if (lower.startsWith('take ') ||
          lower.startsWith('have ') ||
          lower.startsWith('consume ')) {
        final words = text.split(' ');
        final rest = words.skip(1).join(' ').trim();
        if (!rest.toLowerCase().startsWith('your ') &&
            !rest.toLowerCase().startsWith('the ')) {
          speech = "It's time to take your $rest.";
        } else {
          speech = "It's time to $text.";
        }
      } else {
        if (lower.startsWith('your ') || lower.startsWith('the ')) {
          speech = "It's time to take $text.";
        } else {
          speech = "It's time to take your $text.";
        }
      }
    }

    // Domain B: Hydration
    if (speech.isEmpty) {
      if (lower == 'water' ||
          lower == 'drink water' ||
          lower == 'glass of water' ||
          lower == 'hydrate') {
        speech = "It's time to drink water.";
      } else if (lower.startsWith('drink ')) {
        speech = "It's time to $text.";
      }
    }

    // Domain C: Meals & Nutrition
    if (speech.isEmpty) {
      final mealKeywords = [
        'breakfast',
        'lunch',
        'dinner',
        'snack',
        'evening snack',
        'supper',
        'brunch',
        'meal',
        'coffee',
        'tea'
      ];
      for (final m in mealKeywords) {
        if (lower == m || lower == 'my $m' || lower == 'your $m') {
          speech = "It's time for $m.";
          break;
        } else if (lower.startsWith('eat ') ||
            lower.startsWith('have ') ||
            lower.startsWith('make ') ||
            lower.startsWith('cook ')) {
          if (lower.contains(m)) {
            speech = "It's time to $text.";
            break;
          }
        }
      }
    }

    // Domain D: Events, Meetings & Appointments
    if (speech.isEmpty) {
      final eventKeywords = [
        'meeting',
        'standup',
        'appointment',
        'consultation',
        'interview',
        'conference',
        'presentation',
        'demo',
        'pitch',
        'sync',
        'webinar',
        'session',
        'class',
        'lecture',
        'exam',
        'test',
        'checkup'
      ];
      bool isEvent = eventKeywords.any((e) => lower.contains(e));
      if (isEvent) {
        if (lower.startsWith('attend ') ||
            lower.startsWith('join ') ||
            lower.startsWith('go to ')) {
          speech = "It's time to $text.";
        } else if (lower.startsWith('your ') ||
            lower.startsWith('the ') ||
            lower.startsWith('our ') ||
            lower.startsWith('a ') ||
            lower.startsWith('an ')) {
          speech = "It's time for $text.";
        } else {
          speech = "It's time for your $text.";
        }
      }
    }

    // Domain E: Calls & Messages
    if (speech.isEmpty) {
      final commVerbs = [
        'call',
        'phone',
        'ring',
        'text',
        'message',
        'email',
        'mail',
        'ping',
        'contact',
        'reply to',
        'reach out to'
      ];
      for (final cv in commVerbs) {
        if (lower.startsWith('$cv ') || lower == cv) {
          speech = "It's time to $text.";
          break;
        }
      }
    }

    // Domain F: Fitness & Wellness
    if (speech.isEmpty) {
      if (lower == 'gym') {
        speech = "It's time to hit the gym.";
      } else if (lower == 'workout') {
        speech = "It's time for your workout.";
      } else if (lower == 'yoga') {
        speech = "It's time for yoga.";
      } else if (lower == 'meditation') {
        speech = "It's time for meditation.";
      } else {
        final fitVerbs = [
          'run',
          'jog',
          'walk',
          'stretch',
          'swim',
          'exercise',
          'cycle'
        ];
        for (final fv in fitVerbs) {
          if (lower.startsWith('$fv ') || lower == fv) {
            speech = "It's time to $text.";
            break;
          }
        }
      }
    }

    // Domain G: Bills & Payments
    if (speech.isEmpty) {
      if (lower.startsWith('pay ')) {
        speech = "It's time to $text.";
      } else if (lower.contains('bill') ||
          lower.contains('rent') ||
          lower.contains('fee') ||
          lower.contains('dues') ||
          lower.contains('subscription')) {
        if (lower.startsWith('your ') || lower.startsWith('the ')) {
          speech = "It's time to pay $text.";
        } else {
          speech = "It's time to pay the $text.";
        }
      }
    }

    // Domain H: Action Verbs
    if (speech.isEmpty) {
      final actionVerbs = [
        'buy',
        'purchase',
        'clean',
        'wash',
        'vacuum',
        'read',
        'study',
        'write',
        'finish',
        'complete',
        'submit',
        'send',
        'check',
        'review',
        'update',
        'renew',
        'pick up',
        'drop off',
        'feed',
        'water',
        'fix',
        'repair',
        'organize',
        'pack',
        'order',
        'cook',
        'bake',
        'prepare',
        'schedule',
        'book',
        'cancel',
        'visit',
        'watch',
        'listen to',
        'turn off',
        'turn on',
        'lock',
        'sleep',
        'wake up',
        'rest',
        'relax'
      ];
      for (final v in actionVerbs) {
        if (lower.startsWith('$v ') || lower == v) {
          speech = "It's time to $text.";
          break;
        }
      }
    }

    // Domain I: Starts with preposition "to" or "for"
    if (speech.isEmpty) {
      if (lower.startsWith('to ')) {
        speech = "It's time $text.";
      } else if (lower.startsWith('for ')) {
        speech = "It's time $text.";
      }
    }

    // Domain J: Starts with determiners ("the", "a", "an", "your")
    if (speech.isEmpty) {
      if (lower.startsWith('the ') ||
          lower.startsWith('a ') ||
          lower.startsWith('an ') ||
          lower.startsWith('your ')) {
        speech = "It's time for $text.";
      }
    }

    // Fallback: General natural phrasing
    if (speech.isEmpty) {
      speech = "It's time for $text.";
    }

    // Punctuation check on primary sentence
    if (!speech.endsWith('.')) {
      speech = '$speech.';
    }

    // Domain K: Contextual Notes appending
    if (notes != null && notes.trim().isNotEmpty) {
      final cleanNotes =
          notes.trim().replaceAll(RegExp(r'[\.!?,;:]+$'), '').trim();
      if (cleanNotes.isNotEmpty &&
          cleanNotes.length <= 90 &&
          !lower.contains(cleanNotes.toLowerCase())) {
        speech = '$speech $cleanNotes.';
      }
    }

    return speech;
  }

  Future<void> announceReminder(String title,
      {String? notes, bool isMuted = false}) async {
    if (isMuted) return;

    final announcement = formatAnnouncement(title, notes: notes);
    await speak(announcement);
  }

  Future<void> testVoiceAnnouncement({String? sampleText}) async {
    final text = sampleText ??
        formatAnnouncement('Medicine', notes: 'Take 2 pills with water');
    await speak(text);
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    try {
      await init();
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('TTSService speak error: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (_) {}
  }
}
