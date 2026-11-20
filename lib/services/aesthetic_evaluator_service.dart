import '../models/aesthetic_evaluation.dart';
import '../models/handwriting_stroke.dart';
import 'aesthetic/aesthetic_engine.dart';
import 'aesthetic/stage3_reference_profile.dart';

/// Computer vision & geometric heuristic evaluation service for handwriting aesthetics.
/// Powered by the RapidWrite Five-Stage Aesthetic Evaluation Algorithm:
/// - Stage 1: Repeated Letters & Common Stroke Patterns
/// - Stage 2: Geometric & Spatial Feature Extraction
/// - Stage 3: Personal Reference Profile Construction
/// - Stage 4: Deviation Analysis
/// - Stage 5: Consistency & Multi-dimensional Scoring (7 Dimensions)
class AestheticEvaluatorService {
  /// Evaluates handwriting strokes and returns a comprehensive [AestheticEvaluation].
  static AestheticEvaluation evaluate(
    List<HandwritingStroke> strokes, {
    String targetSentence = 'The quick brown fox jumps over the lazy dog',
    PersonalHandwritingProfile? referenceProfile,
    String ageCohort = 'Standard',
  }) {
    if (strokes.isEmpty) {
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
        visualObservations: const ['Canvas is currently empty.'],
        coachingTips: const ['Write the target sentence on the canvas to evaluate.'],
        evaluatedBy: 'RapidWrite 5-Stage Engine',
        hasPersonalReference: referenceProfile != null,
        personalStyleTags: referenceProfile?.personalStyleTags ?? const [],
        styleShiftObservations: const [],
      );
    }

    return AestheticEngine.evaluateSession(
      strokes: strokes,
      targetSentence: targetSentence,
      referenceProfile: referenceProfile,
      ageCohort: ageCohort,
    );
  }

  /// Calibrates and constructs a user's personal reference profile from a baseline sample.
  static PersonalHandwritingProfile calibrateBaseline({
    required List<HandwritingStroke> strokes,
    required String targetSentence,
    String userId = 'user_default',
  }) {
    return AestheticEngine.calibrateReferenceProfile(
      strokes: strokes,
      targetSentence: targetSentence,
      userId: userId,
    );
  }
}
