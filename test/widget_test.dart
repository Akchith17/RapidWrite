import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylus_handwriting_evaluator/main.dart';
import 'package:stylus_handwriting_evaluator/models/handwriting_stroke.dart';
import 'package:stylus_handwriting_evaluator/models/stroke_point.dart';
import 'package:stylus_handwriting_evaluator/services/speed_calculator_service.dart';
import 'package:stylus_handwriting_evaluator/services/aesthetic_evaluator_service.dart';
import 'package:stylus_handwriting_evaluator/services/digital_ink_service.dart';

void main() {
  testWidgets('Tablet Stylus Evaluator smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const StylusEvaluatorApp());
    await tester.pumpAndSettle();

    // Verify main tablet header
    expect(find.text('Stylus Handwriting Evaluator'), findsOneWidget);

    // Verify default target copy sentence
    expect(
      find.text('The quick brown fox jumps over the lazy dog'),
      findsOneWidget,
    );

    // Verify control buttons
    expect(find.text('Clear Canvas'), findsOneWidget);
    expect(find.text('Submit / Analyze'), findsOneWidget);
  });

  test('SpeedCalculatorService independent speed metric test', () {
    final stroke = HandwritingStroke(
      points: [
        StrokePoint(x: 10, y: 10, timestampMs: 1000),
        StrokePoint(x: 110, y: 10, timestampMs: 2000), // 100 px in 1 sec
      ],
    );

    final metrics = SpeedCalculatorService.calculate(
      startTimeMs: 1000,
      endTimeMs: 2500,
      strokes: [stroke],
    );

    expect(metrics.totalStrokeLengthPx, closeTo(100.0, 0.01));
    expect(metrics.activeDrawingTimeMs, equals(1000));
    expect(metrics.activeVelocityPxPerSec, closeTo(100.0, 0.1));
    expect(metrics.strokeCount, equals(1));
  });

  test('AestheticEvaluatorService evaluation heuristics test', () {
    final stroke1 = HandwritingStroke(
      points: [
        StrokePoint(x: 10, y: 50, timestampMs: 1000),
        StrokePoint(x: 20, y: 51, timestampMs: 1100),
        StrokePoint(x: 30, y: 50, timestampMs: 1200),
      ],
    );

    final evaluation = AestheticEvaluatorService.evaluate([stroke1]);

    expect(evaluation.overallAestheticScore, greaterThan(0));
    expect(evaluation.neatnessScore, greaterThan(0));
    expect(evaluation.visualObservations.isNotEmpty, isTrue);
  });

  test('DigitalInkService text matching accuracy test', () {
    const target = 'The quick brown fox jumps over the lazy dog';
    const exact = 'The quick brown fox jumps over the lazy dog';
    const minorTypo = 'The quick brown fox jumps over the lazy fog';

    final exactAcc = DigitalInkService.calculateCharacterAccuracy(target, exact);
    final typoAcc = DigitalInkService.calculateCharacterAccuracy(target, minorTypo);

    expect(exactAcc, equals(100.0));
    expect(typoAcc, greaterThan(90.0));
  });
}
