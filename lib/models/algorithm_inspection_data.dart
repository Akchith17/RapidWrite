/// Inspection and verification payload capturing the complete mathematical
/// and geometric trace of the 5-Stage Adaptive Aesthetic Algorithm.
class AlgorithmInspectionData {
  // ── 0. Metadata ────────────────────────────────────────────────────────────
  final int totalStrokes;
  final int estimatedGlyphs;
  final String ageCohort;

  // ── Stage 1: Repeated Letters & Patterns ──────────────────────────────────
  final List<RepeatedPatternSummary> patterns;
  final int totalRepeatedLettersFound;

  // ── Stage 2: Geometric Feature Measurements ───────────────────────────────
  final double medianHeightPx;
  final double heightMadPx;
  final double heightVariationPct;
  final double medianSlantDeg;
  final double slantMadDeg;
  final double medianSpacingPx;
  final double spacingMadPx;
  final double baselineDriftPx;
  final double strokeSmoothnessPct;

  // ── Stage 3: Personal Reference Profile ───────────────────────────────────
  final bool hasPersonalProfile;
  final double? profileMedianHeight;
  final double? profileMedianSlant;
  final double? profileMedianSpacing;
  final List<String> personalStyleTags;

  // ── Stage 4: Deviation & Tolerance Analysis ───────────────────────────────
  final double heightZScore;
  final double slantZScore;
  final double spacingZScore;
  final double baselineDriftRatio;
  final bool zeroPenaltyApplied;
  final List<String> styleShiftObservations;

  // ── Stage 5: Multi-dimensional Consistency Scoring ────────────────────────
  final Map<String, double> dimensionScores;
  final Map<String, double> scoringWeights;
  final double finalCompositeScore;
  final String finalGrade;
  final String formulaText;

  const AlgorithmInspectionData({
    required this.totalStrokes,
    required this.estimatedGlyphs,
    required this.ageCohort,
    required this.patterns,
    required this.totalRepeatedLettersFound,
    required this.medianHeightPx,
    required this.heightMadPx,
    required this.heightVariationPct,
    required this.medianSlantDeg,
    required this.slantMadDeg,
    required this.medianSpacingPx,
    required this.spacingMadPx,
    required this.baselineDriftPx,
    required this.strokeSmoothnessPct,
    required this.hasPersonalProfile,
    this.profileMedianHeight,
    this.profileMedianSlant,
    this.profileMedianSpacing,
    this.personalStyleTags = const [],
    required this.heightZScore,
    required this.slantZScore,
    required this.spacingZScore,
    required this.baselineDriftRatio,
    required this.zeroPenaltyApplied,
    this.styleShiftObservations = const [],
    required this.dimensionScores,
    required this.scoringWeights,
    required this.finalCompositeScore,
    required this.finalGrade,
    required this.formulaText,
  });

  Map<String, dynamic> toJson() => {
        'totalStrokes': totalStrokes,
        'estimatedGlyphs': estimatedGlyphs,
        'ageCohort': ageCohort,
        'patterns': patterns.map((p) => p.toJson()).toList(),
        'totalRepeatedLettersFound': totalRepeatedLettersFound,
        'medianHeightPx': medianHeightPx,
        'heightMadPx': heightMadPx,
        'heightVariationPct': heightVariationPct,
        'medianSlantDeg': medianSlantDeg,
        'slantMadDeg': slantMadDeg,
        'medianSpacingPx': medianSpacingPx,
        'spacingMadPx': spacingMadPx,
        'baselineDriftPx': baselineDriftPx,
        'strokeSmoothnessPct': strokeSmoothnessPct,
        'hasPersonalProfile': hasPersonalProfile,
        'profileMedianHeight': profileMedianHeight,
        'profileMedianSlant': profileMedianSlant,
        'profileMedianSpacing': profileMedianSpacing,
        'personalStyleTags': personalStyleTags,
        'heightZScore': heightZScore,
        'slantZScore': slantZScore,
        'spacingZScore': spacingZScore,
        'baselineDriftRatio': baselineDriftRatio,
        'zeroPenaltyApplied': zeroPenaltyApplied,
        'styleShiftObservations': styleShiftObservations,
        'dimensionScores': dimensionScores,
        'scoringWeights': scoringWeights,
        'finalCompositeScore': finalCompositeScore,
        'finalGrade': finalGrade,
        'formulaText': formulaText,
      };

