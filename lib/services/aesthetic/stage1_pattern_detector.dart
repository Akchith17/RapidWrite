import 'dart:math' as math;
import '../../models/handwriting_stroke.dart';
import 'handwriting_feature_model.dart';

/// STAGE 1 – Identify Repeated Letters and Common Stroke Patterns
/// Anchors sequential dynamic ink strokes or glyph components against the target sentence,
/// identifies letter repetitions, and clusters stroke patterns.
class Stage1PatternDetector {
  static Map<String, dynamic> analyze({
    required List<HandwritingStroke> strokes,
    required String targetSentence,
  }) {
    if (strokes.isEmpty) {
      return {
        'occurrences': <String, List<LetterOccurrence>>{},
        'patterns': <RepeatedLetterPattern>[],
        'totalGlyphs': 0,
      };
    }

    final cleanTarget = targetSentence.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final charList = cleanTarget.split('');
    final occurrences = <String, List<LetterOccurrence>>{};

    // Group valid strokes and order horizontally (left-to-right reading order)
    final sortedStrokes = strokes.where((s) => s.points.isNotEmpty).toList()
      ..sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));

    final totalStrokes = sortedStrokes.length;
    final totalTargetChars = charList.isNotEmpty ? charList.length : 1;

    for (int i = 0; i < sortedStrokes.length; i++) {
      final stroke = sortedStrokes[i];
      final box = stroke.boundingBox;

      // Approximate mapping from stroke timeline/position to expected target character
      final expectedCharIndex = math.min(
        totalTargetChars - 1,
        ((i / totalStrokes) * totalTargetChars).floor(),
      );
      final expectedChar = charList.isNotEmpty ? charList[expectedCharIndex] : '?';

      // Estimate stroke slant angle via start-to-end vector and midpoints
      final pFirst = stroke.points.first;
      final pLast = stroke.points.last;
      final dx = pLast.x - pFirst.x;
      final dy = pLast.y - pFirst.y;

      // Slant angle in degrees from vertical (vertical upright = 0°)
      double slantDeg = 0.0;
      if (dy.abs() > 2.0) {
        final rad = math.atan2(dx, dy);
        slantDeg = rad * (180.0 / math.pi);
        // Normalize within [-60, +60]
        slantDeg = slantDeg.clamp(-60.0, 60.0);
      }

      final double width = math.max(1.0, box.width);
      final double height = math.max(1.0, box.height);
      final double aspect = width / height;

      final occ = LetterOccurrence(
        char: expectedChar,
        strokeIndex: i,
        x: box.left,
        y: box.top,
        width: width,
        height: height,
        aspectRatio: aspect,
        slantAngleDeg: slantDeg,
        strokeLength: stroke.totalLength,
        confidence: math.max(0.4, 1.0 - ((i / totalStrokes) - (expectedCharIndex / totalTargetChars)).abs()),
      );

      occurrences.putIfAbsent(expectedChar, () => []).add(occ);
    }

    // Identify high-frequency repeated letters (e.g. e, t, a, o, s, d, l, r)
    final patterns = <RepeatedLetterPattern>[];
    for (final entry in occurrences.entries) {
      if (entry.value.length >= 2) {
        final heights = entry.value.map((o) => o.height).toList();
        final slants = entry.value.map((o) => o.slantAngleDeg).toList();

        final medH = _median(heights);
        final madH = _mad(heights, medH);
        final medS = _median(slants);
        final madS = _mad(slants, medS);

        patterns.add(RepeatedLetterPattern(
          char: entry.key,
          occurrences: entry.value.length,
          medianHeight: medH,
          heightMad: madH,
          medianSlantDeg: medS,
          slantMadDeg: madS,
        ));
      }
    }

    return {
      'occurrences': occurrences,
      'patterns': patterns,
      'totalGlyphs': sortedStrokes.length,
    };
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

