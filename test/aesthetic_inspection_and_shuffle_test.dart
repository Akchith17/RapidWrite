import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylus_handwriting_evaluator/models/handwriting_stroke.dart';
import 'package:stylus_handwriting_evaluator/models/practice_settings.dart';
import 'package:stylus_handwriting_evaluator/models/stroke_point.dart';
import 'package:stylus_handwriting_evaluator/services/aesthetic/aesthetic_engine.dart';
import 'package:stylus_handwriting_evaluator/services/sentence_engine_service.dart';

void main() {
  group('1. Sentence Engine Shuffle Verification', () {
    test('Shuffle guarantees a different sentence than currentText', () {
      final settings = PracticeSettings.defaultSettings();
      final original = SentenceEngineService.generateSentence(settings);

      // Roll 15 consecutive shuffles; none should equal the immediate previous sentence
      var previous = original.text;
      for (int i = 0; i < 15; i++) {
        final shuffled = SentenceEngineService.generateSentence(
          settings,
          currentText: previous,
        );
        expect(
          shuffled.text,
          isNot(equals(previous)),
          reason: 'Shuffle cycle $i returned duplicate sentence "$previous"',
        );
        previous = shuffled.text;
      }
    });
  });

  group('2. 5-Stage Algorithm Inspection Data Verification', () {
    test('AestheticEngine populates comprehensive inspectionData for live stylus evaluation', () {
      // Simulate handwriting strokes representing consistent script
      final strokes = <HandwritingStroke>[];
      for (int charIdx = 0; charIdx < 8; charIdx++) {
        final startX = 50.0 + charIdx * 35.0;
        final startY = 100.0;
        strokes.add(HandwritingStroke(
          points: [
            StrokePoint(x: startX, y: startY, timestampMs: 0),
            StrokePoint(x: startX + 2.0, y: startY + 15.0, timestampMs: 20),
            StrokePoint(x: startX + 4.0, y: startY + 35.0, timestampMs: 40),
            StrokePoint(x: startX + 6.0, y: startY + 48.0, timestampMs: 60),
          ],
          strokeWidth: 3.0,
          color: const Color(0xFFFFFFFF),
        ));
      }

      final eval = AestheticEngine.evaluateSession(
        strokes: strokes,
        targetSentence: 'The quick brown fox',
      );

      expect(eval.inspectionData, isNotNull);
      final data = eval.inspectionData!;

      // Verify all 5 stages have live values populated
      expect(data.totalStrokes, equals(8));
      expect(data.medianHeightPx, greaterThan(0.0));
      expect(data.strokeSmoothnessPct, greaterThan(0.0));
      expect(data.dimensionScores.containsKey('Readability'), isTrue);
      expect(data.dimensionScores.containsKey('Letter Formation'), isTrue);
      expect(data.dimensionScores.containsKey('Alignment'), isTrue);
      expect(data.dimensionScores.containsKey('Consistency'), isTrue);
      expect(data.dimensionScores.containsKey('Spacing'), isTrue);
      expect(data.dimensionScores.containsKey('Visual Organisation'), isTrue);
      expect(data.scoringWeights['Readability'], equals(0.22));
      expect(data.scoringWeights['Letter Formation'], equals(0.18));
      expect(data.finalCompositeScore, greaterThan(0.0));
      expect(data.finalGrade, isNotEmpty);
      expect(data.formulaText, contains('0.22×Readability'));
      // Verify neat script does not collapse into C
      expect(eval.overallAestheticScore, greaterThanOrEqualTo(75.0),
          reason: 'Consistent, neat vertical strokes should score B+ or higher, not C');
    });
  });
}
