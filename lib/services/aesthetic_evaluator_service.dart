import 'dart:math' as math;
import '../models/aesthetic_evaluation.dart';
import '../models/handwriting_stroke.dart';

/// Computer vision & geometric heuristic evaluation service for handwriting aesthetics,
/// assessing neatness, baseline alignment, slant consistency, and stroke smoothness holistically.
class AestheticEvaluatorService {
  /// Evaluates the complete set of strokes and returns an AestheticEvaluation.
  static AestheticEvaluation evaluate(List<HandwritingStroke> strokes) {
    if (strokes.isEmpty) {
      return AestheticEvaluation(
        overallAestheticScore: 0,
        neatnessScore: 0,
        baselineAlignmentScore: 0,
        slantConsistencyScore: 0,
        strokeSmoothnessScore: 0,
        pressureRhythmScore: 0,
        grade: 'N/A',
        critiqueTitle: 'No Strokes Recorded',
        visualObservations: ['Canvas is currently empty.'],
        coachingTips: ['Write the target sentence on the canvas to evaluate.'],
        evaluatedBy: 'Local Computer Vision Engine',
      );
    }

    final baselineScore = _evaluateBaselineAlignment(strokes);
    final slantScore = _evaluateSlantConsistency(strokes);
    final smoothnessScore = _evaluateStrokeSmoothness(strokes);
    final pressureScore = _evaluatePressureDynamics(strokes);
    final spacingScore = _evaluateSpatialUniformity(strokes);

    // Weighted composite aesthetic score
    final overallScore = (
      baselineScore * 0.25 +
      slantScore * 0.25 +
      smoothnessScore * 0.25 +
      pressureScore * 0.15 +
      spacingScore * 0.10
    ).clamp(10.0, 99.0);

    // Neatness score is a combination of baseline, smoothness and slant
    final neatnessScore = (
      baselineScore * 0.40 +
      smoothnessScore * 0.35 +
      slantScore * 0.25
    ).clamp(10.0, 99.0);

    final grade = _calculateGrade(overallScore);
    final critiqueTitle = _generateCritiqueTitle(overallScore, baselineScore, smoothnessScore);
    final observations = _generateObservations(baselineScore, slantScore, smoothnessScore, pressureScore);
    final tips = _generateCoachingTips(baselineScore, slantScore, smoothnessScore, pressureScore);

    return AestheticEvaluation(
      overallAestheticScore: double.parse(overallScore.toStringAsFixed(1)),
      neatnessScore: double.parse(neatnessScore.toStringAsFixed(1)),
      baselineAlignmentScore: double.parse(baselineScore.toStringAsFixed(1)),
      slantConsistencyScore: double.parse(slantScore.toStringAsFixed(1)),
      strokeSmoothnessScore: double.parse(smoothnessScore.toStringAsFixed(1)),
      pressureRhythmScore: double.parse(pressureScore.toStringAsFixed(1)),
      grade: grade,
      critiqueTitle: critiqueTitle,
      visualObservations: observations,
      coachingTips: tips,
      evaluatedBy: 'Local Computer Vision Engine',
    );
  }

  /// Evaluates how straight the baseline of the written text is.
  static double _evaluateBaselineAlignment(List<HandwritingStroke> strokes) {
    final bottomPoints = <double>[];

    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;
      // Get the bottom-most 20% points of each stroke to estimate baseline contact
      final yVals = stroke.points.map((p) => p.y).toList()..sort();
      final sampleCount = math.max(1, (yVals.length * 0.2).round());
      for (int i = yVals.length - sampleCount; i < yVals.length; i++) {
        bottomPoints.add(yVals[i]);
      }
    }

    if (bottomPoints.length < 3) return 75.0;

    // Calculate variance of the bottom baseline points
    final mean = bottomPoints.reduce((a, b) => a + b) / bottomPoints.length;
    final variance = bottomPoints
            .map((y) => math.pow(y - mean, 2))
            .reduce((a, b) => a + b) /
        bottomPoints.length;
    final stdDev = math.sqrt(variance);

