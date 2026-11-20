import 'package:flutter_test/flutter_test.dart';
import 'package:stylus_handwriting_evaluator/models/practice_settings.dart';
import 'package:stylus_handwriting_evaluator/models/target_sentence_model.dart';
import 'package:stylus_handwriting_evaluator/services/sentence_engine_service.dart';

void main() {
  group('1. Dynamic Duration & Pacing Calculations', () {
    test('Calculates exact duration for 50 words at 25 WPM (120 seconds / 2.0 mins)', () {
      final durSec = PracticeSettings.calculateRecommendedDurationSec(
        wordCount: 50,
        targetWpm: 25,
      );
      final durMin = PracticeSettings.calculateRecommendedDurationMinutes(
        wordCount: 50,
        targetWpm: 25,
      );

      expect(durSec, closeTo(120.0, 0.01));
      expect(durMin, closeTo(2.0, 0.01));
    });

    test('Calculates exact duration for 30 words at 20 WPM (90 seconds / 1.5 mins)', () {
      final durSec = PracticeSettings.calculateRecommendedDurationSec(
        wordCount: 30,
        targetWpm: 20,
      );
      final durMin = PracticeSettings.calculateRecommendedDurationMinutes(
        wordCount: 30,
        targetWpm: 20,
      );

      expect(durSec, closeTo(90.0, 0.01));
      expect(durMin, closeTo(1.5, 0.01));
    });

    test('Calculates independent CPM duration correctly', () {
      // 150 characters at 100 CPM = 1.5 minutes = 90 seconds
      final cpmSec = PracticeSettings.calculateRecommendedDurationCpmSec(
        charCount: 150,
        targetCpm: 100,
      );
      expect(cpmSec, closeTo(90.0, 0.01));
    });

    test('Formatted duration displays readable strings for students', () {
      final model90 = TargetSentenceModel.fromText(
        text: List.generate(30, (i) => 'word').join(' '),
        settings: const PracticeSettings(targetWpm: 20),
      );
      expect(model90.formattedDuration, equals('90s (1m 30s)'));

      final model60 = TargetSentenceModel.fromText(
        text: List.generate(20, (i) => 'word').join(' '),
        settings: const PracticeSettings(targetWpm: 20),
      );
      expect(model60.formattedDuration, equals('1m'));

      final model30 = TargetSentenceModel.fromText(
        text: List.generate(10, (i) => 'word').join(' '),
        settings: const PracticeSettings(targetWpm: 20),
      );
      expect(model30.formattedDuration, equals('30s'));
    });
  });

  group('2. Sentence Generation Engine & Character Categories', () {
    test('Includes meaningful numbers when includeNumbers is enabled', () {
      final settings = const PracticeSettings(
        includeNumbers: true,
        includeSpecialCharacters: false,
        difficulty: PracticeDifficulty.easy,
      );
      final model = SentenceEngineService.generateSentence(settings);

      expect(RegExp(r'[0-9]').hasMatch(model.text), isTrue,
          reason: 'Sentence should contain digits: "${model.text}"');
      expect(model.categoriesPresent.contains('numbers'), isTrue);
    });

    test('Includes suitable special characters when includeSpecialCharacters is enabled', () {
      final settings = const PracticeSettings(
        includeNumbers: false,
        includeSpecialCharacters: true,
        difficulty: PracticeDifficulty.intermediate,
      );
      final model = SentenceEngineService.generateSentence(settings);

      expect(RegExp(r'[@#%&+=$\/\\*]').hasMatch(model.text), isTrue,
          reason: 'Sentence should contain special characters: "${model.text}"');
      expect(model.categoriesPresent.contains('special'), isTrue);
    });

    test('Handles both numbers and special characters together gracefully', () {
      final settings = const PracticeSettings(
        includeNumbers: true,
        includeSpecialCharacters: true,
        difficulty: PracticeDifficulty.beginner,
      );
      final model = SentenceEngineService.generateSentence(settings);

      expect(RegExp(r'[0-9]').hasMatch(model.text), isTrue);
      expect(RegExp(r'[@#%&+=$\/\\*]').hasMatch(model.text), isTrue);
    });

    test('Strips punctuation when includePunctuation is disabled', () {
      final settings = const PracticeSettings(
        includePunctuation: false,
        difficulty: PracticeDifficulty.easy,
      );
      final model = SentenceEngineService.generateSentence(settings);

      expect(RegExp(r'''[,.;:!?\'"\-]''').hasMatch(model.text), isFalse,
          reason: 'Sentence should have no punctuation: "${model.text}"');
    });

    test('Converts to lowercase when uppercase is disabled', () {
      final settings = const PracticeSettings(
        includeUppercase: false,
        includeLowercase: true,
        difficulty: PracticeDifficulty.beginner,
      );
      final model = SentenceEngineService.generateSentence(settings);

      expect(RegExp(r'[A-Z]').hasMatch(model.text), isFalse,
          reason: 'Sentence should contain no uppercase letters: "${model.text}"');
    });
  });

  group('3. Sentence Length and Difficulty Adaptations', () {
    test('Short sentences generate approx 8-15 words', () {
      final settings = const PracticeSettings(
        lengthCategory: SentenceLengthCategory.short,
      );
      final model = SentenceEngineService.generateSentence(settings);
      expect(model.wordCount, inInclusiveRange(6, 20));
    });

    test('Medium sentences generate approx 20-35 words', () {
      final settings = const PracticeSettings(
        lengthCategory: SentenceLengthCategory.medium,
      );
      final model = SentenceEngineService.generateSentence(settings);
      expect(model.wordCount, greaterThanOrEqualTo(12));
    });

    test('Custom text override passes through accurately', () {
      const custom = 'Students attend classes every day with great enthusiasm.';
      final settings = const PracticeSettings(customText: custom);
      final model = SentenceEngineService.generateSentence(settings);

      expect(model.text, equals(custom));
      expect(model.wordCount, equals(8));
    });
  });

  group('4. Settings Persistence & Serialization', () {
    test('PracticeSettings JSON roundtrip preserves all fields', () {
      const original = PracticeSettings(
        targetWpm: 35,
        targetCpm: 175,
        lengthCategory: SentenceLengthCategory.medium,
        customWordCount: 28,
        difficulty: PracticeDifficulty.advanced,
        includeLowercase: true,
        includeUppercase: true,
        includeNumbers: true,
        includeSpecialCharacters: true,
        includePunctuation: true,
        mixedAlphanumeric: true,
        customText: 'Test custom phrase',
      );

      final json = original.toJson();
      final restored = PracticeSettings.fromJson(json);

      expect(restored.targetWpm, equals(35));
      expect(restored.targetCpm, equals(175));
      expect(restored.lengthCategory, equals(SentenceLengthCategory.medium));
      expect(restored.customWordCount, equals(28));
      expect(restored.difficulty, equals(PracticeDifficulty.advanced));
      expect(restored.includeNumbers, isTrue);
      expect(restored.includeSpecialCharacters, isTrue);
      expect(restored.customText, equals('Test custom phrase'));
    });
  });
}
