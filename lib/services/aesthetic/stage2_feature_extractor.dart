import 'dart:math' as math;
import '../../models/handwriting_stroke.dart';
import 'handwriting_feature_model.dart';

/// STAGE 2 – Extract Geometric Features of Each Occurrence
/// Extracts measurable local features (height, width, slant, aspect ratio)
/// and global features (spacing, baseline drift, stroke curvature smoothness).
class Stage2FeatureExtractor {
  static ExtractedGeometricFeatures extract({
    required List<HandwritingStroke> strokes,
    Map<String, List<LetterOccurrence>>? occurrences,
  }) {
    if (strokes.isEmpty) {
      return const ExtractedGeometricFeatures(
        medianHeight: 0,
        heightMad: 0,
        medianWidth: 0,
        widthMad: 0,
        medianSlantDeg: 0,
        slantMadDeg: 0,
        medianAspectRatio: 1.0,
        medianSpacing: 0,
        spacingMad: 0,
        baselineDriftPx: 0,
        strokeSmoothness: 0,
        totalStrokes: 0,
        estimatedGlyphs: 0,
      );
    }

    final validStrokes = strokes.where((s) => s.points.isNotEmpty).toList();

    // 1. Local glyph metrics: Height, Width, Aspect Ratio, Slant
    final heights = <double>[];
    final widths = <double>[];
    final aspectRatios = <double>[];
    final slants = <double>[];

    for (final stroke in validStrokes) {
      final box = stroke.boundingBox;
      final h = math.max(2.0, box.height);
      final w = math.max(2.0, box.width);
      heights.add(h);
      widths.add(w);
      aspectRatios.add(w / h);

      // Estimate stroke slant on primary downstrokes (filter out pure horizontal crossbars/t-bars)
      final pFirst = stroke.points.first;
      final pLast = stroke.points.last;
      final dx = pLast.x - pFirst.x;
      final dy = pLast.y - pFirst.y;
      // Slant in calligraphy is defined on downstrokes with vertical movement (|dy| >= |dx| * 0.45)
      if (dy.abs() > 3.0 && dy.abs() >= dx.abs() * 0.45) {
        final deg = math.atan2(dx, dy) * (180.0 / math.pi);
        slants.add(deg.clamp(-50.0, 50.0));
      }
    }

    if (slants.isEmpty) {
      slants.add(0.0);
    }

    final medH = _median(heights);
    // In natural handwriting, letters span distinct height tiers (body x-height vs tall ascenders).
    // Measure height MAD within the primary body height band so tall ascenders don't falsely penalize the student:
    final bodyHeights = heights.where((h) => h <= medH * 1.4 && h >= medH * 0.4).toList();
    final madH = bodyHeights.length >= 2 ? _mad(bodyHeights, medH) : math.max(1.0, _mad(heights, medH) * 0.45);

    final medW = _median(widths);
    final madW = _mad(widths, medW);
    final medSlant = _median(slants);
    final madSlant = _mad(slants, medSlant);
    final medAspect = _median(aspectRatios);

    // 2. Global Spatial Metrics: Inter-stroke horizontal spacing
    final sortedByX = List<HandwritingStroke>.from(validStrokes)
      ..sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));

    final spacings = <double>[];
    for (int i = 1; i < sortedByX.length; i++) {
      final gap = sortedByX[i].boundingBox.left - sortedByX[i - 1].boundingBox.right;
      // Filter out line returns / extreme gaps
      if (gap >= -5.0 && gap < medH * 2.5) {
        spacings.add(math.max(0.0, gap));
      }
    }

    final medSpacing = spacings.isNotEmpty ? _median(spacings) : medH * 0.25;
    final madSpacing = spacings.isNotEmpty ? _mad(spacings, medSpacing) : 1.0;

    // 3. Baseline drift (variance of bottom points relative to robust regression fit)
    // Filter out extreme descender strokes (g, y, p, q, j) that naturally drop below baseline
    final strokeBottoms = validStrokes.map((s) => s.boundingBox.bottom).toList();
    final medBottom = _median(strokeBottoms);

    final baselinePoints = <math.Point<double>>[];
    for (final s in validStrokes) {
      final bottom = s.boundingBox.bottom;
      // Exclude extreme descenders that drop significantly below standard baseline
      if (bottom <= medBottom + medH * 0.7) {
        baselinePoints.add(math.Point(s.boundingBox.center.dx, bottom));
      }
    }

    double baselineDrift = 5.0;
    if (baselinePoints.length >= 3) {
      // Linear regression on baseline contact points
      final xs = baselinePoints.map((p) => p.x).toList();
      final ys = baselinePoints.map((p) => p.y).toList();
      final xMean = xs.reduce((a, b) => a + b) / xs.length;
      final yMean = ys.reduce((a, b) => a + b) / ys.length;

      double num = 0.0, den = 0.0;
      for (int i = 0; i < xs.length; i++) {
        num += (xs[i] - xMean) * (ys[i] - yMean);
        den += (xs[i] - xMean) * (xs[i] - xMean);
      }
      final slope = den.abs() > 1e-4 ? (num / den) : 0.0;
      final intercept = yMean - slope * xMean;

      final residuals = <double>[];
      for (int i = 0; i < xs.length; i++) {
        final expectedY = slope * xs[i] + intercept;
        residuals.add((ys[i] - expectedY).abs());
      }
      baselineDrift = _mad(residuals);
    }

    // 4. Stroke curvature smoothness and tremor index
    final smoothnessScore = _computeStrokeSmoothness(validStrokes);

    return ExtractedGeometricFeatures(
      medianHeight: double.parse(medH.toStringAsFixed(2)),
      heightMad: double.parse(madH.toStringAsFixed(2)),
      medianWidth: double.parse(medW.toStringAsFixed(2)),
      widthMad: double.parse(madW.toStringAsFixed(2)),
      medianSlantDeg: double.parse(medSlant.toStringAsFixed(2)),
      slantMadDeg: double.parse(madSlant.toStringAsFixed(2)),
      medianAspectRatio: double.parse(medAspect.toStringAsFixed(2)),
      medianSpacing: double.parse(medSpacing.toStringAsFixed(2)),
      spacingMad: double.parse(madSpacing.toStringAsFixed(2)),
      baselineDriftPx: double.parse(baselineDrift.toStringAsFixed(2)),
      strokeSmoothness: double.parse(smoothnessScore.toStringAsFixed(2)),
      totalStrokes: validStrokes.length,
      estimatedGlyphs: validStrokes.length,
    );
  }

  static double _computeStrokeSmoothness(List<HandwritingStroke> strokes) {
    if (strokes.isEmpty) return 75.0;

    final roughnessValues = <double>[];

    for (final stroke in strokes) {
      final points = stroke.points;
      if (points.length < 5) continue;

      for (int i = 1; i < points.length - 1; i++) {
        final p0 = points[i - 1];
        final p1 = points[i];
        final p2 = points[i + 1];

        final dx1 = p1.x - p0.x;
        final dy1 = p1.y - p0.y;
        final dx2 = p2.x - p1.x;
        final dy2 = p2.y - p1.y;

        final angle1 = math.atan2(dy1, dx1);
        final angle2 = math.atan2(dy2, dx2);
        var diff = (angle2 - angle1).abs();
        if (diff > math.pi) diff = 2 * math.pi - diff;

        // Acute directional jitter (> 95° over short steps) indicates physical tremor
        if (diff > (math.pi * 0.52)) {
          roughnessValues.add(diff);
        }
      }
    }

    if (roughnessValues.isEmpty) return 96.0;

    final jitterRate = roughnessValues.length / strokes.length;
    final score = 100.0 - (jitterRate * 12.0);
    return score.clamp(35.0, 99.0);
  }

  static double _median(List<double> arr) {
    if (arr.isEmpty) return 0.0;
    final sorted = List<double>.from(arr)..sort();
    final mid = sorted.length ~/ 2;
    return sorted.length.isOdd ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2.0;
  }

  static double _mad(List<double> arr, [double? med]) {
    if (arr.length < 2) return 1.0;
    final m = med ?? _median(arr);
    final deviations = arr.map((x) => (x - m).abs()).toList();
    return math.max(0.5, _median(deviations));
  }
}

