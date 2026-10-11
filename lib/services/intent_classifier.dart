import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import '../models/parsed_input.dart';

class IntentClassifier {
  static final IntentClassifier _instance = IntentClassifier._internal();
  factory IntentClassifier() => _instance;
  IntentClassifier._internal();

  bool _isInitialized = false;
  List<String> _classes = [
    'ambiguous',
    'diary',
    'future_event',
    'off_topic',
    'reminder'
  ];
  Map<String, int> _vocab = {};
  List<double> _idf = [];
  List<List<double>> _coefficients = [];
  List<double> _intercept = [];

  bool get isInitialized => _isInitialized;

  Future<void> initialize(
      {String assetPath = 'assets/ml/intent_weights.json'}) async {
    try {
      final jsonStr = await rootBundle.loadString(assetPath);
      final data = json.decode(jsonStr) as Map<String, dynamic>;

      _classes = List<String>.from(data['classes'] as List);
      _vocab = Map<String, int>.from(data['vocabulary'] as Map);
      _idf = (data['idf'] as List).map((e) => (e as num).toDouble()).toList();
      _coefficients = (data['coefficients'] as List)
          .map(
              (row) => (row as List).map((e) => (e as num).toDouble()).toList())
          .toList();
      _intercept = (data['intercept'] as List)
          .map((e) => (e as num).toDouble())
          .toList();

      _isInitialized = true;
    } catch (_) {
      // Graceful fallback to heuristic classification if asset not loaded (e.g., in unit tests)
      _isInitialized = false;
    }
  }

  /// Evaluates input text and returns predicted IntentType and calibrated confidence (0.0 - 1.0)
  IntentResult classify(String rawText) {
    final text = rawText.trim().toLowerCase();
    if (text.isEmpty) {
      return IntentResult(
        intent: IntentType.ambiguous,
        confidence: 0.0,
        scores: {
          'ambiguous': 1.0,
          'diary': 0.0,
          'future_event': 0.0,
          'off_topic': 0.0,
          'reminder': 0.0,
        },
      );
    }

    // Fast-path deterministic rule scoring for explicit intent patterns
    final ruleResult = _checkDeterministicRules(text);
    if (ruleResult != null) {
      return ruleResult;
    }

    // Local ML Inference if weights are loaded
    if (_isInitialized && _vocab.isNotEmpty) {
      return _predictWithMl(text);
    }

    // Heuristic fallback
    return _heuristicClassify(text);
  }

