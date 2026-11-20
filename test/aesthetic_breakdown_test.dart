import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylus_handwriting_evaluator/models/aesthetic_breakdown_model.dart';
import 'package:stylus_handwriting_evaluator/models/handwriting_stroke.dart';
import 'package:stylus_handwriting_evaluator/models/stroke_point.dart';
import 'package:stylus_handwriting_evaluator/services/aesthetic/aesthetic_engine.dart';
import 'package:stylus_handwriting_evaluator/services/aesthetic_evaluator_service.dart';

void main() {
  group('Visual Aesthetic Breakdown Engine Tests', () {
    // Helper to generate simulated handwriting strokes for a specific word
    List<HandwritingStroke> generateWordStrokes(String word, double startX, double baselineY, {double letterSpacing = 20.0, double slantDx = 3.0, double height = 35.0}) {
      final strokes = <HandwritingStroke>[];
      double currentX = startX;

      for (int i = 0; i < word.length; i++) {
        final char = word[i];
        final charHeight = (char == char.toUpperCase() || 'bdfhklt'.contains(char))
            ? height * 1.35
            : ('gjpqy'.contains(char) ? height * 1.2 : height);

        final topY = baselineY - charHeight;
        final bottomY = 'gjpqy'.contains(char) ? baselineY + (height * 0.35) : baselineY;

        strokes.add(HandwritingStroke(
          points: [
            StrokePoint(x: currentX, y: topY, timestampMs: 0),
            StrokePoint(x: currentX + (slantDx * 0.5), y: (topY + bottomY) / 2, timestampMs: 30),
            StrokePoint(x: currentX + slantDx, y: bottomY, timestampMs: 60),
          ],
          strokeWidth: 3.0,
          color: const Color(0xFF1E293B),
        ));

        currentX += letterSpacing;
      }
      return strokes;
    }

    test('1. Segments user sentence "I am the best boy." into distinct words and letters', () {
      const sentence = 'I am the best boy.';
      final allStrokes = <HandwritingStroke>[];

      // Simulate handwriting with distinct inter-word gaps
      // Word 1: "I" at X=50
      allStrokes.addAll(generateWordStrokes('I', 50.0, 150.0));
      // Word 2: "am" at X=100 (gap of 50px)
      allStrokes.addAll(generateWordStrokes('am', 100.0, 150.0));
      // Word 3: "the" at X=170 (gap of 70px)
      allStrokes.addAll(generateWordStrokes('the', 170.0, 150.0));
      // Word 4: "best" at X=260 (gap of 90px)
      allStrokes.addAll(generateWordStrokes('best', 260.0, 150.0));
      // Word 5: "boy" at X=370 (gap of 110px)
      allStrokes.addAll(generateWordStrokes('boy', 370.0, 150.0));

      final eval = AestheticEvaluatorService.evaluate(
        allStrokes,
        targetSentence: sentence,
      );

      expect(eval.breakdown, isNotNull);
      final b = eval.breakdown!;

      // Verify Sentence Text
      expect(b.targetSentence, equals(sentence));

      // Verify Word Segmentation
      expect(b.words.length, equals(5), reason: 'Must detect exactly 5 words in "I am the best boy."');
      expect(b.words[0].text, equals('I'));
      expect(b.words[1].text, equals('am'));
      expect(b.words[2].text, equals('the'));
      expect(b.words[3].text, equals('best'));
      expect(b.words[4].text, equals('boy.'));

      // Verify Letter Segmentation
      expect(b.letters.isNotEmpty, isTrue);
      expect(b.letters.length, greaterThanOrEqualTo(5));

      // Verify Bounding Boxes and Dimensions
      for (final letter in b.letters) {
        expect(letter.width, greaterThan(0));
        expect(letter.height, greaterThan(0));
        expect(letter.boundingBox.isFinite, isTrue);
        expect(letter.confidence, greaterThan(0.5));
      }
    });

    test('2. Accurately measures letter sizes, ascenders, descenders, and size category', () {
      const sentence = 'best boy';
      final strokes = <HandwritingStroke>[];
      strokes.addAll(generateWordStrokes('best', 50.0, 150.0));
      strokes.addAll(generateWordStrokes('boy', 160.0, 150.0));

      final eval = AestheticEngine.evaluateSession(
        strokes: strokes,
        targetSentence: sentence,
      );

      final b = eval.breakdown!;
      final sizeCat = b.letterSize;

      expect(sizeCat.categoryName, contains('Letter Size'));
      expect(sizeCat.score, greaterThan(0));
      expect(sizeCat.score, lessThanOrEqualTo(100));
      expect(sizeCat.whatWasMeasured, contains('Measured individual height and width'));
      expect(sizeCat.whatWasDetected, contains('Median body letter height'));
      expect(sizeCat.suggestion, isNotEmpty);
      expect(sizeCat.confidence, greaterThan(0.8));

      // Check morphological classification
      final letterB = b.letters.firstWhere((l) => l.char == 'b');
      expect(letterB.isAscender, isTrue, reason: '"b" is an ascender letter');

      final letterY = b.letters.firstWhere((l) => l.char == 'y');
      expect(letterY.isDescender, isTrue, reason: '"y" is a descender letter');
    });

    test('3. Measures slant without penalizing natural right, left, or upright direction', () {
      const sentence = 'The quick fox';
      // Simulate steady forward italic slant (dx = 6.0)
      final strokes = <HandwritingStroke>[];
      strokes.addAll(generateWordStrokes('The', 50.0, 150.0, slantDx: 6.0));
      strokes.addAll(generateWordStrokes('quick', 140.0, 150.0, slantDx: 6.0));
      strokes.addAll(generateWordStrokes('fox', 270.0, 150.0, slantDx: 6.0));

      final eval = AestheticEngine.evaluateSession(
        strokes: strokes,
        targetSentence: sentence,
      );

      final b = eval.breakdown!;
      final slantCat = b.slant;

      expect(slantCat.score, greaterThanOrEqualTo(80), reason: 'Consistent slant must score highly even if slanted');
      expect(slantCat.whatWasDetected, contains('Right / Forward'));
      expect(slantCat.suggestion, contains('natural slant angle'));
    });

    test('4. Measures letter spacing and word spacing separately with measurement lines', () {
      const sentence = 'I am here';
      final strokes = <HandwritingStroke>[];
      strokes.addAll(generateWordStrokes('I', 40.0, 150.0));
      strokes.addAll(generateWordStrokes('am', 100.0, 150.0, letterSpacing: 18.0));
      strokes.addAll(generateWordStrokes('here', 180.0, 150.0, letterSpacing: 18.0));

      final eval = AestheticEngine.evaluateSession(
        strokes: strokes,
        targetSentence: sentence,
      );

      final b = eval.breakdown!;
      expect(b.spacings.isNotEmpty, isTrue);

      final letterSpacings = b.letterSpacings;
      final wordSpacings = b.wordSpacings;

      expect(wordSpacings.length, equals(2), reason: 'Between 3 words there are exactly 2 word gaps');
      expect(letterSpacings.isNotEmpty, isTrue);

      for (final ws in wordSpacings) {
        expect(ws.isWordGap, isTrue);
        expect(ws.gapPx, greaterThan(0));
        expect(ws.startPoint.dx, lessThan(ws.endPoint.dx));
      }

      final spacingCat = b.spacing;
      expect(spacingCat.metrics.containsKey('letterSpacingScore'), isTrue);
      expect(spacingCat.metrics.containsKey('wordSpacingScore'), isTrue);
    });

    test('5. Linear regression baseline detection detects level, ascending, or descending lines', () {
      const sentence = 'Writing uphill gently';
      // Simulate slightly ascending baseline: Y decreases from 160 to 140 across the line
      final strokes = <HandwritingStroke>[];
      strokes.addAll(generateWordStrokes('Writing', 50.0, 160.0));
      strokes.addAll(generateWordStrokes('uphill', 180.0, 150.0));
      strokes.addAll(generateWordStrokes('gently', 310.0, 140.0));

      final eval = AestheticEngine.evaluateSession(
        strokes: strokes,
        targetSentence: sentence,
      );

      final b = eval.breakdown!;
      expect(b.baseline.trajectory, equals(BaselineTrajectory.ascending));
      expect(b.baseline.angleDeg, lessThan(0.0)); // screen coordinate ascending has negative slope
      expect(b.baseline.trajectoryName, contains('Ascending'));

      final baseCat = b.baselineCategory;
      expect(baseCat.whatWasDetected, contains('Ascending'));
      expect(baseCat.score, greaterThan(60));
    });

    test('6. Consistency category score matches Stage 5 overall score and grade', () {
      const sentence = 'Clear handwriting';
      final strokes = generateWordStrokes('Clear', 50.0, 150.0);
      strokes.addAll(generateWordStrokes('writing', 180.0, 150.0));

      final eval = AestheticEngine.evaluateSession(
        strokes: strokes,
        targetSentence: sentence,
      );

      final b = eval.breakdown!;
      expect(b.overallAestheticScore, equals(eval.overallAestheticScore));
      expect(b.grade, equals(eval.grade));
      expect(b.consistency.score, equals(eval.consistencyScore));
    });

    test('7. Empty or invalid input produces unmeasurable breakdown without crash', () {
      final eval = AestheticEngine.evaluateSession(
        strokes: const [],
        targetSentence: '',
      );

      expect(eval.breakdown, isNotNull);
      final b = eval.breakdown!;
      expect(b.canMeasureReliably, isFalse);
      expect(b.words.isEmpty, isTrue);
      expect(b.letterSize.isReliable, isFalse);
      expect(b.letterSize.whatWasDetected, contains('Unable to measure reliably'));
    });
  });
}
