import 'dart:convert';

/// Predefined sentence length categories
enum SentenceLengthCategory {
  short('Short', 12, '8–15 words'),
  medium('Medium', 25, '20–35 words'),
  long('Long', 45, '40–60 words'),
  custom('Custom', 20, 'Custom word count');

  final String label;
  final int defaultWords;
  final String description;
  const SentenceLengthCategory(this.label, this.defaultWords, this.description);
}

/// Difficulty levels shaping vocabulary, syntax, and symbol density
enum PracticeDifficulty {
  beginner('Beginner', 'Elementary words, simple sentence structure'),
  easy('Easy', 'Everyday vocabulary, gentle punctuation'),
  intermediate('Intermediate', 'Varied vocabulary, standard punctuation & clauses'),
  advanced('Advanced', 'Challenging vocabulary, rich syntax & symbols'),
  custom('Custom', 'Fully tailored settings');

  final String label;
  final String description;
  const PracticeDifficulty(this.label, this.description);
}

/// Comprehensive settings model for handwriting practice sessions.
class PracticeSettings {
  // ── Target Speed ─────────────────────────────────────────────────────────
  final int targetWpm; // Target Words Per Minute (e.g. 5, 10, 15, 20, 25, 30, 35, 40, or custom)
  final int? targetCpm; // Optional independent Characters Per Minute target

  // ── Sentence Length ──────────────────────────────────────────────────────
  final SentenceLengthCategory lengthCategory;
  final int customWordCount; // Used when lengthCategory == custom

  // ── Difficulty Level ─────────────────────────────────────────────────────
  final PracticeDifficulty difficulty;

  // ── Character Content Options ────────────────────────────────────────────
  final bool includeLowercase;
  final bool includeUppercase;
  final bool includeNumbers;
  final bool includeSpecialCharacters; // @, #, %, &, mathematical symbols (+, =, $)
  final bool includePunctuation;
  final bool mixedAlphanumeric;

  // ── Custom Freeform Sentence Override ────────────────────────────────────
  final String customText;

  const PracticeSettings({
    this.targetWpm = 20,
    this.targetCpm,
    this.lengthCategory = SentenceLengthCategory.short,
    this.customWordCount = 15,
    this.difficulty = PracticeDifficulty.intermediate,
    this.includeLowercase = true,
    this.includeUppercase = true,
    this.includeNumbers = false,
    this.includeSpecialCharacters = false,
    this.includePunctuation = true,
    this.mixedAlphanumeric = false,
    this.customText = '',
  });

  /// Preset WPM choices recommended by curriculum standards
  static const List<int> wpmPresets = [5, 10, 15, 20, 25, 30, 35, 40];

  /// Effective requested word count
  int get targetWordCount {
    if (lengthCategory == SentenceLengthCategory.custom) {
      return customWordCount.clamp(4, 120);
    }
    return lengthCategory.defaultWords;
  }

  /// Calculates recommended duration in seconds based on word count:
  /// Estimated duration in seconds = (Number of words / Target WPM) * 60
  static double calculateRecommendedDurationSec({
    required int wordCount,
    required int targetWpm,
  }) {
    if (targetWpm <= 0) return 60.0;
    return (wordCount / targetWpm) * 60.0;
  }

  /// Calculates recommended duration in minutes:
  /// Estimated duration in minutes = Number of words / Target WPM
  static double calculateRecommendedDurationMinutes({
    required int wordCount,
    required int targetWpm,
  }) {
    if (targetWpm <= 0) return 1.0;
    return wordCount / targetWpm;
  }

  /// Calculates recommended duration based on CPM:
  /// Estimated duration in seconds = (Number of characters / Target CPM) * 60
  static double calculateRecommendedDurationCpmSec({
    required int charCount,
    required int targetCpm,
  }) {
    if (targetCpm <= 0) return 60.0;
    return (charCount / targetCpm) * 60.0;
  }

  PracticeSettings copyWith({
    int? targetWpm,
    int? targetCpm,
    SentenceLengthCategory? lengthCategory,
    int? customWordCount,
    PracticeDifficulty? difficulty,
    bool? includeLowercase,
    bool? includeUppercase,
    bool? includeNumbers,
    bool? includeSpecialCharacters,
    bool? includePunctuation,
    bool? mixedAlphanumeric,
    String? customText,
  }) {
    return PracticeSettings(
      targetWpm: targetWpm ?? this.targetWpm,
      targetCpm: targetCpm ?? this.targetCpm,
      lengthCategory: lengthCategory ?? this.lengthCategory,
      customWordCount: customWordCount ?? this.customWordCount,
      difficulty: difficulty ?? this.difficulty,
      includeLowercase: includeLowercase ?? this.includeLowercase,
      includeUppercase: includeUppercase ?? this.includeUppercase,
      includeNumbers: includeNumbers ?? this.includeNumbers,
      includeSpecialCharacters: includeSpecialCharacters ?? this.includeSpecialCharacters,
      includePunctuation: includePunctuation ?? this.includePunctuation,
      mixedAlphanumeric: mixedAlphanumeric ?? this.mixedAlphanumeric,
      customText: customText ?? this.customText,
    );
  }

  Map<String, dynamic> toJson() => {
        'targetWpm': targetWpm,
        'targetCpm': targetCpm,
        'lengthCategory': lengthCategory.name,
        'customWordCount': customWordCount,
        'difficulty': difficulty.name,
        'includeLowercase': includeLowercase,
        'includeUppercase': includeUppercase,
        'includeNumbers': includeNumbers,
        'includeSpecialCharacters': includeSpecialCharacters,
        'includePunctuation': includePunctuation,
        'mixedAlphanumeric': mixedAlphanumeric,
        'customText': customText,
      };

  factory PracticeSettings.fromJson(Map<String, dynamic> json) {
    SentenceLengthCategory cat = SentenceLengthCategory.short;
    try {
      cat = SentenceLengthCategory.values.firstWhere(
        (e) => e.name == json['lengthCategory'],
        orElse: () => SentenceLengthCategory.short,
      );
    } catch (_) {}

    PracticeDifficulty diff = PracticeDifficulty.intermediate;
    try {
      diff = PracticeDifficulty.values.firstWhere(
        (e) => e.name == json['difficulty'],
        orElse: () => PracticeDifficulty.intermediate,
      );
    } catch (_) {}

    return PracticeSettings(
      targetWpm: (json['targetWpm'] as num?)?.toInt() ?? 20,
      targetCpm: (json['targetCpm'] as num?)?.toInt(),
      lengthCategory: cat,
      customWordCount: (json['customWordCount'] as num?)?.toInt() ?? 15,
      difficulty: diff,
      includeLowercase: json['includeLowercase'] as bool? ?? true,
      includeUppercase: json['includeUppercase'] as bool? ?? true,
      includeNumbers: json['includeNumbers'] as bool? ?? false,
      includeSpecialCharacters: json['includeSpecialCharacters'] as bool? ?? false,
      includePunctuation: json['includePunctuation'] as bool? ?? true,
      mixedAlphanumeric: json['mixedAlphanumeric'] as bool? ?? false,
      customText: json['customText'] as String? ?? '',
    );
  }

  static PracticeSettings defaultSettings() => const PracticeSettings();
}
