import 'dart:ui';

/// Trajectory classification of handwriting baseline.
enum BaselineTrajectory {
  level,
  ascending,
  descending,
}

/// Detailed segmentation and geometric feature measurement of an individual letter glyph.
class LetterSegmentation {
  final String char;
  final Rect boundingBox;
  final double height;
  final double width;
  final double aspectRatio;
  final double slantAngleDeg;
  final double baselineY;
  final double baselineDeviationPx;
  final bool isAscender;
  final bool isDescender;
  final bool isBodyLetter;
  final bool isHeightOutlier;
  final bool isSlantOutlier;
  final bool isBaselineOutlier;
  final double confidence; // 0.0 - 1.0
  final int wordIndex;
  final int letterIndexInWord;
  final List<int> strokeIndices;

  const LetterSegmentation({
    required this.char,
    required this.boundingBox,
    required this.height,
    required this.width,
    required this.aspectRatio,
    required this.slantAngleDeg,
    required this.baselineY,
    required this.baselineDeviationPx,
    required this.isAscender,
    required this.isDescender,
    required this.isBodyLetter,
    required this.isHeightOutlier,
    required this.isSlantOutlier,
    required this.isBaselineOutlier,
    required this.confidence,
    required this.wordIndex,
    required this.letterIndexInWord,
    this.strokeIndices = const [],
  });

  bool get hasAnyOutlier => isHeightOutlier || isSlantOutlier || isBaselineOutlier;

  Map<String, dynamic> toJson() => {
        'char': char,
        'rect': {
          'left': boundingBox.left,
          'top': boundingBox.top,
          'right': boundingBox.right,
          'bottom': boundingBox.bottom,
        },
        'height': height,
        'width': width,
        'aspectRatio': aspectRatio,
        'slantAngleDeg': slantAngleDeg,
        'baselineY': baselineY,
        'baselineDeviationPx': baselineDeviationPx,
        'isAscender': isAscender,
        'isDescender': isDescender,
        'isBodyLetter': isBodyLetter,
        'isHeightOutlier': isHeightOutlier,
        'isSlantOutlier': isSlantOutlier,
        'isBaselineOutlier': isBaselineOutlier,
        'confidence': confidence,
        'wordIndex': wordIndex,
        'letterIndexInWord': letterIndexInWord,
      };

  factory LetterSegmentation.fromJson(Map<String, dynamic> json) {
    final r = json['rect'] as Map<String, dynamic>? ?? {};
    return LetterSegmentation(
      char: json['char'] as String? ?? '?',
      boundingBox: Rect.fromLTRB(
        (r['left'] as num?)?.toDouble() ?? 0.0,
        (r['top'] as num?)?.toDouble() ?? 0.0,
        (r['right'] as num?)?.toDouble() ?? 10.0,
        (r['bottom'] as num?)?.toDouble() ?? 10.0,
      ),
      height: (json['height'] as num?)?.toDouble() ?? 0.0,
      width: (json['width'] as num?)?.toDouble() ?? 0.0,
      aspectRatio: (json['aspectRatio'] as num?)?.toDouble() ?? 1.0,
      slantAngleDeg: (json['slantAngleDeg'] as num?)?.toDouble() ?? 0.0,
      baselineY: (json['baselineY'] as num?)?.toDouble() ?? 0.0,
      baselineDeviationPx: (json['baselineDeviationPx'] as num?)?.toDouble() ?? 0.0,
      isAscender: json['isAscender'] as bool? ?? false,
      isDescender: json['isDescender'] as bool? ?? false,
      isBodyLetter: json['isBodyLetter'] as bool? ?? true,
      isHeightOutlier: json['isHeightOutlier'] as bool? ?? false,
      isSlantOutlier: json['isSlantOutlier'] as bool? ?? false,
      isBaselineOutlier: json['isBaselineOutlier'] as bool? ?? false,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.8,
      wordIndex: json['wordIndex'] as int? ?? 0,
      letterIndexInWord: json['letterIndexInWord'] as int? ?? 0,
    );
  }
}

