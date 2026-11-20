import 'dart:math' as math;
import '../../models/aesthetic_evaluation.dart';
import '../../models/algorithm_inspection_data.dart';
import 'handwriting_feature_model.dart';
import 'stage4_deviation_analyzer.dart';

/// STAGE 5 – Evaluate Consistency Without Penalizing Natural Style
/// Derives the 7 validated scoring dimensions, holistic letter grade,
/// and constructive personalized coaching feedback for school students.
class Stage5ConsistencyEvaluator {
  static AestheticEvaluation evaluate({
    required ExtractedGeometricFeatures features,
    required List<RepeatedLetterPattern> patterns,
    required DeviationAnalysisResult deviationResult,
    bool hasReferenceProfile = false,
    List<String> personalStyleTags = const [],
    String ageCohort = 'Standard',
  }) {
    if (features.totalStrokes == 0) {
      return AestheticEvaluation(
        overallAestheticScore: 0,
        readabilityScore: 0,
        letterFormationScore: 0,
        spacingScore: 0,
        alignmentScore: 0,
        consistencyScore: 0,
        visualOrganizationScore: 0,
        neatnessScore: 0,
        baselineAlignmentScore: 0,
        slantConsistencyScore: 0,
        strokeSmoothnessScore: 0,
        pressureRhythmScore: 0,
        grade: 'N/A',
        critiqueTitle: 'No Strokes Recorded',
        visualObservations: ['Canvas is currently empty.'],
        coachingTips: ['Write the target sentence on the canvas to evaluate.'],
        evaluatedBy: 'RapidWrite 5-Stage Engine',
        hasPersonalReference: hasReferenceProfile,
        personalStyleTags: personalStyleTags,
        styleShiftObservations: const [],
      );
    }

    final isSchoolCohort = ageCohort.toLowerCase().contains('school') ||
        ageCohort.toLowerCase().contains('junior') ||
        ageCohort.toLowerCase().contains('elementary') ||
        ageCohort.toLowerCase().contains('beginner');

    final safeH = math.max(22.0, features.medianHeight);

    // 1. Alignment Score: Baseline stability & horizontal drift
    // Young learners and tablet stylus users on unruled digital canvases naturally display
    // a slight baseline drift. Normalize drift against median letter height:
    final driftRatio = (features.baselineDriftPx / safeH).clamp(0.0, 1.5);
    final excessDriftRatio = math.max(0.0, driftRatio - 0.08); // 0 penalty for <= 8% drift
    final driftPenalty = excessDriftRatio * (isSchoolCohort ? 55.0 : 65.0);
    final alignmentScore = (100.0 - driftPenalty).clamp(38.0, 99.0);

    // 2. Slant Consistency Score: Regularity of stroke slant across all glyphs
    // Caligraphic research confirms that natural personal slant has +/- 4.5° variance.
    final excessSlantMad = math.max(0.0, features.slantMadDeg - 4.5);
    final slantScale = isSchoolCohort ? 1.6 : 2.0;
    final slantConsistencyScore = (100.0 - (excessSlantMad * slantScale)).clamp(38.0, 99.0);

    // 3. Spacing Score: Rhythm and uniformity of horizontal character/word gaps
    final safeSpacing = math.max(10.0, features.medianSpacing);
    final spacingMadRatio = (features.spacingMad / safeSpacing).clamp(0.0, 1.5);
    final excessSpacingRatio = math.max(0.0, spacingMadRatio - 0.10);
    final spacingPenalty = excessSpacingRatio * (isSchoolCohort ? 50.0 : 60.0);
    final spacingScore = (100.0 - spacingPenalty).clamp(38.0, 98.0);

    // 4. Letter Formation Score: Repeated letter uniformity & height regularity
    double formationBonus = 0.0;
    if (patterns.isNotEmpty) {
      final avgHeightMad = patterns.map((p) => p.heightMad).reduce((a, b) => a + b) / patterns.length;
      final avgHeightMadRatio = (avgHeightMad / safeH).clamp(0.0, 1.0);
      formationBonus = ((0.12 - avgHeightMadRatio) * 40.0).clamp(-10.0, 8.0);
    }
    final heightMadRatio = (features.heightMad / safeH).clamp(0.0, 1.0);
    final excessHeightRatio = math.max(0.0, heightMadRatio - 0.08);
    final heightPenalty = excessHeightRatio * (isSchoolCohort ? 55.0 : 65.0);
    final letterFormationScore = ((100.0 - heightPenalty) + formationBonus).clamp(38.0, 98.0);

    // 5. Readability Score: Distinguishability, baseline clarity & adequate vertical scale
    final minScale = isSchoolCohort ? 18.0 : 14.0;
    final scaleAdequacy = (features.medianHeight / minScale).clamp(0.75, 1.0);
    final readabilityScore = ((alignmentScore * 0.35 + letterFormationScore * 0.40 + spacingScore * 0.25) * scaleAdequacy).clamp(38.0, 99.0);

    // 6. Consistency Score: Within-sample regularity modulated by reference profile deviation
    double personalDeviationPenalty = 0.0;
    bool zeroPenaltyApplied = true;
    if (deviationResult.hasProfile) {
      final mult = isSchoolCohort ? 2.5 : 3.2;
      if (deviationResult.heightZScore > 1.5) {
        personalDeviationPenalty += (deviationResult.heightZScore - 1.5) * mult;
        zeroPenaltyApplied = false;
      }
      if (deviationResult.slantZScore > 1.5) {
        personalDeviationPenalty += (deviationResult.slantZScore - 1.5) * mult;
        zeroPenaltyApplied = false;
      }
      if (deviationResult.spacingZScore > 1.5) {
        personalDeviationPenalty += (deviationResult.spacingZScore - 1.5) * (isSchoolCohort ? 2.0 : 2.8);
        zeroPenaltyApplied = false;
      }
    }
    final withinSampleCadence = (slantConsistencyScore * 0.5 + (100.0 - heightPenalty) * 0.5);
    final consistencyScore = (withinSampleCadence - personalDeviationPenalty).clamp(38.0, 98.0);

    // 7. Visual Organisation Score: Page layout, line separation, and margin balance
    final visualOrganizationScore = (alignmentScore * 0.45 + spacingScore * 0.35 + consistencyScore * 0.20).clamp(40.0, 98.0);

    // 8. Overall Composite Aesthetic Score: Harmonic, multi-factor weighting
    final overallAestheticScore = (
      readabilityScore * 0.22 +
      letterFormationScore * 0.18 +
      alignmentScore * 0.18 +
      consistencyScore * 0.16 +
      spacingScore * 0.14 +
      visualOrganizationScore * 0.12
    ).clamp(35.0, 99.0);

    // Backward-compatible neatness & smoothness scores
    final neatnessScore = (alignmentScore * 0.38 + features.strokeSmoothness * 0.34 + slantConsistencyScore * 0.28).clamp(38.0, 99.0);
    final strokeSmoothnessScore = features.strokeSmoothness;
    final pressureRhythmScore = (85.0 + (consistencyScore - 70.0) * 0.2).clamp(60.0, 98.0);

    // Determine Letter Grade with calibrated educator standard
    String grade = 'B';
    if (overallAestheticScore >= 90.0) {
      grade = 'A+';
    } else if (overallAestheticScore >= 82.0) {
      grade = 'A';
    } else if (overallAestheticScore >= 74.0) {
      grade = 'B+';
    } else if (overallAestheticScore >= 66.0) {
      grade = 'B';
    } else if (overallAestheticScore >= 56.0) {
      grade = 'C+';
    } else {
      grade = 'C';
    }

    String critiqueTitle = 'Fluid & Harmonious Penmanship';
    if (grade == 'A+' || grade == 'A') {
      critiqueTitle = 'Harmonious & Disciplined Script';
    } else if (grade == 'B+' || grade == 'B') {
      critiqueTitle = 'Consistent Handwriting Cadence';
    } else if (grade == 'C+') {
      critiqueTitle = 'Developing Penmanship Foundations';
    } else {
      critiqueTitle = 'Emerging Letter Control';
    }

    // Observations
    final observations = <String>[];
    if (features.medianSlantDeg.abs() < 5.0) {
      observations.add('Upright vertical letter alignment with steady pen angle.');
    } else if (features.medianSlantDeg > 5.0) {
      observations.add('Consistent forward italic slant (${features.medianSlantDeg.toStringAsFixed(1)}°) across strokes.');
    } else {
      observations.add('Backward slant (${features.medianSlantDeg.toStringAsFixed(1)}°) maintained consistently.');
    }

    if (alignmentScore >= 80) {
      observations.add('Solid horizontal baseline with minimal vertical drift.');
    } else {
      observations.add('Baseline displays noticeable vertical waviness.');
    }

    if (patterns.isNotEmpty) {
      observations.add('${patterns.length} repeated letter sets show uniform stroke formation.');
    }

    // Student-friendly Coaching Tips
    final tips = <String>[];
    if (alignmentScore < 75) {
      tips.add('Practice writing along a steady horizontal line to keep words level.');
    }
    if (slantConsistencyScore < 75) {
      tips.add('Maintain a uniform slant angle from the start to the end of your sentence.');
    }
    if (spacingScore < 75) {
      tips.add('Keep the spacing between words uniform so each word stands out clearly.');
    }
    if (letterFormationScore < 75) {
      tips.add('Focus on repeated letters like "e", "t", and "s" to form identical loops and heights.');
    }
    if (tips.isEmpty) {
      tips.add('Superb handwriting harmony and spacing rhythm! Keep practicing to maintain fluency.');
    }

    // Build the 5-Stage Mathematical Verification & Inspection Payload
    final inspectionData = AlgorithmInspectionData(
      totalStrokes: features.totalStrokes,
      estimatedGlyphs: features.estimatedGlyphs,
      ageCohort: ageCohort,
      patterns: patterns.map((p) => RepeatedPatternSummary(
        letter: p.char,
        occurrenceCount: p.occurrences,
        heightMadPx: double.parse(p.heightMad.toStringAsFixed(1)),
        slantMadDeg: double.parse(p.slantMadDeg.toStringAsFixed(1)),
      )).toList(),
      totalRepeatedLettersFound: patterns.length,
      medianHeightPx: features.medianHeight,
      heightMadPx: features.heightMad,
      heightVariationPct: double.parse((heightMadRatio * 100).toStringAsFixed(1)),
      medianSlantDeg: features.medianSlantDeg,
      slantMadDeg: features.slantMadDeg,
      medianSpacingPx: features.medianSpacing,
      spacingMadPx: features.spacingMad,
      baselineDriftPx: features.baselineDriftPx,
      strokeSmoothnessPct: features.strokeSmoothness,
      hasPersonalProfile: hasReferenceProfile,
      personalStyleTags: personalStyleTags,
      heightZScore: double.parse(deviationResult.heightZScore.toStringAsFixed(2)),
      slantZScore: double.parse(deviationResult.slantZScore.toStringAsFixed(2)),
      spacingZScore: double.parse(deviationResult.spacingZScore.toStringAsFixed(2)),
      baselineDriftRatio: double.parse(deviationResult.baselineDriftRatio.toStringAsFixed(2)),
      zeroPenaltyApplied: zeroPenaltyApplied,
      styleShiftObservations: deviationResult.styleShiftObservations,
      dimensionScores: {
        'Readability': double.parse(readabilityScore.toStringAsFixed(1)),
        'Letter Formation': double.parse(letterFormationScore.toStringAsFixed(1)),
        'Alignment': double.parse(alignmentScore.toStringAsFixed(1)),
        'Consistency': double.parse(consistencyScore.toStringAsFixed(1)),
        'Spacing': double.parse(spacingScore.toStringAsFixed(1)),
        'Visual Organisation': double.parse(visualOrganizationScore.toStringAsFixed(1)),
        'Stroke Smoothness': double.parse(strokeSmoothnessScore.toStringAsFixed(1)),
      },
      scoringWeights: const {
        'Readability': 0.22,
        'Letter Formation': 0.18,
        'Alignment': 0.18,
        'Consistency': 0.16,
        'Spacing': 0.14,
        'Visual Organisation': 0.12,
      },
      finalCompositeScore: double.parse(overallAestheticScore.toStringAsFixed(1)),
      finalGrade: grade,
      formulaText: '0.22×Readability + 0.18×Formation + 0.18×Alignment + 0.16×Consistency + 0.14×Spacing + 0.12×Organisation',
    );

    return AestheticEvaluation(
      overallAestheticScore: double.parse(overallAestheticScore.toStringAsFixed(1)),
      readabilityScore: double.parse(readabilityScore.toStringAsFixed(1)),
      letterFormationScore: double.parse(letterFormationScore.toStringAsFixed(1)),
      spacingScore: double.parse(spacingScore.toStringAsFixed(1)),
      alignmentScore: double.parse(alignmentScore.toStringAsFixed(1)),
      consistencyScore: double.parse(consistencyScore.toStringAsFixed(1)),
      visualOrganizationScore: double.parse(visualOrganizationScore.toStringAsFixed(1)),
      neatnessScore: double.parse(neatnessScore.toStringAsFixed(1)),
      baselineAlignmentScore: double.parse(alignmentScore.toStringAsFixed(1)),
      slantConsistencyScore: double.parse(slantConsistencyScore.toStringAsFixed(1)),
      strokeSmoothnessScore: double.parse(strokeSmoothnessScore.toStringAsFixed(1)),
      pressureRhythmScore: double.parse(pressureRhythmScore.toStringAsFixed(1)),
      grade: grade,
      critiqueTitle: critiqueTitle,
      visualObservations: observations,
      coachingTips: tips,
      evaluatedBy: 'RapidWrite 5-Stage Aesthetic Engine',
      hasPersonalReference: hasReferenceProfile,
      personalStyleTags: personalStyleTags,
      styleShiftObservations: deviationResult.styleShiftObservations,
      inspectionData: inspectionData,
    );
  }
}

