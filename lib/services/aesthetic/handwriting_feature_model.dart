/// Represents localized geometric features of an individual letter or stroke cluster.
class LetterOccurrence {
  final String char;
  final int strokeIndex;
  final double x;
  final double y;
  final double width;
  final double height;
  final double aspectRatio;
  final double slantAngleDeg;
  final double strokeLength;
  final double confidence;

  const LetterOccurrence({
    required this.char,
    required this.strokeIndex,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.aspectRatio,
    required this.slantAngleDeg,
    required this.strokeLength,
    required this.confidence,
  });

  Map<String, dynamic> toJson() => {
        'char': char,
        'strokeIndex': strokeIndex,
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'aspectRatio': aspectRatio,
        'slantAngleDeg': slantAngleDeg,
        'strokeLength': strokeLength,
        'confidence': confidence,
      };

  factory LetterOccurrence.fromJson(Map<String, dynamic> json) => LetterOccurrence(
        char: json['char'] as String? ?? '?',
        strokeIndex: json['strokeIndex'] as int? ?? 0,
        x: (json['x'] as num?)?.toDouble() ?? 0.0,
        y: (json['y'] as num?)?.toDouble() ?? 0.0,
        width: (json['width'] as num?)?.toDouble() ?? 0.0,
        height: (json['height'] as num?)?.toDouble() ?? 0.0,
        aspectRatio: (json['aspectRatio'] as num?)?.toDouble() ?? 1.0,
        slantAngleDeg: (json['slantAngleDeg'] as num?)?.toDouble() ?? 0.0,
        strokeLength: (json['strokeLength'] as num?)?.toDouble() ?? 0.0,
        confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      );
}

/// Repeated stroke pattern analysis for high-frequency characters.
class RepeatedLetterPattern {
  final String char;
  final int occurrences;
  final double medianHeight;
  final double heightMad;
  final double medianSlantDeg;
  final double slantMadDeg;

  const RepeatedLetterPattern({
    required this.char,
    required this.occurrences,
    required this.medianHeight,
    required this.heightMad,
    required this.medianSlantDeg,
    required this.slantMadDeg,
  });

  Map<String, dynamic> toJson() => {
        'char': char,
        'occurrences': occurrences,
        'medianHeight': medianHeight,
        'heightMad': heightMad,
        'medianSlantDeg': medianSlantDeg,
        'slantMadDeg': slantMadDeg,
      };
}

/// Extracted geometric features separating local and global characteristics.
class ExtractedGeometricFeatures {
  // Local glyph metrics
  final double medianHeight;
  final double heightMad;
  final double medianWidth;
  final double widthMad;
  final double medianSlantDeg;
  final double slantMadDeg;
  final double medianAspectRatio;

  // Global composition metrics
  final double medianSpacing;
  final double spacingMad;
  final double baselineDriftPx;
  final double strokeSmoothness; // 0..100 curvature regularity
  final int totalStrokes;
  final int estimatedGlyphs;

  const ExtractedGeometricFeatures({
    required this.medianHeight,
    required this.heightMad,
    required this.medianWidth,
    required this.widthMad,
    required this.medianSlantDeg,
    required this.slantMadDeg,
    required this.medianAspectRatio,
    required this.medianSpacing,
    required this.spacingMad,
    required this.baselineDriftPx,
    required this.strokeSmoothness,
    required this.totalStrokes,
    required this.estimatedGlyphs,
  });

  Map<String, dynamic> toJson() => {
        'medianHeight': medianHeight,
        'heightMad': heightMad,
        'medianWidth': medianWidth,
        'widthMad': widthMad,
        'medianSlantDeg': medianSlantDeg,
        'slantMadDeg': slantMadDeg,
        'medianAspectRatio': medianAspectRatio,
        'medianSpacing': medianSpacing,
        'spacingMad': spacingMad,
        'baselineDriftPx': baselineDriftPx,
        'strokeSmoothness': strokeSmoothness,
        'totalStrokes': totalStrokes,
        'estimatedGlyphs': estimatedGlyphs,
      };
}

