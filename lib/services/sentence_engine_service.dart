import 'dart:math';
import '../models/practice_settings.dart';
import '../models/target_sentence_model.dart';

/// Intelligent target-sentence selection and generation engine for RapidWrite.
/// Dynamically adapts to target WPM, desired word count, difficulty tier,
/// and character category requirements (numbers, symbols, punctuation, casing).
class SentenceEngineService {
  static final Random _rng = Random();

  // ═══════════════════════════════════════════════════════════════════════════
  // 1. CURATED EDUCATIONAL SENTENCE CORPUS (Categorized by Difficulty & Content)
  // ═══════════════════════════════════════════════════════════════════════════

  // ── Beginner sentences (elementary vocabulary, simple structure) ───────────
  static const List<String> _beginnerStandard = [
    'The quick brown fox jumps over the lazy dog.',
    'Pack my box with five dozen fresh apples.',
    'A soft blue bird sings high in the green tree.',
    'We like to read good books and write with neat ink.',
    'Sunny days bring bright smiles to all children at school.',
    'The gentle kitten plays with a little red ball.',
    'Warm sun shines over the quiet blue lake every morning.',
    'Children walk to the park and play cheerful games together.',
  ];

  static const List<String> _beginnerWithNumbers = [
    'There are 7 days in a week and 12 months in every year.',
    'The school library has 5 big tables and 20 soft chairs.',
    'We counted 10 bright stars and 2 birds in the morning sky.',
    'A spider has 8 little legs and can spin 3 silk webs.',
    'Our friendly team won 4 games out of 6 matches this term.',
    'There are 24 hours in a full day and 60 minutes in an hour.',
  ];

  static const List<String> _beginnerWithSpecial = [
    'Apples & oranges taste sweet, and fresh milk costs \$2 each.',
    'Our art group won #1 place & received a golden ribbon.',
    'In math class, 2 + 3 = 5 and 4 + 4 = 8.',
    'Save 10% on sketchbooks & crayons at our school fair.',
    'Write to us @school & join the fun drawing club today.',
  ];

  static const List<String> _beginnerWithNumbersAndSpecial = [
    'Team #1 scored 100% on the quiz & won 5 shiny medals.',
    'At the shop, 2 notebooks & 3 pencils cost \$4 in total.',
    'We finished 10 exercises with 95% accuracy & got #1 rank.',
    'In math, 10 + 5 = 15 & 20 - 4 = 16 for all 25 students.',
  ];

  // ── Easy sentences (everyday vocabulary, compound sentences) ───────────────
  static const List<String> _easyStandard = [
    'Sphinx of black quartz, judge my sincere handwriting vow.',
    'Learning to write smoothly takes daily patience and steady practice.',
    'The morning breeze rustled the leaves while birds greeted the sunrise.',
    'Careful strokes create harmonious letters that are effortless to read.',
    'Students gathered in the classroom to share their favorite stories.',
    'Every journey begins with a small step and grows with quiet determination.',
    'Clear handwriting reflects a calm mind and disciplined focus.',
  ];

  static const List<String> _easyWithNumbers = [
    'The Apollo 11 mission reached the Moon in 1969 after 4 days of flight.',
    'Our science project recorded 25 plant species in the 3 acre school garden.',
    'Earth travels around the Sun at about 30 kilometers every single second.',
    'The local museum displays 150 ancient coins dating back to 300 BC.',
    'Over 500 students participated in the annual 5 kilometer school run.',
  ];

  static const List<String> _easyWithSpecial = [
    'Art & handwriting express thought, while neatness & clarity build confidence.',
    'Project #3 focuses on balance & rhythm: practice makes progress.',
    'The student council email @school offers tips & guides for calligraphy.',
    'Discounts of 20% apply to drawing pens & paper pads at the student store.',
    'Remember: effort + patience = mastery in both science & the arts.',
  ];

