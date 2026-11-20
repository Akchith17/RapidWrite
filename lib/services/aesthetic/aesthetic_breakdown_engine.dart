import 'dart:math' as math;
import 'dart:ui';

import '../../models/aesthetic_breakdown_model.dart';
import '../../models/aesthetic_evaluation.dart';
import '../../models/handwriting_stroke.dart';
import 'handwriting_feature_model.dart';
import 'stage3_reference_profile.dart';

/// Comprehensive Visual Aesthetic Breakdown Engine.
/// Segments the student's actual handwritten strokes into words, individual letters,
/// inter-letter gaps, and inter-word gaps against the active target sentence,
/// providing verifiable geometric measurements, visual overlays, and explainable category scores.
class AestheticBreakdownEngine {
  static AestheticBreakdown generateBreakdown({
    required List<HandwritingStroke> strokes,
    required String targetSentence,
    required ExtractedGeometricFeatures features,
    required AestheticEvaluation evaluation,
    PersonalHandwritingProfile? referenceProfile,
    String ageCohort = 'Standard',
  }) {
    final validStrokes = strokes.where((s) => s.points.isNotEmpty).toList();

    if (validStrokes.isEmpty || targetSentence.trim().isEmpty) {
      return _generateEmptyBreakdown(targetSentence, evaluation);
    }

    // 1. Clean and decompose target sentence into words
    final targetWords = targetSentence
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    // 2. Sort strokes horizontally in reading order
    final sortedStrokes = List<HandwritingStroke>.from(validStrokes)
      ..sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));

    final medH = math.max(18.0, features.medianHeight);

    // 3. Segment strokes into word clusters based on horizontal gaps
    final strokeWordClusters = _clusterStrokesIntoWords(
      sortedStrokes,
      targetWords.length,
      medH,
    );

    // 4. Within each word cluster, segment into individual letters
    final words = <WordSegmentation>[];
    final allLetters = <LetterSegmentation>[];

    for (int wIdx = 0; wIdx < strokeWordClusters.length; wIdx++) {
      final cluster = strokeWordClusters[wIdx];
      final expectedWord = wIdx < targetWords.length ? targetWords[wIdx] : 'word';

      final wordRect = _computeClusterBounds(cluster);
      final wordBaselineY = cluster.map((s) => s.boundingBox.bottom).reduce(math.max);

      final letters = _segmentClusterIntoLetters(
        cluster,
        expectedWord,
        wIdx,
        medH,
        features.medianSlantDeg,
      );

      allLetters.addAll(letters);

      words.add(WordSegmentation(
        index: wIdx,
        text: expectedWord,
        boundingBox: wordRect,
        letters: letters,
        baselineY: wordBaselineY,
        confidence: math.min(1.0, 0.70 + (letters.length / math.max(1, expectedWord.length)) * 0.25),
      ));
    }

    // 5. Measure Baseline & Linear Regression across all letters
    final baseline = _computeBaselineMeasurement(allLetters, sortedStrokes, medH);

    // 6. Update baseline deviations and outlier status for each letter
    final lettersWithDeviations = _applyBaselineDeviations(allLetters, baseline, features);

    // 7. Measure Spacings: inter-letter gaps and inter-word gaps
    final spacings = _computeSpacingMeasurements(words, lettersWithDeviations, medH);

    // 8. Generate Explainable Category Breakdowns
    final letterSizeCategory = _evaluateLetterSizeCategory(
      lettersWithDeviations,
      words,
      features,
      evaluation,
    );

    final slantCategory = _evaluateSlantCategory(
      lettersWithDeviations,
      words,
      features,
      evaluation,
    );

    final spacingCategory = _evaluateSpacingCategory(
      spacings,
      words,
      features,
      evaluation,
    );

    final baselineCategory = _evaluateBaselineCategory(
      baseline,
      lettersWithDeviations,
      words,
      features,
      evaluation,
    );

    final consistencyCategory = _evaluateConsistencyCategory(
      lettersWithDeviations,
      words,
      features,
      evaluation,
      referenceProfile,
      ageCohort,
    );

    return AestheticBreakdown(
      targetSentence: targetSentence,
      words: words,
      letters: lettersWithDeviations,
      spacings: spacings,
      baseline: baseline,
      letterSize: letterSizeCategory,
      slant: slantCategory,
      spacing: spacingCategory,
      baselineCategory: baselineCategory,
      consistency: consistencyCategory,
      overallAestheticScore: evaluation.overallAestheticScore,
      grade: evaluation.grade,
      hasPersonalProfile: referenceProfile != null,
      personalStyleTags: referenceProfile?.personalStyleTags ?? evaluation.personalStyleTags,
      canMeasureReliably: allLetters.length >= 2,
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // WORD & LETTER SPATIAL CLUSTERING ALGORITHMS
  // ──────────────────────────────────────────────────────────────────────────

  static List<List<HandwritingStroke>> _clusterStrokesIntoWords(
    List<HandwritingStroke> sortedStrokes,
    int expectedWordCount,
    double medianHeight,
  ) {
    if (sortedStrokes.isEmpty) return [];
    if (expectedWordCount <= 1) return [sortedStrokes];

    // Compute horizontal gaps between consecutive strokes
    final gaps = <double>[];
    for (int i = 0; i < sortedStrokes.length - 1; i++) {
      final gap = sortedStrokes[i + 1].boundingBox.left - sortedStrokes[i].boundingBox.right;
      gaps.add(gap);
    }

    // Adaptive word gap threshold
    double wordGapThreshold = math.max(16.0, medianHeight * 0.45);

    // If gaps are generally smaller, use gap distribution percentile
    final positiveGaps = gaps.where((g) => g > 0).toList()..sort();
    if (positiveGaps.isNotEmpty && positiveGaps.length >= expectedWordCount) {
      final splitIndex = math.max(0, positiveGaps.length - (expectedWordCount - 1));
      final dynamicThreshold = positiveGaps[splitIndex];
      if (dynamicThreshold > 8.0) {
        wordGapThreshold = math.min(wordGapThreshold, dynamicThreshold * 0.85);
      }
    }

    final clusters = <List<HandwritingStroke>>[];
    var currentCluster = <HandwritingStroke>[sortedStrokes.first];

    for (int i = 0; i < sortedStrokes.length - 1; i++) {
      final gap = gaps[i];
      if (gap >= wordGapThreshold && clusters.length < expectedWordCount - 1) {
        clusters.add(currentCluster);
        currentCluster = [sortedStrokes[i + 1]];
      } else {
        currentCluster.add(sortedStrokes[i + 1]);
      }
    }
    clusters.add(currentCluster);

    return clusters;
  }

  static Rect _computeClusterBounds(List<HandwritingStroke> strokes) {
    if (strokes.isEmpty) return Rect.zero;
    double left = strokes.first.boundingBox.left;
    double top = strokes.first.boundingBox.top;
    double right = strokes.first.boundingBox.right;
    double bottom = strokes.first.boundingBox.bottom;

    for (final s in strokes) {
      final b = s.boundingBox;
      if (b.left < left) left = b.left;
      if (b.top < top) top = b.top;
      if (b.right > right) right = b.right;
      if (b.bottom > bottom) bottom = b.bottom;
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }

  static List<LetterSegmentation> _segmentClusterIntoLetters(
    List<HandwritingStroke> strokes,
    String expectedWord,
    int wordIndex,
    double medianHeight,
    double defaultSlantDeg,
  ) {
    final cleanChars = expectedWord.split('').where((c) => RegExp(r'[a-zA-Z0-9]').hasMatch(c)).toList();
    if (cleanChars.isEmpty) {
      cleanChars.addAll(expectedWord.split(''));
    }

    final targetCharCount = math.max(1, cleanChars.length);
    final letters = <LetterSegmentation>[];

    // Cluster overlapping or closely adjacent strokes into glyph units
    final glyphStrokeGroups = <List<HandwritingStroke>>[];
    var currentGroup = <HandwritingStroke>[strokes.first];

    for (int i = 0; i < strokes.length - 1; i++) {
      final sCurr = strokes[i];
      final sNext = strokes[i + 1];

      final overlap = sCurr.boundingBox.right - sNext.boundingBox.left;
      final gap = sNext.boundingBox.left - sCurr.boundingBox.right;

      // Group strokes if they heavily overlap horizontally (like 't' stem + crossbar or dot on 'i')
      final shouldGroup = overlap > 3.0 || gap < math.max(3.0, medianHeight * 0.12);

      if (shouldGroup && glyphStrokeGroups.length + 1 < targetCharCount) {
        currentGroup.add(sNext);
      } else {
        glyphStrokeGroups.add(currentGroup);
        currentGroup = [sNext];
      }
    }
    glyphStrokeGroups.add(currentGroup);

    // Map glyph groups to target characters
    for (int gIdx = 0; gIdx < glyphStrokeGroups.length; gIdx++) {
      final group = glyphStrokeGroups[gIdx];
      final bounds = _computeClusterBounds(group);

      final charIndex = math.min(targetCharCount - 1, ((gIdx / glyphStrokeGroups.length) * targetCharCount).floor());
      final char = cleanChars[charIndex];

      final h = math.max(3.0, bounds.height);
      final w = math.max(3.0, bounds.width);

      // Estimate slant on dominant downstrokes in this letter
      double slantDeg = defaultSlantDeg;
      for (final s in group) {
        if (s.points.length >= 2) {
          final pFirst = s.points.first;
          final pLast = s.points.last;
          final dx = pLast.x - pFirst.x;
          final dy = pLast.y - pFirst.y;
          if (dy.abs() > 3.0 && dy.abs() >= dx.abs() * 0.40) {
            slantDeg = (math.atan2(dx, dy) * (180.0 / math.pi)).clamp(-50.0, 50.0);
            break;
          }
        }
      }

      final isAscender = RegExp(r'[A-Z|b|d|f|h|k|l|t]').hasMatch(char);
      final isDescender = RegExp(r'[g|j|p|q|y]').hasMatch(char);
      final isBodyLetter = !isAscender && !isDescender;

      letters.add(LetterSegmentation(
        char: char,
        boundingBox: bounds,
        height: double.parse(h.toStringAsFixed(1)),
        width: double.parse(w.toStringAsFixed(1)),
        aspectRatio: double.parse((w / h).toStringAsFixed(2)),
        slantAngleDeg: double.parse(slantDeg.toStringAsFixed(1)),
        baselineY: double.parse(bounds.bottom.toStringAsFixed(1)),
        baselineDeviationPx: 0.0, // Computed in next step
        isAscender: isAscender,
        isDescender: isDescender,
        isBodyLetter: isBodyLetter,
        isHeightOutlier: false,
        isSlantOutlier: false,
        isBaselineOutlier: false,
        confidence: 0.85,
        wordIndex: wordIndex,
        letterIndexInWord: charIndex,
      ));
    }

    return letters;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // BASELINE DETECTION & RESIDUAL CALCULATION
  // ──────────────────────────────────────────────────────────────────────────

  static BaselineMeasurement _computeBaselineMeasurement(
    List<LetterSegmentation> letters,
    List<HandwritingStroke> strokes,
    double medianHeight,
  ) {
    if (letters.isEmpty) {
      return const BaselineMeasurement(
        slope: 0.0,
        intercept: 100.0,
        angleDeg: 0.0,
        trajectory: BaselineTrajectory.level,
        lineStart: Offset(0, 100),
        lineEnd: Offset(300, 100),
        residualDriftMadPx: 0.0,
        isConsistent: true,
        confidence: 0.5,
      );
    }

    // Filter out descender letters (g, j, p, q, y) that drop below baseline
    final nonDescenders = letters.where((l) => !l.isDescender).toList();
    final sampleLetters = nonDescenders.isNotEmpty ? nonDescenders : letters;

    final xs = sampleLetters.map((l) => l.boundingBox.center.dx).toList();
    final ys = sampleLetters.map((l) => l.boundingBox.bottom).toList();

    double slope = 0.0;
    double intercept = ys.reduce((a, b) => a + b) / ys.length;

    if (xs.length >= 2) {
      final xMean = xs.reduce((a, b) => a + b) / xs.length;
      final yMean = ys.reduce((a, b) => a + b) / ys.length;

      double num = 0.0;
      double den = 0.0;
      for (int i = 0; i < xs.length; i++) {
        num += (xs[i] - xMean) * (ys[i] - yMean);
        den += (xs[i] - xMean) * (xs[i] - xMean);
      }
      slope = den.abs() > 1e-4 ? (num / den) : 0.0;
      intercept = yMean - slope * xMean;
    }

    final angleDeg = (math.atan(slope) * (180.0 / math.pi));

    BaselineTrajectory trajectory = BaselineTrajectory.level;
    if (slope < -0.035) {
      trajectory = BaselineTrajectory.ascending;
    } else if (slope > 0.035) {
      trajectory = BaselineTrajectory.descending;
    }

    final minX = letters.map((l) => l.boundingBox.left).reduce(math.min);
    final maxX = letters.map((l) => l.boundingBox.right).reduce(math.max);

    final lineStart = Offset(math.max(0.0, minX - 10.0), slope * (minX - 10.0) + intercept);
    final lineEnd = Offset(maxX + 15.0, slope * (maxX + 15.0) + intercept);

    // Compute residual drift MAD
    final residuals = <double>[];
    for (final l in sampleLetters) {
      final expectedY = slope * l.boundingBox.center.dx + intercept;
      residuals.add((l.boundingBox.bottom - expectedY).abs());
    }

    final driftMad = _computeMad(residuals);

    return BaselineMeasurement(
      slope: double.parse(slope.toStringAsFixed(4)),
      intercept: double.parse(intercept.toStringAsFixed(2)),
      angleDeg: double.parse(angleDeg.toStringAsFixed(1)),
      trajectory: trajectory,
      lineStart: lineStart,
      lineEnd: lineEnd,
      residualDriftMadPx: double.parse(driftMad.toStringAsFixed(1)),
      isConsistent: driftMad < medianHeight * 0.22,
      confidence: math.min(1.0, 0.65 + (xs.length / 10.0) * 0.30),
    );
  }

  static List<LetterSegmentation> _applyBaselineDeviations(
    List<LetterSegmentation> letters,
    BaselineMeasurement baseline,
    ExtractedGeometricFeatures features,
  ) {
    final updated = <LetterSegmentation>[];
    final medH = math.max(18.0, features.medianHeight);
    final medSlant = features.medianSlantDeg;
    final slantMad = math.max(3.0, features.slantMadDeg);
    final driftMad = math.max(2.0, baseline.residualDriftMadPx);

    // Classify height outliers based on body x-height letters
    final bodyHeights = letters.where((l) => l.isBodyLetter).map((l) => l.height).toList();
    final bodyMedH = bodyHeights.isNotEmpty ? _computeMedian(bodyHeights) : medH;
    final bodyMadH = bodyHeights.length >= 2 ? _computeMad(bodyHeights, bodyMedH) : 3.0;

    for (final l in letters) {
      final expectedY = baseline.expectedYAt(l.boundingBox.center.dx);
      final deviation = l.boundingBox.bottom - expectedY;

      // Check size outlier
      bool isHeightOutlier = false;
      if (l.isBodyLetter) {
        isHeightOutlier = (l.height - bodyMedH).abs() > math.max(4.0, bodyMadH * 2.2);
      } else if (l.isAscender) {
        // Ascender should be taller than body
        isHeightOutlier = l.height < bodyMedH * 1.05 || l.height > bodyMedH * 2.5;
      }

      // Check slant outlier: deviates more than 12° from median slant
      final isSlantOutlier = (l.slantAngleDeg - medSlant).abs() > math.max(10.0, slantMad * 2.2);

      // Check baseline outlier: non-descender letter whose bottom is far from baseline
      final isBaselineOutlier = !l.isDescender && deviation.abs() > math.max(5.0, driftMad * 2.0);

      updated.add(LetterSegmentation(
        char: l.char,
        boundingBox: l.boundingBox,
        height: l.height,
        width: l.width,
        aspectRatio: l.aspectRatio,
        slantAngleDeg: l.slantAngleDeg,
        baselineY: l.baselineY,
        baselineDeviationPx: double.parse(deviation.toStringAsFixed(1)),
        isAscender: l.isAscender,
        isDescender: l.isDescender,
        isBodyLetter: l.isBodyLetter,
        isHeightOutlier: isHeightOutlier,
        isSlantOutlier: isSlantOutlier,
        isBaselineOutlier: isBaselineOutlier,
        confidence: l.confidence,
        wordIndex: l.wordIndex,
        letterIndexInWord: l.letterIndexInWord,
        strokeIndices: l.strokeIndices,
      ));
    }

    return updated;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // SPACING MEASUREMENT CALCULATIONS
  // ──────────────────────────────────────────────────────────────────────────

  static List<SpacingMeasurement> _computeSpacingMeasurements(
    List<WordSegmentation> words,
    List<LetterSegmentation> letters,
    double medianHeight,
  ) {
    final measurements = <SpacingMeasurement>[];

    // 1. Inter-letter gaps within each word
    for (final w in words) {
      final wLetters = letters.where((l) => l.wordIndex == w.index).toList()
        ..sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));

      for (int i = 0; i < wLetters.length - 1; i++) {
        final l1 = wLetters[i];
        final l2 = wLetters[i + 1];

        final gapPx = l2.boundingBox.left - l1.boundingBox.right;
        final midY = (l1.boundingBox.center.dy + l2.boundingBox.center.dy) / 2.0;

        final isCramped = gapPx < 1.0; // Overlapping
        final isExcessive = gapPx > medianHeight * 0.70;

        measurements.add(SpacingMeasurement(
          isWordGap: false,
          leftLabel: l1.char,
          rightLabel: l2.char,
          startPoint: Offset(l1.boundingBox.right, midY),
          endPoint: Offset(l2.boundingBox.left, midY),
          gapPx: double.parse(gapPx.toStringAsFixed(1)),
          isCramped: isCramped,
          isExcessive: isExcessive,
          confidence: 0.90,
        ));
      }
    }

    // 2. Inter-word gaps across the sentence
    final sortedWords = List<WordSegmentation>.from(words)
      ..sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));

    final wordGaps = <double>[];
    for (int i = 0; i < sortedWords.length - 1; i++) {
      final gap = sortedWords[i + 1].boundingBox.left - sortedWords[i].boundingBox.right;
      if (gap > 0) wordGaps.add(gap);
    }
    final medWordGap = wordGaps.isNotEmpty ? _computeMedian(wordGaps) : medianHeight * 0.75;

    for (int i = 0; i < sortedWords.length - 1; i++) {
      final w1 = sortedWords[i];
      final w2 = sortedWords[i + 1];

      final gapPx = w2.boundingBox.left - w1.boundingBox.right;
      final midY = (w1.boundingBox.center.dy + w2.boundingBox.center.dy) / 2.0;

      final isCramped = gapPx < math.max(6.0, medWordGap * 0.45);
      final isExcessive = gapPx > math.max(24.0, medWordGap * 1.9);

      measurements.add(SpacingMeasurement(
        isWordGap: true,
        leftLabel: w1.text,
        rightLabel: w2.text,
        startPoint: Offset(w1.boundingBox.right, midY),
        endPoint: Offset(w2.boundingBox.left, midY),
        gapPx: double.parse(gapPx.toStringAsFixed(1)),
        isCramped: isCramped,
        isExcessive: isExcessive,
        confidence: 0.92,
      ));
    }

    return measurements;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // EXPLAINABLE CATEGORY EVALUATION GENERATORS
  // ──────────────────────────────────────────────────────────────────────────

  static CategoryBreakdown _evaluateLetterSizeCategory(
    List<LetterSegmentation> letters,
    List<WordSegmentation> words,
    ExtractedGeometricFeatures features,
    AestheticEvaluation evaluation,
  ) {
    final bodyLetters = letters.where((l) => l.isBodyLetter).toList();
    final ascenders = letters.where((l) => l.isAscender).toList();
    final descenders = letters.where((l) => l.isDescender).toList();

    final bodyHeights = bodyLetters.map((l) => l.height).toList();
    final medBodyH = bodyHeights.isNotEmpty ? _computeMedian(bodyHeights) : features.medianHeight;
    final madBodyH = bodyHeights.length >= 2 ? _computeMad(bodyHeights, medBodyH) : features.heightMad;
    final varPct = ((madBodyH / math.max(15.0, medBodyH)) * 100.0).clamp(0.0, 100.0);

    final outliers = letters.where((l) => l.isHeightOutlier).toList();
    final affectedRegions = <String>[];

    for (final out in outliers.take(3)) {
      final wordText = out.wordIndex < words.length ? words[out.wordIndex].text : 'word';
      if (out.isBodyLetter) {
        final diff = out.height - medBodyH;
        final dir = diff > 0 ? 'taller' : 'smaller';
        affectedRegions.add(
          'In word "$wordText", letter "${out.char}" is ${out.height}px (${diff.abs().toStringAsFixed(1)}px $dir than average body height ${medBodyH.toStringAsFixed(1)}px).',
        );
      } else if (out.isAscender) {
        affectedRegions.add(
          'In word "$wordText", ascender letter "${out.char}" is ${out.height}px (insufficient height difference from standard body letters).',
        );
      }
    }

    if (affectedRegions.isEmpty) {
      affectedRegions.add('All letter heights remain closely aligned with expected proportions.');
    }

    String suggestion = 'Consistent letter sizing! Keep practicing to maintain uniform letter scales.';
    if (outliers.isNotEmpty) {
      suggestion = 'Try to keep lowercase body letters (like "a", "e", "o", "m") at a uniform height, while extending tall letters ("t", "d", "b", "l") distinctly higher.';
    }

    return CategoryBreakdown(
      categoryName: 'Letter Size & Proportion',
      score: evaluation.letterFormationScore,
      whatWasMeasured: 'Measured individual height and width of all ${letters.length} detected letters across ${words.length} words, comparing body x-heights against ascenders (${ascenders.length}) and descenders (${descenders.length}).',
      whatWasDetected: 'Median body letter height is ${medBodyH.toStringAsFixed(1)}px (variation MAD: ${madBodyH.toStringAsFixed(1)}px, ${varPct.toStringAsFixed(1)}% size variance). ${outliers.length} size outlier(s) detected.',
      affectedRegions: affectedRegions,
      suggestion: suggestion,
      confidence: 0.94,
      isReliable: letters.length >= 3,
      metrics: {
        'medianHeightPx': medBodyH,
        'heightMadPx': madBodyH,
        'heightVariationPct': varPct,
        'bodyLetterCount': bodyLetters.length,
        'ascenderCount': ascenders.length,
        'descenderCount': descenders.length,
        'outlierCount': outliers.length,
      },
    );
  }

  static CategoryBreakdown _evaluateSlantCategory(
    List<LetterSegmentation> letters,
    List<WordSegmentation> words,
    ExtractedGeometricFeatures features,
    AestheticEvaluation evaluation,
  ) {
    final medSlant = features.medianSlantDeg;
    final madSlant = features.slantMadDeg;

    String slantDesc = 'Upright Vertical (${medSlant.abs().toStringAsFixed(1)}°)';
    if (medSlant > 4.5) {
      slantDesc = 'Right / Forward Italic Slant (+${medSlant.toStringAsFixed(1)}°)';
    } else if (medSlant < -4.5) {
      slantDesc = 'Left / Backward Slant (${medSlant.toStringAsFixed(1)}°)';
    }

    final outliers = letters.where((l) => l.isSlantOutlier).toList();
    final affectedRegions = <String>[];

    for (final out in outliers.take(3)) {
      final wordText = out.wordIndex < words.length ? words[out.wordIndex].text : 'word';
      final diff = out.slantAngleDeg - medSlant;
      affectedRegions.add(
        'In word "$wordText", letter "${out.char}" has a slant of ${out.slantAngleDeg}° (${diff.abs().toStringAsFixed(1)}° deviation from your sentence median of ${medSlant.toStringAsFixed(1)}°).',
      );
    }

    if (affectedRegions.isEmpty) {
      affectedRegions.add('Slant angle remains steady and uniform across all words in this sentence.');
    }

    String suggestion = 'Excellent slant consistency! Your natural slant angle ($slantDesc) is maintained steadily across the entire sentence.';
    if (outliers.isNotEmpty) {
      suggestion = 'Your natural slant angle ($slantDesc) is respected. To improve, keep downstrokes tilted at this same steady angle from the start to the end of the line.';
    }

    return CategoryBreakdown(
      categoryName: 'Handwriting Slant & Direction',
      score: evaluation.slantConsistencyScore,
      whatWasMeasured: 'Estimated stroke inclination angle (in degrees from vertical) on primary downstrokes for every letter. Natural right, left, or upright handwriting angles are celebrated equally.',
      whatWasDetected: 'Natural handwriting style: $slantDesc with an angular consistency MAD of ${madSlant.toStringAsFixed(1)}°. ${outliers.length} abrupt angle shift(s) detected.',
      affectedRegions: affectedRegions,
      suggestion: suggestion,
      confidence: 0.92,
      isReliable: letters.length >= 3,
      metrics: {
        'medianSlantDeg': medSlant,
        'slantMadDeg': madSlant,
        'slantStyle': slantDesc,
        'outlierCount': outliers.length,
      },
    );
  }

  static CategoryBreakdown _evaluateSpacingCategory(
    List<SpacingMeasurement> spacings,
    List<WordSegmentation> words,
    ExtractedGeometricFeatures features,
    AestheticEvaluation evaluation,
  ) {
    final letterGaps = spacings.where((s) => !s.isWordGap).toList();
    final wordGaps = spacings.where((s) => s.isWordGap).toList();

    final lGapValues = letterGaps.map((s) => s.gapPx).toList();
    final wGapValues = wordGaps.map((s) => s.gapPx).toList();

    final medLetterGap = lGapValues.isNotEmpty ? _computeMedian(lGapValues) : 4.0;
    final medWordGap = wGapValues.isNotEmpty ? _computeMedian(wGapValues) : 22.0;

    final crampedLetterGaps = letterGaps.where((s) => s.isCramped).length;
    final excessiveWordGaps = wordGaps.where((s) => s.isExcessive).length;
    final crampedWordGaps = wordGaps.where((s) => s.isCramped).length;

    final affectedRegions = <String>[];
    for (final s in wordGaps.where((s) => s.isOutlier).take(2)) {
      if (s.isExcessive) {
        affectedRegions.add(
          'Gap between word "${s.leftLabel}" and "${s.rightLabel}" is ${s.gapPx}px (noticeably wider than your ${medWordGap.toStringAsFixed(1)}px average).',
        );
      } else if (s.isCramped) {
        affectedRegions.add(
          'Gap between word "${s.leftLabel}" and "${s.rightLabel}" is ${s.gapPx}px (too cramped, words touch or blur together).',
        );
      }
    }

    for (final s in letterGaps.where((s) => s.isCramped).take(2)) {
      affectedRegions.add(
        'Letters "${s.leftLabel}" and "${s.rightLabel}" overlap with a cramped gap of ${s.gapPx}px.',
      );
    }

    if (affectedRegions.isEmpty) {
      affectedRegions.add('Both letter gaps and word intervals show steady rhythmic separation.');
    }

    String suggestion = 'Great spacing rhythm between letters and words!';
    if (crampedWordGaps > 0) {
      suggestion = 'Leave a clear finger-width space between words so reader eyes can separate them easily.';
    } else if (excessiveWordGaps > 0) {
      suggestion = 'Keep word gaps consistent so large gaps do not interrupt reading fluency.';
    } else if (crampedLetterGaps > 0) {
      suggestion = 'Give adjacent letters room to breathe without unintentional stroke overlap.';
    }

    // Separate letter-spacing and word-spacing subscores
    final letterScore = (100.0 - (crampedLetterGaps * 8.0)).clamp(40.0, 99.0);
    final wordScore = (100.0 - (excessiveWordGaps * 9.0 + crampedWordGaps * 12.0)).clamp(40.0, 99.0);

    return CategoryBreakdown(
      categoryName: 'Letter & Word Spacing Rhythm',
      score: evaluation.spacingScore,
      whatWasMeasured: 'Separately measured ${letterGaps.length} inter-letter gaps within words and ${wordGaps.length} inter-word gaps across the sentence.',
      whatWasDetected: 'Median letter gap: ${medLetterGap.toStringAsFixed(1)}px • Median word gap: ${medWordGap.toStringAsFixed(1)}px. ${crampedLetterGaps + crampedWordGaps + excessiveWordGaps} spacing outlier(s) detected.',
      affectedRegions: affectedRegions,
      suggestion: suggestion,
      confidence: 0.91,
      isReliable: spacings.isNotEmpty,
      metrics: {
        'letterSpacingScore': letterScore,
        'wordSpacingScore': wordScore,
        'medianLetterGapPx': medLetterGap,
        'medianWordGapPx': medWordGap,
        'crampedLetterCount': crampedLetterGaps,
        'crampedWordCount': crampedWordGaps,
        'excessiveWordCount': excessiveWordGaps,
      },
    );
  }

  static CategoryBreakdown _evaluateBaselineCategory(
    BaselineMeasurement baseline,
    List<LetterSegmentation> letters,
    List<WordSegmentation> words,
    ExtractedGeometricFeatures features,
    AestheticEvaluation evaluation,
  ) {
    final outliers = letters.where((l) => l.isBaselineOutlier).toList();
    final affectedRegions = <String>[];

    for (final out in outliers.take(3)) {
      final wordText = out.wordIndex < words.length ? words[out.wordIndex].text : 'word';
      final dir = out.baselineDeviationPx > 0 ? 'below' : 'above';
      affectedRegions.add(
        'In word "$wordText", letter "${out.char}" rests ${out.baselineDeviationPx.abs().toStringAsFixed(1)}px $dir the baseline regression line.',
      );
    }

    if (affectedRegions.isEmpty) {
      affectedRegions.add('All letters rest steadily along the estimated baseline with minimal drift.');
    }

    String suggestion = 'Terrific horizontal line discipline! Letters sit flat along the line.';
    if (outliers.isNotEmpty) {
      suggestion = 'Try to rest the base of all body letters along an imaginary steady horizontal line to prevent individual letters from sinking or floating.';
    }

    return CategoryBreakdown(
      categoryName: 'Baseline Stability & Alignment',
      score: evaluation.alignmentScore,
      whatWasMeasured: 'Calculated robust linear regression baseline trajectory across the sentence contact points and measured vertical deviation for every individual letter.',
      whatWasDetected: 'Trajectory: ${baseline.trajectoryName} with a residual baseline drift MAD of ${baseline.residualDriftMadPx.toStringAsFixed(1)}px. ${outliers.length} vertical baseline deviation(s) detected.',
      affectedRegions: affectedRegions,
      suggestion: suggestion,
      confidence: 0.93,
      isReliable: letters.length >= 3,
      metrics: {
        'trajectory': baseline.trajectoryName,
        'angleDeg': baseline.angleDeg,
        'residualDriftPx': baseline.residualDriftMadPx,
        'outlierCount': outliers.length,
      },
    );
  }

  static CategoryBreakdown _evaluateConsistencyCategory(
    List<LetterSegmentation> letters,
    List<WordSegmentation> words,
    ExtractedGeometricFeatures features,
    AestheticEvaluation evaluation,
    PersonalHandwritingProfile? referenceProfile,
    String ageCohort,
  ) {
    final hasProf = referenceProfile != null;
    final observations = <String>[];

    if (hasProf) {
      observations.add('Compared against your personal reference profile: natural slant (${features.medianSlantDeg.toStringAsFixed(1)}°) and letter scale are recognized as your personal style.');
    } else {
      observations.add('Evaluated against educational consistency criteria: rhythm, baseline stability, and stroke smoothness.');
    }

    if (evaluation.strokeSmoothnessScore >= 85) {
      observations.add('Strokes exhibit fluid curvature and low physical tremor (${features.strokeSmoothness.toStringAsFixed(0)}% smoothness index).');
    }

    String suggestion = 'Outstanding handwriting harmony and visual organisation! Keep writing with this steady rhythm.';
    if (evaluation.consistencyScore < 75) {
      suggestion = 'Focus on keeping your writing pace steady. Rushing can cause slant and letter heights to wobble toward the end of long sentences.';
    }

    return CategoryBreakdown(
      categoryName: 'Overall Consistency & Visual Organisation',
      score: evaluation.consistencyScore,
      whatWasMeasured: 'Synthesizes intra-sentence consistency across size, slant, spacing, baseline stability, and stroke curvature fluency.',
      whatWasDetected: 'Visual organisation score: ${evaluation.visualOrganizationScore.toStringAsFixed(1)}/100 • Stroke smoothness: ${features.strokeSmoothness.toStringAsFixed(1)}% • Grade: ${evaluation.grade}.',
      affectedRegions: observations,
      suggestion: suggestion,
      confidence: 0.95,
      isReliable: true,
      metrics: {
        'overallScore': evaluation.overallAestheticScore,
        'grade': evaluation.grade,
        'smoothnessScore': features.strokeSmoothness,
        'visualOrganizationScore': evaluation.visualOrganizationScore,
        'readabilityScore': evaluation.readabilityScore,
        'hasPersonalProfile': hasProf,
      },
    );
  }

  static AestheticBreakdown _generateEmptyBreakdown(String targetSentence, AestheticEvaluation eval) {
    const emptyCat = CategoryBreakdown(
      categoryName: 'Not Measured',
      score: 0,
      whatWasMeasured: 'No valid handwriting strokes detected on the canvas.',
      whatWasDetected: 'Unable to measure reliably.',
      affectedRegions: ['Canvas was empty at submission time.'],
      suggestion: 'Write the target sentence on the canvas and submit again.',
      confidence: 0.0,
      isReliable: false,
    );

    return AestheticBreakdown(
      targetSentence: targetSentence,
      words: const [],
      letters: const [],
      spacings: const [],
      baseline: const BaselineMeasurement(
        slope: 0,
        intercept: 0,
        angleDeg: 0,
        trajectory: BaselineTrajectory.level,
        lineStart: Offset.zero,
        lineEnd: Offset.zero,
        residualDriftMadPx: 0,
        isConsistent: true,
        confidence: 0,
      ),
      letterSize: emptyCat,
      slant: emptyCat,
      spacing: emptyCat,
      baselineCategory: emptyCat,
      consistency: emptyCat,
      overallAestheticScore: eval.overallAestheticScore,
      grade: eval.grade,
      hasPersonalProfile: false,
      canMeasureReliably: false,
    );
  }

  // Helper statistical functions
  static double _computeMedian(List<double> arr) {
    if (arr.isEmpty) return 0.0;
    final s = List<double>.from(arr)..sort();
    final mid = s.length ~/ 2;
    return s.length.isOdd ? s[mid] : (s[mid - 1] + s[mid]) / 2.0;
  }

  static double _computeMad(List<double> arr, [double? med]) {
    if (arr.length < 2) return 1.0;
    final m = med ?? _computeMedian(arr);
    final devs = arr.map((x) => (x - m).abs()).toList();
    return math.max(0.5, _computeMedian(devs));
  }
}
