import 'aesthetic_breakdown_model.dart';
import 'algorithm_inspection_data.dart';

/// Represents holistic visual, geometric, and reference-calibrated aesthetic evaluation of handwriting.
class AestheticEvaluation {
  // ── Core Composite & Grade ──────────────────────────────────────────────
  final double overallAestheticScore;   // 0 - 100 Harmonic composite
  final String grade;                   // 'A+', 'A', 'B+', 'B', 'C+', 'C'
  final String critiqueTitle;
  final String evaluatedBy;

  // ── 7 Mandatory Research Evaluation Dimensions ──────────────────────────
  final double readabilityScore;        // 0 - 100 Glyph clarity & scale
  final double letterFormationScore;   // 0 - 100 Stroke repetition regularity
  final double spacingScore;            // 0 - 100 Character & word gap rhythm
  final double alignmentScore;          // 0 - 100 Baseline straightness & drift control
  final double consistencyScore;        // 0 - 100 Intra-sample & reference consistency
  final double visualOrganizationScore; // 0 - 100 Spatial layout & line balance
  final double strokeSmoothnessScore;   // 0 - 100 Curvature fluency & low tremor

  // ── Legacy Compatibility Fields ──────────────────────────────────────────
  final double neatnessScore;           // Combined neatness proxy
  final double baselineAlignmentScore;  // Alias to alignmentScore
  final double slantConsistencyScore;   // Angular regularity
  final double pressureRhythmScore;     // Kinematic pen cadence

  // ── Qualitative Student Feedback ─────────────────────────────────────────
  final List<String> visualObservations;
  final List<String> coachingTips;

  // ── Personal Reference Profile Context ───────────────────────────────────
  final bool hasPersonalReference;
  final List<String> personalStyleTags;
  final List<String> styleShiftObservations;

  // ── 5-Stage Mathematical Verification & Inspection ─────────────────────────
  final AlgorithmInspectionData? inspectionData;

  // ── Detailed Visual Aesthetic Breakdown ───────────────────────────────────
  final AestheticBreakdown? breakdown;

  AestheticEvaluation({
    required this.overallAestheticScore,
    required this.neatnessScore,
    required this.baselineAlignmentScore,
    required this.slantConsistencyScore,
    required this.strokeSmoothnessScore,
    required this.pressureRhythmScore,
    required this.grade,
    required this.critiqueTitle,
    required this.visualObservations,
    required this.coachingTips,
    required this.evaluatedBy,
    double? readabilityScore,
    double? letterFormationScore,
    double? spacingScore,
    double? alignmentScore,
    double? consistencyScore,
    double? visualOrganizationScore,
    this.hasPersonalReference = false,
    this.personalStyleTags = const [],
    this.styleShiftObservations = const [],
    this.inspectionData,
    this.breakdown,
  })  : readabilityScore = readabilityScore ?? neatnessScore,
        letterFormationScore = letterFormationScore ?? slantConsistencyScore,
        spacingScore = spacingScore ?? 85.0,
        alignmentScore = alignmentScore ?? baselineAlignmentScore,
        consistencyScore = consistencyScore ?? slantConsistencyScore,
        visualOrganizationScore = visualOrganizationScore ?? neatnessScore;

  Map<String, dynamic> toJson() => {
        'overallAestheticScore': overallAestheticScore,
        'readabilityScore': readabilityScore,
        'letterFormationScore': letterFormationScore,
        'spacingScore': spacingScore,
        'alignmentScore': alignmentScore,
        'consistencyScore': consistencyScore,
        'visualOrganizationScore': visualOrganizationScore,
        'neatnessScore': neatnessScore,
        'baselineAlignmentScore': baselineAlignmentScore,
        'slantConsistencyScore': slantConsistencyScore,
        'strokeSmoothnessScore': strokeSmoothnessScore,
        'pressureRhythmScore': pressureRhythmScore,
        'grade': grade,
        'critiqueTitle': critiqueTitle,
        'visualObservations': visualObservations,
        'coachingTips': coachingTips,
        'evaluatedBy': evaluatedBy,
        'hasPersonalReference': hasPersonalReference,
        'personalStyleTags': personalStyleTags,
        'styleShiftObservations': styleShiftObservations,
        'inspectionData': inspectionData?.toJson(),
        'breakdown': breakdown?.toJson(),
      };

  factory AestheticEvaluation.fromJson(Map<String, dynamic> json) => AestheticEvaluation(
        overallAestheticScore: (json['overallAestheticScore'] as num?)?.toDouble() ?? 0.0,
        neatnessScore: (json['neatnessScore'] as num?)?.toDouble() ?? 0.0,
        baselineAlignmentScore: (json['baselineAlignmentScore'] as num?)?.toDouble() ?? 0.0,
        slantConsistencyScore: (json['slantConsistencyScore'] as num?)?.toDouble() ?? 0.0,
        strokeSmoothnessScore: (json['strokeSmoothnessScore'] as num?)?.toDouble() ?? 0.0,
        pressureRhythmScore: (json['pressureRhythmScore'] as num?)?.toDouble() ?? 0.0,
        readabilityScore: (json['readabilityScore'] as num?)?.toDouble() ?? 0.0,
        letterFormationScore: (json['letterFormationScore'] as num?)?.toDouble() ?? 0.0,
        spacingScore: (json['spacingScore'] as num?)?.toDouble() ?? 0.0,
        alignmentScore: (json['alignmentScore'] as num?)?.toDouble() ?? 0.0,
        consistencyScore: (json['consistencyScore'] as num?)?.toDouble() ?? 0.0,
        visualOrganizationScore: (json['visualOrganizationScore'] as num?)?.toDouble() ?? 0.0,
        grade: json['grade'] as String? ?? 'N/A',
        critiqueTitle: json['critiqueTitle'] as String? ?? 'Unassessed',
        visualObservations: (json['visualObservations'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        coachingTips: (json['coachingTips'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        evaluatedBy: json['evaluatedBy'] as String? ?? 'RapidWrite Engine',
        hasPersonalReference: json['hasPersonalReference'] as bool? ?? false,
        personalStyleTags: (json['personalStyleTags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        styleShiftObservations: (json['styleShiftObservations'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        inspectionData: json['inspectionData'] != null
            ? AlgorithmInspectionData.fromJson(json['inspectionData'] as Map<String, dynamic>)
            : null,
        breakdown: json['breakdown'] != null
            ? AestheticBreakdown.fromJson(json['breakdown'] as Map<String, dynamic>)
            : null,
      );
}