/// Detailed segmentation of an individual word in the user's sentence.
class WordSegmentation {
  final int index;
  final String text;
  final Rect boundingBox;
  final List<LetterSegmentation> letters;
  final double baselineY;
  final double confidence;

  const WordSegmentation({
    required this.index,
    required this.text,
    required this.boundingBox,
    required this.letters,
    required this.baselineY,
    required this.confidence,
  });

  Map<String, dynamic> toJson() => {
        'index': index,
        'text': text,
        'rect': {
          'left': boundingBox.left,
          'top': boundingBox.top,
          'right': boundingBox.right,
          'bottom': boundingBox.bottom,
        },
        'letters': letters.map((l) => l.toJson()).toList(),
        'baselineY': baselineY,
        'confidence': confidence,
      };

  factory WordSegmentation.fromJson(Map<String, dynamic> json) {
    final r = json['rect'] as Map<String, dynamic>? ?? {};
    return WordSegmentation(
      index: json['index'] as int? ?? 0,
      text: json['text'] as String? ?? '',
      boundingBox: Rect.fromLTRB(
        (r['left'] as num?)?.toDouble() ?? 0.0,
        (r['top'] as num?)?.toDouble() ?? 0.0,
        (r['right'] as num?)?.toDouble() ?? 10.0,
        (r['bottom'] as num?)?.toDouble() ?? 10.0,
      ),
      letters: (json['letters'] as List<dynamic>?)
              ?.map((e) => LetterSegmentation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      baselineY: (json['baselineY'] as num?)?.toDouble() ?? 0.0,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.8,
    );
  }
}

/// Measured gap between adjacent letters or adjacent words.
class SpacingMeasurement {
  final bool isWordGap;
  final String leftLabel;
  final String rightLabel;
  final Offset startPoint;
  final Offset endPoint;
  final double gapPx;
  final bool isCramped;
  final bool isExcessive;
  final double confidence;

  const SpacingMeasurement({
    required this.isWordGap,
    required this.leftLabel,
    required this.rightLabel,
    required this.startPoint,
    required this.endPoint,
    required this.gapPx,
    required this.isCramped,
    required this.isExcessive,
    required this.confidence,
  });

  bool get isOutlier => isCramped || isExcessive;

  Map<String, dynamic> toJson() => {
        'isWordGap': isWordGap,
        'leftLabel': leftLabel,
        'rightLabel': rightLabel,
        'startX': startPoint.dx,
        'startY': startPoint.dy,
        'endX': endPoint.dx,
        'endY': endPoint.dy,
        'gapPx': gapPx,
        'isCramped': isCramped,
        'isExcessive': isExcessive,
        'confidence': confidence,
      };

  factory SpacingMeasurement.fromJson(Map<String, dynamic> json) => SpacingMeasurement(
        isWordGap: json['isWordGap'] as bool? ?? false,
        leftLabel: json['leftLabel'] as String? ?? '',
        rightLabel: json['rightLabel'] as String? ?? '',
        startPoint: Offset(
          (json['startX'] as num?)?.toDouble() ?? 0.0,
          (json['startY'] as num?)?.toDouble() ?? 0.0,
        ),
        endPoint: Offset(
          (json['endX'] as num?)?.toDouble() ?? 0.0,
          (json['endY'] as num?)?.toDouble() ?? 0.0,
        ),
        gapPx: (json['gapPx'] as num?)?.toDouble() ?? 0.0,
        isCramped: json['isCramped'] as bool? ?? false,
        isExcessive: json['isExcessive'] as bool? ?? false,
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0.8,
      );
}

/// Linear regression baseline and trajectory across the written sentence.
class BaselineMeasurement {
  final double slope;
  final double intercept;
  final double angleDeg;
  final BaselineTrajectory trajectory;
  final Offset lineStart;
  final Offset lineEnd;
  final double residualDriftMadPx;
  final bool isConsistent;
  final double confidence;