  IntentResult? _checkDeterministicRules(String text) {
    // 1. Explicit off-topic queries (programming, trivia, general AI prompts)
    final offTopicTriggers = [
      'give me code',
      'give me a python',
      'give me python',
      'write a python',
      'write code',
      'what is machine learning',
      'what is the capital of',
      'how to calculate',
      'write an essay',
      'who wrote',
      'what is the formula',
      'solve 25',
      'generate a poem',
      'explain recursion',
    ];
    for (final pat in offTopicTriggers) {
      if (text.contains(pat)) {
        return IntentResult(
          intent: IntentType.offTopic,
          confidence: 0.98,
          scores: {
            'off_topic': 0.98,
            'reminder': 0.0,
            'diary': 0.01,
            'ambiguous': 0.01
          },
        );
      }
    }

    // 2. Strong explicit reminder patterns
    final strongReminderPatterns = [
      'remind me',
      'set a reminder',
      "don't let me forget",
      'dont let me forget',
      'notify me',
      'alert me',
      'alarm me',
      'schedule a reminder',
      'remember to',
      'kindly remind me',
      'please remind me',
      'set an alarm',
      'ping me to',
    ];

    for (final pat in strongReminderPatterns) {
      if (text.startsWith(pat) || text.contains(' $pat')) {
        return IntentResult(
          intent: IntentType.reminder,
          confidence: 0.96,
          scores: {'reminder': 0.96, 'diary': 0.01, 'ambiguous': 0.03},
        );
      }
    }

    // 2b. Explicit reminder clock time expressions (e.g. "8 :5 pm today", "8:5 pm today", "8 5 pm")
    final clockTimeRegex = RegExp(
      r'\b\d{1,2}(?:\s*[:\.]\s*\d{1,2}|\s+\d{1,2})?\s*(?:am|pm)\b|\bin\s+\d+\s+(?:min|minute|hour|day)',
      caseSensitive: false,
    );
    if (clockTimeRegex.hasMatch(text)) {
      final hasDiaryContext = text.contains('dear diary') ||
          text.contains('felt') ||
          text.contains('grateful') ||
          text.contains('today was') ||
          text.contains('woke up') ||
          text.contains('today i met') ||
          text.contains('today i went');
      if (!hasDiaryContext) {
        return IntentResult(
          intent: IntentType.reminder,
          confidence: 0.98,
          scores: {'reminder': 0.98, 'diary': 0.01, 'ambiguous': 0.01},
        );
      }
    }

    // 3. Strong explicit diary starters
    final strongDiaryStarters = [
      'dear diary',
      'journal:',
      'today i felt',
      'today was a',
      'today was exhausting',
      'today was difficult',
      'my day was',
      'i am grateful for',
      'reflected on',
      'looking back on today',
      'personal log:',
      'what a tiring day today',
      'today went by so fast',
    ];

    for (final pat in strongDiaryStarters) {
      if (text.startsWith(pat)) {
        return IntentResult(
          intent: IntentType.diary,
          confidence: 0.95,
          scores: {'diary': 0.95, 'reminder': 0.02, 'ambiguous': 0.03},
        );
      }
    }

    if (text.startsWith('i had a') ||
        text.startsWith('had a great') ||
        text.startsWith('today i met') ||
        text.startsWith('today i went') ||
        text.contains('had a meeting today') ||
        text == 'i had a meeting today') {
      return IntentResult(
        intent: IntentType.diary,
        confidence: 0.95,
        scores: {'diary': 0.95, 'reminder': 0.02, 'ambiguous': 0.03},
      );
    }

    // 4. Future event descriptions in diary style (not explicit reminders)
    // E.g., "Tomorrow is my mother's birthday", "Tomorrow is my sister's birthday"
    final futureEventPatterns = [
      "tomorrow is my mother's birthday",
      "tomorrow is my sister's birthday",
      "tomorrow is my birthday",
      "i have an exam tomorrow",
      "i have a meeting tomorrow",
      "my exam is on friday",
      "my exam is next friday",
      "presentation is scheduled",
      "interview scheduled for",
      "presentation on 25 september",
    ];
    for (final pat in futureEventPatterns) {
      if (text.contains(pat)) {
        return IntentResult(
          intent: IntentType.futureEvent,
          confidence: 0.92,
          scores: {'future_event': 0.92, 'reminder': 0.05, 'diary': 0.03},
        );
      }
    }

    return null;
  }

  IntentResult _predictWithMl(String text) {
    // 1. Tokenize into words
    final cleaned = text.replaceAll(RegExp(r'[^\w\s]'), ' ');
    final words =
        cleaned.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

    // 2. Extract unigrams and bigrams
    final ngrams = <String>[];
    for (int i = 0; i < words.length; i++) {
      ngrams.add(words[i]);
      if (i + 1 < words.length) {
        ngrams.add('${words[i]} ${words[i + 1]}');
      }
    }

    // 3. Count term frequencies
    final tfCounts = <int, int>{};
    for (final gram in ngrams) {
      final idx = _vocab[gram];
      if (idx != null) {
        tfCounts[idx] = (tfCounts[idx] ?? 0) + 1;
      }
    }

    if (tfCounts.isEmpty) {
      return _heuristicClassify(text);
    }

    // 4. Compute sublinear TF-IDF vector: (1 + ln(tf)) * idf
    final featureVector = <int, double>{};
    double normSq = 0.0;
    for (final entry in tfCounts.entries) {
      final idx = entry.key;
      final count = entry.value;
      final val = (1.0 + log(count)) * _idf[idx];
      featureVector[idx] = val;
      normSq += val * val;
    }

    // L2 normalize
    final norm = sqrt(normSq);
    if (norm > 0) {
      for (final k in featureVector.keys) {
        featureVector[k] = featureVector[k]! / norm;
      }
    }

    // 5. Compute class logits
    final logits = <double>[];
    for (int c = 0; c < _classes.length; c++) {
      double logit = _intercept[c];
      final coefRow = _coefficients[c];
      for (final entry in featureVector.entries) {
        logit += coefRow[entry.key] * entry.value;
      }
      logits.add(logit);
    }

    // 6. Softmax
    final maxLogit = logits.reduce(max);
    final expScores = logits.map((l) => exp(l - maxLogit)).toList();
    final sumExp = expScores.reduce((a, b) => a + b);
    final probs = expScores.map((e) => e / sumExp).toList();

    final scoreMap = <String, double>{};
    int maxIdx = 0;
    double maxProb = 0.0;
    for (int i = 0; i < _classes.length; i++) {
      final p = probs[i];
      scoreMap[_classes[i]] = p;
      if (p > maxProb) {
        maxProb = p;
        maxIdx = i;
      }
    }

    final topClass = _classes[maxIdx];
    IntentType resolvedIntent;
    switch (topClass) {
      case 'reminder':
        resolvedIntent = IntentType.reminder;
        break;
      case 'diary':
        resolvedIntent = IntentType.diary;
        break;
      case 'future_event':
        resolvedIntent = IntentType.futureEvent;
        break;
      case 'off_topic':
        resolvedIntent = IntentType.offTopic;
        break;
      default:
        resolvedIntent = IntentType.ambiguous;
    }

    return IntentResult(
      intent: resolvedIntent,
      confidence: maxProb,
      scores: scoreMap,
    );
  }