  static const List<String> _easyWithNumbersAndSpecial = [
    'Notice #4: All 12 teams must submit 100% of assignments by 5 PM & attend room #2.',
    'The student shop offers 15% off notebooks (now \$3.50) & 25% off 12-color pen sets.',
    'Formula check: if 5 + x = 12, then x = 7; student @lab2 verified this with 100% precision.',
    'Event #7 gathered 45 students & raised \$250 for the regional wildlife fund.',
  ];

  // ── Intermediate sentences (multi-clause, academic vocabulary) ─────────────
  static const List<String> _intermediateStandard = [
    'Handwriting fluency develops through relaxed finger motion, consistent slant, and rhythmic stroke velocity.',
    'Language allows human civilization to bridge historical distances, preserving thoughts across centuries with timeless grace.',
    'True craftsmanship lies not in hurried execution, but in deliberate attention to proportion, curvature, and subtle balance.',
    'Scientific inquiry demands curious observation, systematic hypotheses, and disciplined documentation of unexpected anomalies.',
    'The architecture of an ancient library mirrors the intellectual heritage of scholars who cherished knowledge above worldly wealth.',
    'When students cultivate patience, challenging concepts gradually transform into clear, elegant understanding.',
  ];

  static const List<String> _intermediateWithNumbers = [
    'In 2026, educational researchers observed that students writing at 25 WPM retained 30% more conceptual information.',
    'The human brain contains roughly 86 billion neurons, forming over 100 trillion synaptic connections throughout a lifetime.',
    'Mount Everest reaches an altitude of 8,848 meters, with temperatures dropping below minus 35 degrees during winter.',
    'Our solar system formed approximately 4.6 billion years ago from a massive rotating interstellar molecular cloud.',
  ];

  static const List<String> _intermediateWithSpecial = [
    'Scholarly writing requires rigor: verify primary sources, balance brevity & depth, and attribute insights @citations.',
    'Design principle #5: form + function = elegance; excess ornament weakens clarity & distracts from core communication.',
    'Review the syllabus @portal: chapters 4 & 6 cover calligraphy kinetics, pen-pressure rhythm, and spatial proportions.',
    'Excellence in penmanship combines three virtues: consistency (90%+), fluid baseline alignment, and uniform letter spacing.',
  ];

  static const List<String> _intermediateWithNumbersAndSpecial = [
    'Report #12 indicates that 85% of calligraphy learners improved velocity from 15 to 28 WPM & reduced error rates by 40%.',
    'Lab protocol: mix 50 mL solution A with 25 mL reagent B at 20°C; record measurements in log #3 & notify @supervisor.',
    'Budget allocation: 40% for lab equipment (\$1,200), 35% for library references (\$1,050), & 25% for digital stylus licenses.',
    'Equation 3.1: with alpha = 0.05 & n = 120, the calculated p-value was < 0.01; results verified by research team @lab4.',
  ];

  // ── Advanced sentences (complex syntax, scholarly prose, dense typography) ──
  static const List<String> _advancedStandard = [
    'The philosophical juxtaposition of kinetic dynamism and calligraphic poise exemplifies the synthesis of biomechanics and aesthetic discernment.',
    'Epistemological inquiry presupposes that observed phenomena transcend subjective perception, requiring rigorous methodological empiricism.',
    'Neuroplastic adaptations occurring during fine-motor penmanship exercises stimulate bilateral hemispheric communication within the cerebral cortex.',
    'Architectural equilibrium requires harmonious symmetry, meticulous spatial cadence, and unyielding fidelity to structural integrity.',
    'Literary eloquence emerges when profound philosophical depth coalesces effortlessly with crystalline typographic rhythm and syntactic precision.',
  ];

  static const List<String> _advancedWithNumbers = [
    'Recent neurological studies in 2025 demonstrate that 45 minutes of daily stylus calligraphy accelerates cortical pathway development by 34.5%.',
    'Quantum computing architectures operating at 0.015 Kelvin process 1,024 qubits simultaneously, surpassing conventional supercomputers by a factor of 10,000.',
    'Geological stratigraphy reveals that the sedimentary layer formed 65.5 million years ago across 12 distinct geographic continents.',
  ];

