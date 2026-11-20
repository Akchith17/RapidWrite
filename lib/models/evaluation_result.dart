import 'aesthetic_breakdown_model.dart';
import 'aesthetic_evaluation.dart';
import 'handwriting_metrics.dart';
import 'handwriting_stroke.dart';

/// Complete evaluation result returned after submitting a handwritten sample.
/// Encapsulates:
/// 1. Raw / Gross handwriting speed (independent of text content)
/// 2. Text recognition accuracy (against target sentence)
/// 3. Actual / Net writing speed (speed scaled by accuracy)
/// 4. Holistic aesthetic and neatness evaluation
class EvaluationResult {
  final String targetSentence;
  final String recognizedText;
  final double characterAccuracy;
  final double wordAccuracy;
  final HandwritingMetrics metrics;
  final AestheticEvaluation aesthetic;
  final String? screenshotPath;
  final DateTime timestamp;
  final String ocrEngine;
  final List<HandwritingStroke>? strokes;

  AestheticBreakdown? get aestheticBreakdown => aesthetic.breakdown;

  // Raw / Gross Speed Metrics (pure physical writing speed, regardless of what they wrote)
  final double grossWpm;
  final double grossCpm;

  // Actual / Net Speed Metrics (calculated taking accuracy into account)
  final double netWpm;
  final double netCpm;
  final double effectiveVelocityPxPerSec;
  final double speedPenaltyWpm;
  final int correctCharacterCount;
  final int errorCount;

  // Adaptive Target Benchmarks (for pacing & speed comparison)
  final int? targetWpm;
  final double? recommendedDurationSec;

  EvaluationResult({
    required this.targetSentence,
    required this.recognizedText,
    required this.characterAccuracy,
    required this.wordAccuracy,
    required this.metrics,
    required this.aesthetic,
    this.screenshotPath,
    required this.timestamp,
    this.strokes,
    String? ocrEngine,
    double? grossWpm,
    double? grossCpm,
    double? netWpm,
    double? netCpm,
    double? effectiveVelocityPxPerSec,
    double? speedPenaltyWpm,
    int? correctCharacterCount,
    int? errorCount,
    this.targetWpm,
    this.recommendedDurationSec,
  })  : ocrEngine = ocrEngine ?? 'Google Digital Ink',
        grossCpm = grossCpm ?? _computeGrossCpm(recognizedText, targetSentence, metrics),
        grossWpm = grossWpm ?? (_computeGrossCpm(recognizedText, targetSentence, metrics) / 5.0),
        netCpm = netCpm ?? (_computeGrossCpm(recognizedText, targetSentence, metrics) * (characterAccuracy / 100.0).clamp(0.0, 1.0)),
        netWpm = netWpm ?? ((_computeGrossCpm(recognizedText, targetSentence, metrics) / 5.0) * (characterAccuracy / 100.0).clamp(0.0, 1.0)),
        effectiveVelocityPxPerSec = effectiveVelocityPxPerSec ?? (metrics.activeVelocityPxPerSec * (characterAccuracy / 100.0).clamp(0.0, 1.0)),
        speedPenaltyWpm = speedPenaltyWpm ?? (((_computeGrossCpm(recognizedText, targetSentence, metrics) / 5.0) * (1.0 - (characterAccuracy / 100.0).clamp(0.0, 1.0))).clamp(0.0, 999.0)),
        correctCharacterCount = correctCharacterCount ?? _computeCorrectChars(recognizedText, targetSentence, characterAccuracy),
        errorCount = errorCount ?? _computeErrorChars(recognizedText, targetSentence, characterAccuracy);

  static double _computeGrossCpm(String recognized, String target, HandwritingMetrics metrics) {
    final text = recognized.trim();
    final int chars = text.isNotEmpty
        ? text.length
        : (metrics.strokeCount > 0
            ? (metrics.strokeCount / 2.2).round().clamp(1, target.length)
            : target.length);

    // Active writing duration in minutes (at least 0.5s to avoid division by zero)
    final double activeMin = (metrics.activeDrawingTimeMs / 60000.0).clamp(0.0083, 999.0);
    return (chars / activeMin).clamp(0.0, 500.0);
  }

  static int _computeCorrectChars(String recognized, String target, double accuracy) {
    final int total = recognized.trim().isNotEmpty ? recognized.trim().length : target.length;
    return ((accuracy / 100.0).clamp(0.0, 1.0) * total).round();
  }

  static int _computeErrorChars(String recognized, String target, double accuracy) {
    final int total = recognized.trim().isNotEmpty ? recognized.trim().length : target.length;
    final int correct = _computeCorrectChars(recognized, target, accuracy);
    return (total - correct).clamp(0, total);
  }

  Map<String, dynamic> toJson() => {
        'targetSentence': targetSentence,
        'recognizedText': recognizedText,
        'characterAccuracy': characterAccuracy,
        'wordAccuracy': wordAccuracy,
        'ocrEngine': ocrEngine,
        'grossWpm': grossWpm,
        'grossCpm': grossCpm,
        'netWpm': netWpm,
        'netCpm': netCpm,
        'effectiveVelocityPxPerSec': effectiveVelocityPxPerSec,
        'speedPenaltyWpm': speedPenaltyWpm,
        'correctCharacterCount': correctCharacterCount,
        'errorCount': errorCount,
        'metrics': metrics.toJson(),
        'aesthetic': aesthetic.toJson(),
        'screenshotPath': screenshotPath,
        'timestamp': timestamp.toIso8601String(),
        'targetWpm': targetWpm,
        'recommendedDurationSec': recommendedDurationSec,
      };
}