  const BaselineMeasurement({
    required this.slope,
    required this.intercept,
    required this.angleDeg,
    required this.trajectory,
    required this.lineStart,
    required this.lineEnd,
    required this.residualDriftMadPx,
    required this.isConsistent,
    required this.confidence,
  });

  double expectedYAt(double x) => slope * x + intercept;

  String get trajectoryName {
    switch (trajectory) {
      case BaselineTrajectory.ascending:
        return 'Ascending (+${angleDeg.abs().toStringAsFixed(1)}°)';
      case BaselineTrajectory.descending:
        return 'Descending (-${angleDeg.abs().toStringAsFixed(1)}°)';
      case BaselineTrajectory.level:
        return 'Level (${angleDeg.abs().toStringAsFixed(1)}°)';
    }
  }

  Map<String, dynamic> toJson() => {
        'slope': slope,
        'intercept': intercept,
        'angleDeg': angleDeg,
        'trajectory': trajectory.name,
        'startX': lineStart.dx,
        'startY': lineStart.dy,
        'endX': lineEnd.dx,
        'endY': lineEnd.dy,
        'residualDriftMadPx': residualDriftMadPx,
        'isConsistent': isConsistent,
        'confidence': confidence,
      };

  factory BaselineMeasurement.fromJson(Map<String, dynamic> json) => BaselineMeasurement(
        slope: (json['slope'] as num?)?.toDouble() ?? 0.0,
        intercept: (json['intercept'] as num?)?.toDouble() ?? 0.0,
        angleDeg: (json['angleDeg'] as num?)?.toDouble() ?? 0.0,
        trajectory: BaselineTrajectory.values.firstWhere(
          (t) => t.name == json['trajectory'],
          orElse: () => BaselineTrajectory.level,
        ),
        lineStart: Offset(
          (json['startX'] as num?)?.toDouble() ?? 0.0,
          (json['startY'] as num?)?.toDouble() ?? 0.0,
        ),
        lineEnd: Offset(
          (json['endX'] as num?)?.toDouble() ?? 100.0,
          (json['endY'] as num?)?.toDouble() ?? 0.0,
        ),
        residualDriftMadPx: (json['residualDriftMadPx'] as num?)?.toDouble() ?? 0.0,
        isConsistent: json['isConsistent'] as bool? ?? true,
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0.8,
      );
}

/// Explainable breakdown for one of the five required handwriting assessment categories.
class CategoryBreakdown {
  final String categoryName;
  final double score; // 0 - 100
  final String whatWasMeasured;
  final String whatWasDetected;
  final List<String> affectedRegions;
  final String suggestion;
  final double confidence; // 0.0 - 1.0
  final bool isReliable;
  final Map<String, dynamic> metrics;

  const CategoryBreakdown({
    required this.categoryName,
    required this.score,
    required this.whatWasMeasured,
    required this.whatWasDetected,
    required this.affectedRegions,
    required this.suggestion,
    required this.confidence,
    this.isReliable = true,
    this.metrics = const {},
  });

  Map<String, dynamic> toJson() => {
        'categoryName': categoryName,
        'score': score,
        'whatWasMeasured': whatWasMeasured,
        'whatWasDetected': whatWasDetected,
        'affectedRegions': affectedRegions,
        'suggestion': suggestion,
        'confidence': confidence,
        'isReliable': isReliable,
        'metrics': metrics,
      };