  static const List<String> _advancedWithSpecial = [
    'Methodological maxim #9: observe anomalies, corroborate empirical metrics (r > 0.85), & distinguish correlation from causation @peer-review.',
    'Biomechanical calligraphy model: velocity (px/s) + pressure rhythm (%) = kinematic fluidity & minimum muscular fatigue.',
    'Academic inquiry thrives on open discourse: synthesize thesis & antithesis to formulate #1 robust paradigm for digital typography.',
  ];

  static const List<String> _advancedWithNumbersAndSpecial = [
    'Publication #88/B: across 350 trials, 92.4% of participants demonstrated slant stability (variance < 3.5°) & completed 40 WPM sprints in < 60s.',
    'Theorem 7.4 states: if delta = 0.025 & lambda = 4.8, then composite aesthetic index E = 100 * (1 - e^(-k*t)) with 99.9% statistical confidence.',
    'Grant #2026-X: \$450,000 distributed among 3 institutions (MIT 40%, Oxford 35% & Stanford 25%) to study digital ink ergonomics @neuro-lab.',
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // 2. MAIN ENGINE METHOD
  // ═══════════════════════════════════════════════════════════════════════════

  /// Generates or selects a target sentence adhering to all [settings],
  /// accompanied by accurate structural statistics and dynamic timer calculations.
  /// [currentText] can be passed so that shuffling is guaranteed to pick a different sentence.
  static TargetSentenceModel generateSentence(
    PracticeSettings settings, {
    String? currentText,
  }) {
    // If user provided custom text in settings, use that directly
    if (settings.customText.trim().isNotEmpty) {
      return TargetSentenceModel.fromText(
        text: settings.customText.trim(),
        settings: settings,
        note: 'User custom text',
      );
    }

    // Determine target word count based on category
    final targetWords = settings.targetWordCount;

    // Pick candidate pool based on difficulty and content flags
    final pool = _selectSentencePool(
      difficulty: settings.difficulty,
      needsNumbers: settings.includeNumbers,
      needsSpecial: settings.includeSpecialCharacters,
    );

    // Filter or rank candidates by proximity to requested word count
    String baseSentence = _pickBestCandidate(pool, targetWords, excludeText: currentText);

    // If candidate is too short for a medium/long/custom requirement, concatenate cleanly
    if (settings.lengthCategory != SentenceLengthCategory.short &&
        _countWords(baseSentence) < targetWords - 5) {
      baseSentence = _assembleMultiSentenceText(pool, targetWords, excludeText: currentText);
    }

    // Apply casing adjustments
    String finalSentence = _applyCasing(
      baseSentence,
      includeUppercase: settings.includeUppercase,
      includeLowercase: settings.includeLowercase,
    );

    // Apply punctuation adjustments
    if (!settings.includePunctuation) {
      finalSentence = _stripPunctuation(finalSentence);
    }

    // Check if any requirements could not be strictly met
    String? adaptationNote;
    if (settings.includeNumbers && !RegExp(r'[0-9]').hasMatch(finalSentence)) {
      adaptationNote = 'Numbers were enabled but suitable sentence was unavailable in current pool.';
    }
    if (settings.includeSpecialCharacters &&
        !RegExp(r'[@#%&+=$\/\\*]').hasMatch(finalSentence)) {
      adaptationNote = (adaptationNote == null ? '' : '$adaptationNote ') +
          'Special characters were enabled but limited in current difficulty tier.';
    }

    return TargetSentenceModel.fromText(
      text: finalSentence,
      settings: settings,
      note: adaptationNote,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 3. SELECTION & ASSEMBLY HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  static List<String> _selectSentencePool({
    required PracticeDifficulty difficulty,
    required bool needsNumbers,
    required bool needsSpecial,
  }) {
    switch (difficulty) {
      case PracticeDifficulty.beginner:
        if (needsNumbers && needsSpecial) return _beginnerWithNumbersAndSpecial;
        if (needsNumbers) return _beginnerWithNumbers;
        if (needsSpecial) return _beginnerWithSpecial;
        return _beginnerStandard;

      case PracticeDifficulty.easy:
        if (needsNumbers && needsSpecial) return _easyWithNumbersAndSpecial;
        if (needsNumbers) return _easyWithNumbers;
        if (needsSpecial) return _easyWithSpecial;
        return _easyStandard;

      case PracticeDifficulty.intermediate:
      case PracticeDifficulty.custom:
        if (needsNumbers && needsSpecial) return _intermediateWithNumbersAndSpecial;
        if (needsNumbers) return _intermediateWithNumbers;
        if (needsSpecial) return _intermediateWithSpecial;
        return _intermediateStandard;

      case PracticeDifficulty.advanced:
        if (needsNumbers && needsSpecial) return _advancedWithNumbersAndSpecial;
        if (needsNumbers) return _advancedWithNumbers;
        if (needsSpecial) return _advancedWithSpecial;
        return _advancedStandard;
    }
  }

  static String _pickBestCandidate(
    List<String> pool,
    int targetWords, {
    String? excludeText,
  }) {
    if (pool.isEmpty) {
      return 'The quick brown fox jumps over the lazy dog.';
    }

    final cleanExclude = excludeText?.trim().toLowerCase();
    final eligible = (cleanExclude != null && pool.length > 1)
        ? pool.where((s) => s.trim().toLowerCase() != cleanExclude).toList()
        : pool;

    final candidates = eligible.isNotEmpty ? eligible : pool;
    final shuffled = List<String>.from(candidates)..shuffle(_rng);

    // Pick from candidates reasonably close to requested word count (+-5 words)
    final closeMatches = shuffled.where((s) => (_countWords(s) - targetWords).abs() <= 5).toList();
    if (closeMatches.isNotEmpty) {
      return closeMatches[_rng.nextInt(closeMatches.length)];
    }

    // Otherwise find candidate closest to target words
    String best = shuffled.first;
    int bestDiff = (_countWords(best) - targetWords).abs();

    for (final s in shuffled) {
      final diff = (_countWords(s) - targetWords).abs();
      if (diff < bestDiff) {
        best = s;
        bestDiff = diff;
      }
    }
    return best;
  }

  static String _assembleMultiSentenceText(
    List<String> pool,
    int targetWords, {
    String? excludeText,
  }) {
    if (pool.isEmpty) return 'The quick brown fox jumps over the lazy dog.';

    final cleanExclude = excludeText?.trim().toLowerCase();
    final eligible = (cleanExclude != null && pool.length > 1)
        ? pool.where((s) => s.trim().toLowerCase() != cleanExclude).toList()
        : pool;

    final candidates = eligible.isNotEmpty ? eligible : pool;
    final shuffled = List<String>.from(candidates)..shuffle(_rng);
    final chosen = <String>[];
    int currentWords = 0;

    for (final s in shuffled) {
      chosen.add(s);
      currentWords += _countWords(s);
      if (currentWords >= targetWords) break;
    }

    if (chosen.isEmpty) return candidates.first;
    return chosen.join(' ');
  }

  static int _countWords(String text) {
    return text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }

  static String _applyCasing(
    String text, {
    required bool includeUppercase,
    required bool includeLowercase,
  }) {
    if (!includeUppercase && includeLowercase) {
      return text.toLowerCase();
    }
    if (includeUppercase && !includeLowercase) {
      return text.toUpperCase();
    }
    return text; // Both enabled: keep standard mixed case
  }

  static String _stripPunctuation(String text) {
    return text
        .replaceAll(RegExp(r'''[,.;:!?\'"“”"'\-()]'''), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