  factory AlgorithmInspectionData.fromJson(Map<String, dynamic> json) =>
      AlgorithmInspectionData(
        totalStrokes: json['totalStrokes'] as int? ?? 0,
        estimatedGlyphs: json['estimatedGlyphs'] as int? ?? 0,
        ageCohort: json['ageCohort'] as String? ?? 'Standard',
        patterns: (json['patterns'] as List<dynamic>?)
                ?.map((e) =>
                    RepeatedPatternSummary.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        totalRepeatedLettersFound:
            json['totalRepeatedLettersFound'] as int? ?? 0,
        medianHeightPx:
            (json['medianHeightPx'] as num?)?.toDouble() ?? 0.0,
        heightMadPx: (json['heightMadPx'] as num?)?.toDouble() ?? 0.0,
        heightVariationPct:
            (json['heightVariationPct'] as num?)?.toDouble() ?? 0.0,
        medianSlantDeg:
            (json['medianSlantDeg'] as num?)?.toDouble() ?? 0.0,
        slantMadDeg: (json['slantMadDeg'] as num?)?.toDouble() ?? 0.0,
        medianSpacingPx:
            (json['medianSpacingPx'] as num?)?.toDouble() ?? 0.0,
        spacingMadPx: (json['spacingMadPx'] as num?)?.toDouble() ?? 0.0,
        baselineDriftPx:
            (json['baselineDriftPx'] as num?)?.toDouble() ?? 0.0,
        strokeSmoothnessPct:
            (json['strokeSmoothnessPct'] as num?)?.toDouble() ?? 0.0,
        hasPersonalProfile: json['hasPersonalProfile'] as bool? ?? false,
        profileMedianHeight:
            (json['profileMedianHeight'] as num?)?.toDouble(),
        profileMedianSlant:
            (json['profileMedianSlant'] as num?)?.toDouble(),
        profileMedianSpacing:
            (json['profileMedianSpacing'] as num?)?.toDouble(),
        personalStyleTags: (json['personalStyleTags'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        heightZScore: (json['heightZScore'] as num?)?.toDouble() ?? 0.0,
        slantZScore: (json['slantZScore'] as num?)?.toDouble() ?? 0.0,
        spacingZScore: (json['spacingZScore'] as num?)?.toDouble() ?? 0.0,
        baselineDriftRatio:
            (json['baselineDriftRatio'] as num?)?.toDouble() ?? 0.0,
        zeroPenaltyApplied: json['zeroPenaltyApplied'] as bool? ?? true,
        styleShiftObservations: (json['styleShiftObservations']
                    as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        dimensionScores: (json['dimensionScores'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
            const {},
        scoringWeights: (json['scoringWeights'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
            const {},
        finalCompositeScore:
            (json['finalCompositeScore'] as num?)?.toDouble() ?? 0.0,
        finalGrade: json['finalGrade'] as String? ?? 'N/A',
        formulaText: json['formulaText'] as String? ?? '',
      );
}

class RepeatedPatternSummary {
  final String letter;
  final int occurrenceCount;
  final double heightMadPx;
  final double slantMadDeg;

  const RepeatedPatternSummary({
    required this.letter,
    required this.occurrenceCount,
    required this.heightMadPx,
    required this.slantMadDeg,
  });

  Map<String, dynamic> toJson() => {
        'letter': letter,
        'occurrenceCount': occurrenceCount,
        'heightMadPx': heightMadPx,
        'slantMadDeg': slantMadDeg,
      };

  factory RepeatedPatternSummary.fromJson(Map<String, dynamic> json) =>
      RepeatedPatternSummary(
        letter: json['letter'] as String? ?? '',
        occurrenceCount: json['occurrenceCount'] as int? ?? 0,
        heightMadPx: (json['heightMadPx'] as num?)?.toDouble() ?? 0.0,
        slantMadDeg: (json['slantMadDeg'] as num?)?.toDouble() ?? 0.0,
      );
}