    // StdDev < 12px indicates very steady baseline alignment
    final score = 100.0 - (stdDev * 1.8);
    return score.clamp(30.0, 98.0);
  }

  /// Evaluates consistency of stroke slant angle (uniform cursive or print angle).
  static double _evaluateSlantConsistency(List<HandwritingStroke> strokes) {
    final angles = <double>[];

    for (final stroke in strokes) {
      if (stroke.points.length < 3) continue;
      for (int i = 0; i < stroke.points.length - 2; i += 2) {
        final p1 = stroke.points[i];
        final p2 = stroke.points[i + 2];
        final dy = p2.y - p1.y;
        final dx = p2.x - p1.x;
        final dist = math.sqrt(dx * dx + dy * dy);

        // Consider downward strokes of substantial length
        if (dy > 4.0 && dist > 8.0) {
          final angleDeg = (math.atan2(dy, dx) * 180 / math.pi);
          angles.add(angleDeg);
        }
      }
    }

    if (angles.length < 4) return 80.0;

    final meanAngle = angles.reduce((a, b) => a + b) / angles.length;
    final variance = angles
            .map((a) => math.pow(a - meanAngle, 2))
            .reduce((a, b) => a + b) /
        angles.length;
    final stdDev = math.sqrt(variance);

    // StdDev of slant angle < 10 degrees is exceptionally consistent
    final score = 100.0 - (stdDev * 1.5);
    return score.clamp(35.0, 97.0);
  }

  /// Evaluates stroke smoothness and detects microscopic hand tremors or hesitation.
  static double _evaluateStrokeSmoothness(List<HandwritingStroke> strokes) {
    double totalJitter = 0.0;
    int evaluatedSegments = 0;

    for (final stroke in strokes) {
      if (stroke.points.length < 4) continue;
      for (int i = 1; i < stroke.points.length - 1; i++) {
        final pPrev = stroke.points[i - 1];
        final pCurr = stroke.points[i];
        final pNext = stroke.points[i + 1];

        final angle1 = math.atan2(pCurr.y - pPrev.y, pCurr.x - pPrev.x);
        final angle2 = math.atan2(pNext.y - pCurr.y, pNext.x - pCurr.x);

        double diff = (angle2 - angle1).abs();
        if (diff > math.pi) diff = 2 * math.pi - diff;

        // Sharp zigzag angles indicate tremor, whereas smooth curves have low diff
        totalJitter += diff;
        evaluatedSegments++;
      }
    }

    if (evaluatedSegments == 0) return 82.0;

    final avgJitter = totalJitter / evaluatedSegments;
    // Avg angular change per segment (radians): ~0.2-0.5 is smooth curve
    final score = 100.0 - (avgJitter * 28.0);
    return score.clamp(35.0, 96.0);
  }

  /// Evaluates pressure modulation dynamics (stylus sensitivity).
  static double _evaluatePressureDynamics(List<HandwritingStroke> strokes) {
    final pressures = <double>[];
    for (final stroke in strokes) {
      for (final p in stroke.points) {
        if (p.pressure > 0.0 && p.pressure != 1.0) {
          pressures.add(p.pressure);
        }
      }
    }

    if (pressures.length < 10) {
      // Stylus or simulator reporting uniform pressure
      return 85.0;
    }

    final mean = pressures.reduce((a, b) => a + b) / pressures.length;
    final variance = pressures
            .map((p) => math.pow(p - mean, 2))
            .reduce((a, b) => a + b) /
        pressures.length;
    final stdDev = math.sqrt(variance);

    // Natural expressive calligraphic pressure variation has stdDev between 0.1 and 0.25
    if (stdDev >= 0.08 && stdDev <= 0.35) {
      return 92.0;
    } else if (stdDev < 0.08) {
      return 80.0;
    } else {
      return 75.0;
    }
  }

  /// Evaluates spacing balance between strokes.
  static double _evaluateSpatialUniformity(List<HandwritingStroke> strokes) {
    if (strokes.length < 3) return 80.0;

    final gaps = <double>[];
    for (int i = 0; i < strokes.length - 1; i++) {
      final b1 = strokes[i].bounds;
      final b2 = strokes[i + 1].bounds;
      if (b1 != null && b2 != null) {
        final gap = b2.left - b1.right;
        if (gap > 0 && gap < 120) {
          gaps.add(gap);
        }
      }
    }

    if (gaps.length < 2) return 85.0;

    final meanGap = gaps.reduce((a, b) => a + b) / gaps.length;
    final variance =
        gaps.map((g) => math.pow(g - meanGap, 2)).reduce((a, b) => a + b) /
            gaps.length;
    final stdDev = math.sqrt(variance);

    final score = 100.0 - (stdDev * 1.2);
    return score.clamp(40.0, 95.0);
  }

  static String _calculateGrade(double score) {
    if (score >= 92) return 'A+';
    if (score >= 85) return 'A';
    if (score >= 78) return 'B+';
    if (score >= 70) return 'B';
    if (score >= 60) return 'C+';
    return 'C';
  }

  static String _generateCritiqueTitle(double overall, double baseline, double smoothness) {
    if (overall >= 90) return 'Fluid & Harmonious Penmanship';
    if (overall >= 80) return 'Clean, Confident Letterforms';
    if (baseline >= 85 && smoothness < 70) return 'Linear Structure with Minor Tremor';
    if (smoothness >= 85 && baseline < 70) return 'Graceful Curves with Baseline Drift';
    if (overall >= 70) return 'Good Legibility with Room for Polish';
    return 'Developing Handwriting Cadence';
  }

  static List<String> _generateObservations(
    double baseline,
    double slant,
    double smoothness,
    double pressure,
  ) {
    final list = <String>[];
    if (baseline >= 85) {
      list.add('Exceptional horizontal baseline adherence along the ruled guidelines.');
    } else {
      list.add('Moderate vertical wander observed along the sentence baseline.');
    }

    if (slant >= 85) {
      list.add('Highly uniform character slant angle exhibiting mature cursive discipline.');
    } else {
      list.add('Mixed vertical and inclined slants across word clusters.');
    }

    if (smoothness >= 85) {
      list.add('Smooth stroke arcs with negligible tremor or mechanical hesitation.');
    } else {
      list.add('Subtle micro-tremor detected on extended vertical ascenders.');
    }

    if (pressure >= 88) {
      list.add('Dynamic calligraphic pressure modulation showing natural pen control.');
    }

    return list;
  }

  static List<String> _generateCoachingTips(
    double baseline,
    double slant,
    double smoothness,
    double pressure,
  ) {
    final tips = <String>[];
    if (baseline < 80) {
      tips.add('Anchor word endings onto the baseline guideline to prevent upward drifting.');
    }
    if (slant < 80) {
      tips.add('Maintain a consistent 75° forward tilt for harmonious word rhythm.');
    }
    if (smoothness < 80) {
      tips.add('Relax wrist tension and write from the forearm to achieve silkier curves.');
    }
    if (tips.isEmpty) {
      tips.add('Maintain this fluid cadence for high-speed tablet notation.');
      tips.add('Experiment with nib tilt angles to achieve calligraphic flair.');
    }
    return tips;
  }
}
