import 'package:flutter_test/flutter_test.dart';
import 'package:remindly/models/parsed_input.dart';
import 'package:remindly/services/intent_classifier.dart';

void main() {
  group('IntentClassifier Tests', () {
    late IntentClassifier classifier;

    setUp(() {
      classifier = IntentClassifier();
    });

    test('classifies explicit reminder keywords with high confidence', () {
      final res1 = classifier.classify('remind me to buy groceries tomorrow at 5');
      expect(res1.intent, equals(IntentType.reminder));
      expect(res1.confidence, greaterThanOrEqualTo(0.85));

      final res2 = classifier.classify("don't let me forget to take medicine");
      expect(res2.intent, equals(IntentType.reminder));
      expect(res2.confidence, greaterThanOrEqualTo(0.85));
    });

    test('classifies explicit diary starters with high confidence', () {
      final res1 = classifier.classify('dear diary today i learned how neural networks work');
      expect(res1.intent, equals(IntentType.diary));
      expect(res1.confidence, greaterThanOrEqualTo(0.85));

      final res2 = classifier.classify('today i felt calm and peaceful after a long walk');
      expect(res2.intent, equals(IntentType.diary));
      expect(res2.confidence, greaterThanOrEqualTo(0.85));
    });

    test('classifies explicit clock time and voice expressions as reminder', () {
      final res1 = classifier.classify('8 :5 pm today');
      expect(res1.intent, equals(IntentType.reminder));
      expect(res1.confidence, greaterThanOrEqualTo(0.85));

      final res2 = classifier.classify('8:5 pm today');
      expect(res2.intent, equals(IntentType.reminder));
      expect(res2.confidence, greaterThanOrEqualTo(0.85));

      final res3 = classifier.classify('8 5 pm today');
      expect(res3.intent, equals(IntentType.reminder));
      expect(res3.confidence, greaterThanOrEqualTo(0.85));

      final res4 = classifier.classify('call mom at 8 :5 pm today');
      expect(res4.intent, equals(IntentType.reminder));
      expect(res4.confidence, greaterThanOrEqualTo(0.85));
    });

    test('handles empty input gracefully as ambiguous with 0 confidence', () {
      final res = classifier.classify('   ');
      expect(res.intent, equals(IntentType.ambiguous));
      expect(res.confidence, equals(0.0));
    });
  });
}
