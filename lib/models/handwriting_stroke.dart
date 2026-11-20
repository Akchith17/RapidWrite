import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'stroke_point.dart';

/// Represents a single continuous stroke drawn on the canvas.
class HandwritingStroke {
  final List<StrokePoint> points;
  final Color color;
  final double strokeWidth;

  HandwritingStroke({
    List<StrokePoint>? points,
    this.color = const Color(0xFF1E293B), // Premium ink dark slate
    this.strokeWidth = 3.0,
  }) : points = points ?? [];

  bool get isEmpty => points.isEmpty;
  bool get isNotEmpty => points.isNotEmpty;

  void addPoint(StrokePoint point) {
    points.add(point);
  }

  /// Calculates the total path length of the stroke in pixels.
  double get totalLength {
    if (points.length < 2) return 0.0;
    double sum = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      sum += math.sqrt(math.pow(p2.x - p1.x, 2) + math.pow(p2.y - p1.y, 2));
    }
    return sum;
  }

  /// Total duration of the stroke from first to last point in milliseconds.
  int get durationMs {
    if (points.length < 2) return 0;
    return points.last.timestampMs - points.first.timestampMs;
  }

  /// Average velocity of this stroke in pixels per second.
  double get velocityPxPerSec {
    final d = durationMs;
    if (d <= 0) return 0.0;
    return (totalLength / (d / 1000.0));
  }

  /// Bounding box enclosing the stroke.
  Rect? get bounds {
    if (points.isEmpty) return null;
    double minX = points.first.x;
    double maxX = points.first.x;
    double minY = points.first.y;
    double maxY = points.first.y;

    for (final p in points) {
      if (p.x < minX) minX = p.x;
      if (p.x > maxX) maxX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.y > maxY) maxY = p.y;
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// Non-null bounding box getter for computer vision and aesthetic analysis.
  Rect get boundingBox => bounds ?? Rect.zero;
}
