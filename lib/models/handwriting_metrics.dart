import 'dart:ui';

/// Metrics specifically calculating physical handwriting speed and spatial dynamics,
/// completely independent of target sentence accuracy.
class HandwritingMetrics {
  final int startTimeMs;
  final int endTimeMs;
  final int totalElapsedTimeMs;
  final int activeDrawingTimeMs;
  final int pauseTimeMs;
  final double totalStrokeLengthPx;
  final double activeVelocityPxPerSec;
  final double overallVelocityPxPerSec;
  final Rect boundingBox;
  final int strokeCount;
  final int totalPoints;

  HandwritingMetrics({
    required this.startTimeMs,
    required this.endTimeMs,
    required this.totalElapsedTimeMs,
    required this.activeDrawingTimeMs,
    required this.pauseTimeMs,
    required this.totalStrokeLengthPx,
    required this.activeVelocityPxPerSec,
    required this.overallVelocityPxPerSec,
    required this.boundingBox,
    required this.strokeCount,
    required this.totalPoints,
  });

  /// Approximate spatial coverage in square centimeters assuming standard tablet ~160-264 DPI.
  /// Using ~200 DPI (approx 78.7 px/cm => 6193.7 px²/cm²).
  double get estimatedAreaCm2 {
    final areaPx = boundingBox.width * boundingBox.height;
    return areaPx / 6193.7;
  }

  /// Active writing percentage (time spent with pen on screen vs total time).
  double get activeDutyCyclePercent {
    if (totalElapsedTimeMs <= 0) return 0.0;
    return (activeDrawingTimeMs / totalElapsedTimeMs) * 100.0;
  }

  /// Spatial density (total stroke length divided by bounding area).
  double get strokeDensity {
    final area = boundingBox.width * boundingBox.height;
    if (area <= 0) return 0.0;
    return (totalStrokeLengthPx / area) * 1000;
  }

  Map<String, dynamic> toJson() => {
        'startTimeMs': startTimeMs,
        'endTimeMs': endTimeMs,
        'totalElapsedTimeMs': totalElapsedTimeMs,
        'activeDrawingTimeMs': activeDrawingTimeMs,
        'pauseTimeMs': pauseTimeMs,
        'totalStrokeLengthPx': totalStrokeLengthPx,
        'activeVelocityPxPerSec': activeVelocityPxPerSec,
        'overallVelocityPxPerSec': overallVelocityPxPerSec,
        'strokeCount': strokeCount,
        'totalPoints': totalPoints,
        'boundingBox': {
          'left': boundingBox.left,
          'top': boundingBox.top,
          'width': boundingBox.width,
          'height': boundingBox.height,
        },
      };
}
