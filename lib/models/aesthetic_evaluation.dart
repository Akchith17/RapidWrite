/// Represents holistic visual and geometric aesthetic evaluation of handwriting.
class AestheticEvaluation {
  final double overallAestheticScore; // 0 - 100
  final double neatnessScore;         // 0 - 100
  final double baselineAlignmentScore;// 0 - 100
  final double slantConsistencyScore; // 0 - 100
  final double strokeSmoothnessScore; // 0 - 100
  final double pressureRhythmScore;   // 0 - 100
  final String grade;                 // 'A+', 'A', 'B+', 'B', 'C'
  final String critiqueTitle;
  final List<String> visualObservations;
  final List<String> coachingTips;
  final String evaluatedBy;

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
  });

  Map<String, dynamic> toJson() => {
        'overallAestheticScore': overallAestheticScore,
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
      };
}
