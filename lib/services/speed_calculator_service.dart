import 'dart:ui';
import '../models/handwriting_stroke.dart';
import '../models/handwriting_metrics.dart';

/// Service dedicated to calculating physical handwriting dynamics and speed
/// independently of the text content or target accuracy.
class SpeedCalculatorService {
  /// Computes comprehensive speed and physical motion metrics.
  static HandwritingMetrics calculate({
    required int startTimeMs,
    required int endTimeMs,
    required List<HandwritingStroke> strokes,
  }) {
    if (strokes.isEmpty || startTimeMs <= 0) {
      return HandwritingMetrics(
        startTimeMs: startTimeMs,
        endTimeMs: endTimeMs,
        totalElapsedTimeMs: (endTimeMs - startTimeMs).clamp(0, 9999999),
        activeDrawingTimeMs: 0,
        pauseTimeMs: (endTimeMs - startTimeMs).clamp(0, 9999999),
        totalStrokeLengthPx: 0.0,
        activeVelocityPxPerSec: 0.0,
        overallVelocityPxPerSec: 0.0,
        boundingBox: Rect.zero,
        strokeCount: 0,
        totalPoints: 0,
      );
    }

    final totalElapsedMs = (endTimeMs - startTimeMs).clamp(1, 99999999);
    int activeDrawingMs = 0;
    double totalLengthPx = 0.0;
    int totalPoints = 0;

    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      totalPoints += stroke.points.length;
      totalLengthPx += stroke.totalLength;
      activeDrawingMs += stroke.durationMs;

      for (final p in stroke.points) {
        if (p.x < minX) minX = p.x;
        if (p.x > maxX) maxX = p.x;
        if (p.y < minY) minY = p.y;
        if (p.y > maxY) maxY = p.y;
      }
    }

    final pauseMs = (totalElapsedMs - activeDrawingMs).clamp(0, totalElapsedMs);
    final activeSec = (activeDrawingMs / 1000.0);
    final overallSec = (totalElapsedMs / 1000.0);

    final activeVelocity = activeSec > 0 ? (totalLengthPx / activeSec) : 0.0;
    final overallVelocity = overallSec > 0 ? (totalLengthPx / overallSec) : 0.0;

    final boundingBox = (minX.isFinite && minY.isFinite)
        ? Rect.fromLTRB(minX, minY, maxX, maxY)
        : Rect.zero;

    return HandwritingMetrics(
      startTimeMs: startTimeMs,
      endTimeMs: endTimeMs,
      totalElapsedTimeMs: totalElapsedMs,
      activeDrawingTimeMs: activeDrawingMs,
      pauseTimeMs: pauseMs,
      totalStrokeLengthPx: totalLengthPx,
      activeVelocityPxPerSec: activeVelocity,
      overallVelocityPxPerSec: overallVelocity,
      boundingBox: boundingBox,
      strokeCount: strokes.length,
      totalPoints: totalPoints,
    );
  }
}