  factory CategoryBreakdown.fromJson(Map<String, dynamic> json) => CategoryBreakdown(
        categoryName: json['categoryName'] as String? ?? '',
        score: (json['score'] as num?)?.toDouble() ?? 0.0,
        whatWasMeasured: json['whatWasMeasured'] as String? ?? '',
        whatWasDetected: json['whatWasDetected'] as String? ?? '',
        affectedRegions: (json['affectedRegions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        suggestion: json['suggestion'] as String? ?? '',
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0.8,
        isReliable: json['isReliable'] as bool? ?? true,
        metrics: json['metrics'] as Map<String, dynamic>? ?? {},
      );
}

/// Complete Aesthetic Breakdown payload containing visual annotations,
/// segmented sentence structure, measurements, and explainable category scores.
class AestheticBreakdown {
  final String targetSentence;
  final List<WordSegmentation> words;
  final List<LetterSegmentation> letters;
  final List<SpacingMeasurement> spacings;
  final BaselineMeasurement baseline;

  // The 5 mandatory breakdown categories
  final CategoryBreakdown letterSize;
  final CategoryBreakdown slant;
  final CategoryBreakdown spacing;
  final CategoryBreakdown baselineCategory;
  final CategoryBreakdown consistency;

  // Synthesis & Comparison Context
  final double overallAestheticScore;
  final String grade;
  final bool hasPersonalProfile;
  final List<String> personalStyleTags;
  final bool canMeasureReliably;

  const AestheticBreakdown({
    required this.targetSentence,
    required this.words,
    required this.letters,
    required this.spacings,
    required this.baseline,
    required this.letterSize,
    required this.slant,
    required this.spacing,
    required this.baselineCategory,
    required this.consistency,
    required this.overallAestheticScore,
    required this.grade,
    required this.hasPersonalProfile,
    this.personalStyleTags = const [],
    this.canMeasureReliably = true,
  });

  List<SpacingMeasurement> get letterSpacings => spacings.where((s) => !s.isWordGap).toList();
  List<SpacingMeasurement> get wordSpacings => spacings.where((s) => s.isWordGap).toList();

  Map<String, dynamic> toJson() => {
        'targetSentence': targetSentence,
        'words': words.map((w) => w.toJson()).toList(),
        'letters': letters.map((l) => l.toJson()).toList(),
        'spacings': spacings.map((s) => s.toJson()).toList(),
        'baseline': baseline.toJson(),
        'letterSize': letterSize.toJson(),
        'slant': slant.toJson(),
        'spacing': spacing.toJson(),
        'baselineCategory': baselineCategory.toJson(),
        'consistency': consistency.toJson(),
        'overallAestheticScore': overallAestheticScore,
        'grade': grade,
        'hasPersonalProfile': hasPersonalProfile,
        'personalStyleTags': personalStyleTags,
        'canMeasureReliably': canMeasureReliably,
      };

  factory AestheticBreakdown.fromJson(Map<String, dynamic> json) => AestheticBreakdown(
        targetSentence: json['targetSentence'] as String? ?? '',
        words: (json['words'] as List<dynamic>?)
                ?.map((e) => WordSegmentation.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        letters: (json['letters'] as List<dynamic>?)
                ?.map((e) => LetterSegmentation.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        spacings: (json['spacings'] as List<dynamic>?)
                ?.map((e) => SpacingMeasurement.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        baseline: BaselineMeasurement.fromJson(json['baseline'] as Map<String, dynamic>? ?? {}),
        letterSize: CategoryBreakdown.fromJson(json['letterSize'] as Map<String, dynamic>? ?? {}),
        slant: CategoryBreakdown.fromJson(json['slant'] as Map<String, dynamic>? ?? {}),
        spacing: CategoryBreakdown.fromJson(json['spacing'] as Map<String, dynamic>? ?? {}),
        baselineCategory: CategoryBreakdown.fromJson(json['baselineCategory'] as Map<String, dynamic>? ?? {}),
        consistency: CategoryBreakdown.fromJson(json['consistency'] as Map<String, dynamic>? ?? {}),
        overallAestheticScore: (json['overallAestheticScore'] as num?)?.toDouble() ?? 0.0,
        grade: json['grade'] as String? ?? 'B',
        hasPersonalProfile: json['hasPersonalProfile'] as bool? ?? false,
        personalStyleTags: (json['personalStyleTags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        canMeasureReliably: json['canMeasureReliably'] as bool? ?? true,
      );
}
