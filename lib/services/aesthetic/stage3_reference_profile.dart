import 'dart:math' as math;
import 'handwriting_feature_model.dart';

/// Personal Handwriting Reference Profile representation.
/// Encapsulates a user's natural authentic handwriting characteristics:
/// typical size, natural slant, spacing, baseline drift, and style variance envelope.
class PersonalHandwritingProfile {
  final String userId;
  final DateTime createdAt;
  final int calibrationSessionCount;
  final double medianLetterHeight;
  final double letterHeightMad;
  final double medianSlantDeg;
  final double slantMadDeg;
  final double medianSpacing;
  final double spacingMad;
  final double baselineDriftTolerance;
  final double medianAspectRatio;
  final List<String> personalStyleTags;

  const PersonalHandwritingProfile({
    required this.userId,
    required this.createdAt,
    required this.calibrationSessionCount,
    required this.medianLetterHeight,
    required this.letterHeightMad,
    required this.medianSlantDeg,
    required this.slantMadDeg,
    required this.medianSpacing,
    required this.spacingMad,
    required this.baselineDriftTolerance,
    required this.medianAspectRatio,
    required this.personalStyleTags,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'createdAt': createdAt.toIso8601String(),
        'calibrationSessionCount': calibrationSessionCount,
        'medianLetterHeight': medianLetterHeight,
        'letterHeightMad': letterHeightMad,
        'medianSlantDeg': medianSlantDeg,
        'slantMadDeg': slantMadDeg,
        'medianSpacing': medianSpacing,
        'spacingMad': spacingMad,
        'baselineDriftTolerance': baselineDriftTolerance,
        'medianAspectRatio': medianAspectRatio,
        'personalStyleTags': personalStyleTags,
      };

  factory PersonalHandwritingProfile.fromJson(Map<String, dynamic> json) =>
      PersonalHandwritingProfile(
        userId: json['userId'] as String? ?? 'user_default',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        calibrationSessionCount: json['calibrationSessionCount'] as int? ?? 1,
        medianLetterHeight: (json['medianLetterHeight'] as num?)?.toDouble() ?? 35.0,
        letterHeightMad: (json['letterHeightMad'] as num?)?.toDouble() ?? 5.0,
        medianSlantDeg: (json['medianSlantDeg'] as num?)?.toDouble() ?? 0.0,
        slantMadDeg: (json['slantMadDeg'] as num?)?.toDouble() ?? 6.0,
        medianSpacing: (json['medianSpacing'] as num?)?.toDouble() ?? 12.0,
        spacingMad: (json['spacingMad'] as num?)?.toDouble() ?? 3.0,
        baselineDriftTolerance: (json['baselineDriftTolerance'] as num?)?.toDouble() ?? 10.0,
        medianAspectRatio: (json['medianAspectRatio'] as num?)?.toDouble() ?? 0.75,
        personalStyleTags: (json['personalStyleTags'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            ['Balanced Print'],
      );
}

/// STAGE 3 – Construct a Personal Handwriting Reference Profile
/// Builds a non-prescriptive, authentic baseline profile from a natural calibration sample.
class Stage3ReferenceProfile {
  static PersonalHandwritingProfile construct({
    required ExtractedGeometricFeatures features,
    String userId = 'user_default',
  }) {
    // Generate authentic style descriptive tags
    final tags = <String>[];
    if (features.medianSlantDeg > 12.0) {
      tags.add('Forward Slant (Cursive/Italic)');
    } else if (features.medianSlantDeg < -10.0) {
      tags.add('Reverse Slant');
    } else {
      tags.add('Upright Form');
    }

    if (features.medianAspectRatio > 0.85) {
      tags.add('Spacious & Open');
    } else if (features.medianAspectRatio < 0.65) {
      tags.add('Narrow & Compact');
    } else {
      tags.add('Standard Proportions');
    }

    if (features.baselineDriftPx < 7.0) {
      tags.add('Steady Baseline Control');
    } else {
      tags.add('Dynamic Freehand Baseline');
    }

    return PersonalHandwritingProfile(
      userId: userId,
      createdAt: DateTime.now(),
      calibrationSessionCount: 1,
      medianLetterHeight: features.medianHeight,
      letterHeightMad: math.max(1.5, features.heightMad),
      medianSlantDeg: features.medianSlantDeg,
      slantMadDeg: math.max(2.0, features.slantMadDeg),
      medianSpacing: features.medianSpacing,
      spacingMad: math.max(1.0, features.spacingMad),
      baselineDriftTolerance: math.max(6.0, features.baselineDriftPx * 1.6),
      medianAspectRatio: features.medianAspectRatio,
      personalStyleTags: tags,
    );
  }
}

