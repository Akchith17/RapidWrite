import '../../models/aesthetic_evaluation.dart';
import '../../models/handwriting_stroke.dart';
import 'aesthetic_breakdown_engine.dart';
import 'handwriting_feature_model.dart';
import 'stage1_pattern_detector.dart';
import 'stage2_feature_extractor.dart';
import 'stage3_reference_profile.dart';
import 'stage4_deviation_analyzer.dart';
import 'stage5_consistency_evaluator.dart';

/// Unified Five-Stage Handwriting Aesthetic Evaluation Engine.
/// Serves as the central evaluation coordinator for live stylus input and calibration.
class AestheticEngine {
  /// Evaluates a live handwriting session against the 5-stage algorithm
  /// and the user's stored personal reference profile (if present).
  static AestheticEvaluation evaluateSession({
    required List<HandwritingStroke> strokes,
    required String targetSentence,
    PersonalHandwritingProfile? referenceProfile,
    String ageCohort = 'Standard',
  }) {
    if (strokes.isEmpty) {
      final baseEval = Stage5ConsistencyEvaluator.evaluate(
        features: const ExtractedGeometricFeatures(
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
        ),
        patterns: const [],
        deviationResult: const DeviationAnalysisResult(
          hasProfile: false,
          heightZScore: 0,
          slantZScore: 0,
          spacingZScore: 0,
          baselineDriftRatio: 1,
          styleShiftObservations: [],
        ),
        ageCohort: ageCohort,
      );

      return AestheticEvaluation(
        overallAestheticScore: baseEval.overallAestheticScore,
        neatnessScore: baseEval.neatnessScore,
        baselineAlignmentScore: baseEval.baselineAlignmentScore,
        slantConsistencyScore: baseEval.slantConsistencyScore,
        strokeSmoothnessScore: baseEval.strokeSmoothnessScore,
        pressureRhythmScore: baseEval.pressureRhythmScore,
        grade: baseEval.grade,
        critiqueTitle: baseEval.critiqueTitle,
        visualObservations: baseEval.visualObservations,
        coachingTips: baseEval.coachingTips,
        evaluatedBy: baseEval.evaluatedBy,
        hasPersonalReference: baseEval.hasPersonalReference,
        personalStyleTags: baseEval.personalStyleTags,
        styleShiftObservations: baseEval.styleShiftObservations,
        inspectionData: baseEval.inspectionData,
        breakdown: AestheticBreakdownEngine.generateBreakdown(
          strokes: strokes,
          targetSentence: targetSentence,
          features: const ExtractedGeometricFeatures(
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
          ),
          evaluation: baseEval,
          referenceProfile: referenceProfile,
          ageCohort: ageCohort,
        ),
      );
    }

    // STAGE 1: Identify Repeated Letters & Stroke Patterns
    final stage1Result = Stage1PatternDetector.analyze(
      strokes: strokes,
      targetSentence: targetSentence,
    );
    final occurrences = stage1Result['occurrences'] as Map<String, List<LetterOccurrence>>?;
    final patterns = stage1Result['patterns'] as List<RepeatedLetterPattern>? ?? const [];

    // STAGE 2: Extract Geometric Features (Local & Global)
    final features = Stage2FeatureExtractor.extract(
      strokes: strokes,
      occurrences: occurrences,
    );

    // STAGE 4: Measure Deviations from Personal Reference Profile
    final deviations = Stage4DeviationAnalyzer.analyze(
      currentFeatures: features,
      referenceProfile: referenceProfile,
    );

    // STAGE 5: Evaluate Consistency & Multi-dimensional Scoring
    final eval = Stage5ConsistencyEvaluator.evaluate(
      features: features,
      patterns: patterns,
      deviationResult: deviations,
      hasReferenceProfile: referenceProfile != null,
      personalStyleTags: referenceProfile?.personalStyleTags ?? const [],
      ageCohort: ageCohort,
    );

    // Generate comprehensive visual aesthetic breakdown
    final breakdown = AestheticBreakdownEngine.generateBreakdown(
      strokes: strokes,
      targetSentence: targetSentence,
      features: features,
      evaluation: eval,
      referenceProfile: referenceProfile,
      ageCohort: ageCohort,
    );

    return AestheticEvaluation(
      overallAestheticScore: eval.overallAestheticScore,
      neatnessScore: eval.neatnessScore,
      baselineAlignmentScore: eval.baselineAlignmentScore,
      slantConsistencyScore: eval.slantConsistencyScore,
      strokeSmoothnessScore: eval.strokeSmoothnessScore,
      pressureRhythmScore: eval.pressureRhythmScore,
      grade: eval.grade,
      critiqueTitle: eval.critiqueTitle,
      visualObservations: eval.visualObservations,
      coachingTips: eval.coachingTips,
      evaluatedBy: eval.evaluatedBy,
      readabilityScore: eval.readabilityScore,
      letterFormationScore: eval.letterFormationScore,
      spacingScore: eval.spacingScore,
      alignmentScore: eval.alignmentScore,
      consistencyScore: eval.consistencyScore,
      visualOrganizationScore: eval.visualOrganizationScore,
      hasPersonalReference: eval.hasPersonalReference,
      personalStyleTags: eval.personalStyleTags,
      styleShiftObservations: eval.styleShiftObservations,
      inspectionData: eval.inspectionData,
      breakdown: breakdown,
    );
  }

  /// Calibrates and constructs a new personal handwriting reference profile (STAGE 3).
  static PersonalHandwritingProfile calibrateReferenceProfile({
    required List<HandwritingStroke> strokes,
    required String targetSentence,
    String userId = 'user_default',
  }) {
    final stage1Result = Stage1PatternDetector.analyze(
      strokes: strokes,
      targetSentence: targetSentence,
    );
    final occurrences = stage1Result['occurrences'] as Map<String, List<LetterOccurrence>>?;

    final features = Stage2FeatureExtractor.extract(
      strokes: strokes,
      occurrences: occurrences,
    );

    return Stage3ReferenceProfile.construct(
      features: features,
      userId: userId,
    );
  }
}