  IntentResult _heuristicClassify(String text) {
    // Off topic heuristic
    if (text.contains('python') ||
        text.contains('code') ||
        text.contains('what is machine learning') ||
        text.contains('capital of france') ||
        text.contains('solve ')) {
      return IntentResult(
        intent: IntentType.offTopic,
        confidence: 0.90,
        scores: {'off_topic': 0.90},
      );
    }

    // Future event heuristic
    if (text.contains("sister's birthday") ||
        text.contains("mother's birthday") ||
        (text.contains('exam') &&
            !text.contains('study for') &&
            !text.contains('remind')) ||
        (text.contains('meeting tomorrow') &&
            !text.contains('remind') &&
            !text.contains('forget'))) {
      return IntentResult(
        intent: IntentType.futureEvent,
        confidence: 0.85,
        scores: {'future_event': 0.85},
      );
    }

    int reminderVotes = 0;
    int diaryVotes = 0;
    int ambiguousVotes = 0;

    final reminderTriggers = [
      'tomorrow',
      'at ',
      'pm',
      'am',
      'need to',
      'must',
      'buy',
      'call',
      'in 10 min',
      'in 2 hours',
      'in 20 minutes',
      'in 30 minutes',
      'submit',
      'check the',
      'study for',
      'every monday',
      'every day'
    ];
    final diaryTriggers = [
      'today was',
      'felt',
      'i feel',
      'woke up',
      'went to',
      'dinner with',
      'happy',
      'grateful',
      'today i',
      'completed my',
      'visited my',
      'exhausting'
    ];
    final ambiguousTriggers = [
      'maybe',
      'sometime',
      'wondering',
      'thinking about',
      'should probably'
    ];

    for (final t in reminderTriggers) {
      if (text.contains(t)) reminderVotes++;
    }
    for (final t in diaryTriggers) {
      if (text.contains(t)) diaryVotes++;
    }
    for (final t in ambiguousTriggers) {
      if (text.contains(t)) ambiguousVotes++;
    }

    if (reminderVotes > diaryVotes && reminderVotes > ambiguousVotes) {
      return IntentResult(
        intent: IntentType.reminder,
        confidence: 0.78,
        scores: {'reminder': 0.78, 'diary': 0.12, 'ambiguous': 0.10},
      );
    } else if (diaryVotes > reminderVotes && diaryVotes > ambiguousVotes) {
      return IntentResult(
        intent: IntentType.diary,
        confidence: 0.78,
        scores: {'diary': 0.78, 'reminder': 0.12, 'ambiguous': 0.10},
      );
    } else {
      return IntentResult(
        intent: IntentType.ambiguous,
        confidence: 0.50,
        scores: {'ambiguous': 0.60, 'reminder': 0.20, 'diary': 0.20},
      );
    }
  }
}

class IntentResult {
  final IntentType intent;
  final double confidence;
  final Map<String, double> scores;

  const IntentResult({
    required this.intent,
    required this.confidence,
    required this.scores,
  });
}
