import 'handwriting_feature_model.dart';
import 'stage3_reference_profile.dart';

/// Result of Stage 4 deviation comparison against personal reference profile.
class DeviationAnalysisResult {
  final bool hasProfile;
  final double heightZScore;
  final double slantZScore;
  final double spacingZScore;
  final double baselineDriftRatio;
  final List<String> styleShiftObservations;

  const DeviationAnalysisResult({
    required this.hasProfile,
    required this.heightZScore,
    required this.slantZScore,
    required this.spacingZScore,
    required this.baselineDriftRatio,
    required this.styleShiftObservations,
  });

  Map<String, dynamic> toJson() => {
        'hasProfile': hasProfile,
        'heightZScore': heightZScore,
        'slantZScore': slantZScore,
        'spacingZScore': spacingZScore,
        'baselineDriftRatio': baselineDriftRatio,
        'styleShiftObservations': styleShiftObservations,
      };
}

/// STAGE 4 – Measure Deviation from the Personal Reference Profile
/// Uses robust standard deviation proxy (1.4826 * MAD) to identify
/// meaningful deviations without penalizing normal natural variation.
class Stage4DeviationAnalyzer {
  static DeviationAnalysisResult analyze({
    required ExtractedGeometricFeatures currentFeatures,
    PersonalHandwritingProfile? referenceProfile,
  }) {
    if (referenceProfile == null) {
      return const DeviationAnalysisResult(
        hasProfile: false,
        heightZScore: 0.0,
        slantZScore: 0.0,
        spacingZScore: 0.0,
        baselineDriftRatio: 1.0,
        styleShiftObservations: [],
      );
    }

    // Normalized Z = |current - refMedian| / (1.4826 * refMAD)
    final heightZ = (currentFeatures.medianHeight - referenceProfile.medianLetterHeight).abs() /
        (1.4826 * referenceProfile.letterHeightMad);

    final slantZ = (currentFeatures.medianSlantDeg - referenceProfile.medianSlantDeg).abs() /
        (1.4826 * referenceProfile.slantMadDeg);

    final spacingZ = (currentFeatures.medianSpacing - referenceProfile.medianSpacing).abs() /
        (1.4826 * referenceProfile.spacingMad);

    final driftRatio = currentFeatures.baselineDriftPx / referenceProfile.baselineDriftTolerance;

    final observations = <String>[];
    if (heightZ > 2.0) {
      if (currentFeatures.medianHeight > referenceProfile.medianLetterHeight) {
        observations.add('Letter scale is noticeably larger than your calibration baseline.');
      } else {
        observations.add('Letter scale is written noticeably smaller than your baseline.');
      }
    }

    if (slantZ > 2.2) {
      observations.add('Handwriting slant shows a notable variation from your natural angle.');
    }

    if (spacingZ > 2.0) {
      observations.add('Word/character spacing shifted outside your standard cadence.');
    }

    if (driftRatio > 1.8) {
      observations.add('Baseline drift is higher than your usual steady alignment.');
    }

    return DeviationAnalysisResult(
      hasProfile: true,
      heightZScore: double.parse(heightZ.toStringAsFixed(2)),
      slantZScore: double.parse(slantZ.toStringAsFixed(2)),
      spacingZScore: double.parse(spacingZ.toStringAsFixed(2)),
      baselineDriftRatio: double.parse(driftRatio.toStringAsFixed(2)),
      styleShiftObservations: observations,
    );
  }
}

