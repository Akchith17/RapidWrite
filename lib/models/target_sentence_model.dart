import 'practice_settings.dart';

/// Metadata and structural statistics for an active target sentence.
class TargetSentenceModel {
  final String text;
  final int wordCount;
  final int characterCount;
  final int targetWpm;
  final int targetCpm;
  final double recommendedDurationSec;
  final double recommendedDurationMinutes;
  final PracticeDifficulty difficulty;
  final List<String> categoriesPresent; // e.g. ["Uppercase", "Numbers", "Punctuation"]
  final String? adaptationNote;

  const TargetSentenceModel({
    required this.text,
    required this.wordCount,
    required this.characterCount,
    required this.targetWpm,
    required this.targetCpm,
    required this.recommendedDurationSec,
    required this.recommendedDurationMinutes,
    required this.difficulty,
    this.categoriesPresent = const [],
    this.adaptationNote,
  });

  /// Factory constructor calculating word and character statistics and durations
  factory TargetSentenceModel.fromText({
    required String text,
    required PracticeSettings settings,
    String? note,
  }) {
    final cleanText = text.trim();
    final words = cleanText.isEmpty
        ? <String>[]
        : cleanText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final wordCount = words.length;
    final charCount = cleanText.length;
    final wpm = settings.targetWpm > 0 ? settings.targetWpm : 20;
    final cpm = settings.targetCpm ?? (wpm * 5);

    final durSec = PracticeSettings.calculateRecommendedDurationSec(
      wordCount: wordCount,
      targetWpm: wpm,
    );
    final durMin = PracticeSettings.calculateRecommendedDurationMinutes(
      wordCount: wordCount,
      targetWpm: wpm,
    );

    final categories = <String>[];
    if (RegExp(r'[a-z]').hasMatch(cleanText)) categories.add('lowercase');
    if (RegExp(r'[A-Z]').hasMatch(cleanText)) categories.add('uppercase');
    if (RegExp(r'[0-9]').hasMatch(cleanText)) categories.add('numbers');
    if (RegExp(r'[@#%&+=$\/\\*]').hasMatch(cleanText)) categories.add('special');
    if (RegExp(r'''[,.;:!?\'"\-]''').hasMatch(cleanText)) categories.add('punctuation');

    return TargetSentenceModel(
      text: cleanText,
      wordCount: wordCount,
      characterCount: charCount,
      targetWpm: wpm,
      targetCpm: cpm,
      recommendedDurationSec: durSec,
      recommendedDurationMinutes: durMin,
      difficulty: settings.difficulty,
      categoriesPresent: categories,
      adaptationNote: note,
    );
  }

  /// Formatted duration for student display, e.g. "90s (1m 30s)" or "45s"
  String get formattedDuration {
    final totalSec = recommendedDurationSec.round();
    final mins = totalSec ~/ 60;
    final secs = totalSec % 60;
    if (mins == 0) {
      return '${totalSec}s';
    } else if (secs == 0) {
      return '${mins}m';
    } else {
      return '${totalSec}s (${mins}m ${secs}s)';
    }
  }
}
