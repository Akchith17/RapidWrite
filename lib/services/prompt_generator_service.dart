import 'dart:math';

enum PracticeMode {
  time,
  words,
  quote,
  zen,
  custom,
}

enum QuoteLength {
  short,
  medium,
  long,
  all,
}

enum VocabularyDeck {
  english('english', 'Common vocabulary'),
  english1k('english 1k', 'Top 1,000 core words'),
  english5k('english 5k', 'Top 5,000 extended words'),
  misspelled('misspelled', 'Tricky spelling & letter combinations'),
  doubleLetter('double letter', 'Double-consonant stroke flow'),
  shakespearean('shakespearean', 'Poetic & classical prose'),
  medical('medical', 'Scientific, clinical & anatomical'),
  tech('code & tech', 'Digital architecture & algorithms'),
  pangrams('pangrams', 'A-Z pangrams for full alphabet practice');

  final String label;
  final String description;
  const VocabularyDeck(this.label, this.description);
}

class PracticeConfig {
  final PracticeMode mode;
  final int timeSeconds;
  final int wordCount;
  final QuoteLength quoteLength;
  final VocabularyDeck vocabDeck;
  final bool hasPunctuation;
  final bool hasNumbers;
  final String customText;

  const PracticeConfig({
    this.mode = PracticeMode.words,
    this.timeSeconds = 30,
    this.wordCount = 10,
    this.quoteLength = QuoteLength.short,
    this.vocabDeck = VocabularyDeck.pangrams,
    this.hasPunctuation = false,
    this.hasNumbers = false,
    this.customText = '',
  });

  PracticeConfig copyWith({
    PracticeMode? mode,
    int? timeSeconds,
    int? wordCount,
    QuoteLength? quoteLength,
    VocabularyDeck? vocabDeck,
    bool? hasPunctuation,
    bool? hasNumbers,
    String? customText,
  }) {
    return PracticeConfig(
      mode: mode ?? this.mode,
      timeSeconds: timeSeconds ?? this.timeSeconds,
      wordCount: wordCount ?? this.wordCount,
      quoteLength: quoteLength ?? this.quoteLength,
      vocabDeck: vocabDeck ?? this.vocabDeck,
      hasPunctuation: hasPunctuation ?? this.hasPunctuation,
      hasNumbers: hasNumbers ?? this.hasNumbers,
      customText: customText ?? this.customText,
    );
  }
}

class PromptGeneratorService {
  static final Random _rng = Random();

  static List<String> get pangrams => _pangrams;

  static const List<String> _pangrams = [
    'Sphinx of black quartz, judge my vow',
    'The quick brown fox jumps over the lazy dog',
    'Pack my box with five dozen liquor jugs',
    'How vexingly quick daft zebras jump',
    'Bright vixens jump; dozy fowl quack',
    'Woven silk pyjamas exchanged for blue quartz',
    'Brawny gods just flocked up to quiz and vex him',
    'Jackdaws love my big sphinx of quartz',
    'Glib jocks quiz nymph to vex dwarf',
    'Crazy Fredericka bought many very exquisite opal jewels',
    'Six big devils from Japan quickly forgot how to waltz',
    'Grumpy wizards make toxic brew for the evil queen and jack',
  ];

  static const Map<QuoteLength, List<String>> _quotes = {
    QuoteLength.short: [
      'Simplicity is the ultimate sophistication.',
      'Stay hungry, stay foolish.',
      'In the middle of difficulty lies opportunity.',
      'He who has a why to live can bear almost any how.',
      'Creativity is intelligence having fun.',
      'Action is the foundational key to all success.',
      'Whatever you are, be a good one.',
      'Turn your wounds into wisdom.',
    ],
    QuoteLength.medium: [
      'The journey of a thousand miles begins with a single step.',
      'Do not go where the path may lead, go instead where there is no path and leave a trail.',
      'It is during our darkest moments that we must focus to see the light.',
      'Success is not final, failure is not fatal: it is the courage to continue that counts.',
      'What you do today can improve all your tomorrows.',
      'The only limit to our realization of tomorrow will be our doubts of today.',
    ],
    QuoteLength.long: [
      'Two roads diverged in a wood, and I took the one less traveled by, and that has made all the difference.',
      'To be yourself in a world that is constantly trying to make you something else is the greatest accomplishment.',
      'It is not the critic who counts; not the man who points out how the strong man stumbles, but the one in the arena.',
    ],
  };

  static const Map<VocabularyDeck, List<String>> _deckWords = {
    VocabularyDeck.english: [
      'time', 'year', 'people', 'water', 'place', 'day', 'world', 'school',
      'state', 'family', 'student', 'group', 'country', 'problem', 'hand',
      'system', 'program', 'question', 'work', 'government', 'number', 'night',
      'point', 'home', 'room', 'mother', 'area', 'money', 'story', 'fact',
      'month', 'lot', 'right', 'study', 'book', 'eye', 'job', 'word', 'business',
      'issue', 'side', 'kind', 'head', 'house', 'service', 'friend', 'father',
      'power', 'hour', 'game', 'line', 'end', 'member', 'law', 'car', 'city',
    ],
    VocabularyDeck.english1k: [
      'clarity', 'rhythm', 'balance', 'motion', 'stylus', 'pressure', 'gesture',
      'harmony', 'curvature', 'velocity', 'baseline', 'cursive', 'ascender',
      'descender', 'flourish', 'spacing', 'texture', 'contrast', 'alignment',
      'stroke', 'feather', 'zenith', 'vibrant', 'gentle', 'steady', 'flowing',
      'precision', 'elegance', 'poise', 'cadence', 'graceful', 'artisan',
    ],
    VocabularyDeck.english5k: [
      'phenomenon', 'serendipity', 'ephemeral', 'surreptitious', 'labyrinth',
      'mellifluous', 'quixotic', 'ineffable', 'halcyon', 'solitude', 'effervescent',
      'sonorous', 'luminous', 'resilience', 'panacea', 'cacophony', 'petrichor',
      'ubiquitous', 'vicarious', 'juxtapose', 'ebullient', 'epiphany', 'nostalgia',
    ],
    VocabularyDeck.misspelled: [
      'accommodate', 'embarrass', 'rhythm', 'silhouette', 'vacuum', 'liaison',
      'millennium', 'conscience', 'rendezvous', 'hierarchy', 'fluorescent',
      'occurrence', 'mischievous', 'guarantee', 'subtle', 'bureaucracy',
      'gauge', 'privilege', 'supersede', 'maintenance', 'pronunciation',
    ],
    VocabularyDeck.doubleLetter: [
      'assessment', 'bookkeeper', 'commission', 'parallel', 'committee',
      'sudden', 'successful', 'possession', 'innocent', 'tomorrow', 'goddess',
      'occurred', 'address', 'colleague', 'necessary', 'milligram', 'shuffled',
    ],
    VocabularyDeck.shakespearean: [
      'tempest', 'slumber', 'prologue', 'whispered', 'melancholy', 'majestic',
      'fathom', 'chronicle', 'soliloquy', 'sovereignty', 'enchantment',
      'valiant', 'celestial', 'immortal', 'forswear', 'gallant', 'bequeath',
    ],
    VocabularyDeck.medical: [
      'cerebellum', 'hemisphere', 'capillary', 'endocrine', 'synaptic',
      'neurosis', 'diagnostic', 'vertebra', 'bronchial', 'cardiovascular',
      'retina', 'tendon', 'thoracic', 'clavicle', 'cellular', 'lymphatic',
    ],
    VocabularyDeck.tech: [
      'algorithm', 'asynchronous', 'architecture', 'protocol', 'kinetic',
      'vector', 'neural', 'quantum', 'cryptography', 'heuristic', 'responsive',
      'telemetry', 'compiler', 'interface', 'render', 'pipeline', 'matrix',
    ],
    VocabularyDeck.pangrams: _pangrams,
  };

  static const List<String> _numbersPool = [
    '42', '100', '2026', '360', '7.5', '12th', '99%', '8,400', '3.14', '1st',
    '#7', '24/7', '500m', '1984', '0.05', '60s',
  ];

  static const List<String> _punctuationMarks = [
    ',', ';', '!', '?', '—', '"', ':', '...',
  ];

  /// Generates a prompt string based on the given configuration.
  static String generatePrompt(PracticeConfig config) {
    switch (config.mode) {
      case PracticeMode.zen:
        return 'Zen Flow: Write freely without target constraints. Express your thoughts with graceful ink flow.';

      case PracticeMode.custom:
        if (config.customText.trim().isNotEmpty) {
          return config.customText.trim();
        }
        return 'The quick brown fox jumps over the lazy dog';

      case PracticeMode.quote:
        List<String> pool;
        if (config.quoteLength == QuoteLength.all) {
          pool = [
            ..._quotes[QuoteLength.short]!,
            ..._quotes[QuoteLength.medium]!,
            ..._quotes[QuoteLength.long]!,
          ];
        } else {
          pool = _quotes[config.quoteLength] ?? _quotes[QuoteLength.short]!;
        }
        return pool[_rng.nextInt(pool.length)];

      case PracticeMode.time:
      case PracticeMode.words:
        if (config.vocabDeck == VocabularyDeck.pangrams) {
          final pangram = _pangrams[_rng.nextInt(_pangrams.length)];
          return _applyDecorations(pangram, config.hasPunctuation, config.hasNumbers);
        }

        final wordsList = _deckWords[config.vocabDeck] ?? _deckWords[VocabularyDeck.english]!;
        final count = config.mode == PracticeMode.time
            // For timed sprint, give a comfortable sentence length matching duration
            ? (config.timeSeconds <= 15 ? 8 : config.timeSeconds <= 30 ? 14 : 22)
            : config.wordCount;

        final chosen = <String>[];
        for (int i = 0; i < count; i++) {
          chosen.add(wordsList[_rng.nextInt(wordsList.length)]);
        }

        // Capitalize first word
        if (chosen.isNotEmpty) {
          chosen[0] = chosen[0][0].toUpperCase() + chosen[0].substring(1);
        }

        var sentence = chosen.join(' ');
        return _applyDecorations(sentence, config.hasPunctuation, config.hasNumbers);
    }
  }

  static String _applyDecorations(String text, bool punctuation, bool numbers) {
    var words = text.split(' ');

    if (numbers && words.length >= 3) {
      final insertIdx = 1 + _rng.nextInt(words.length - 1);
      final num = _numbersPool[_rng.nextInt(_numbersPool.length)];
      words.insert(insertIdx, num);
    }

    if (punctuation && words.length >= 4) {
      // Add mid-sentence punctuation
      final pIdx = 1 + _rng.nextInt(words.length - 2);
      final mark = _punctuationMarks[_rng.nextInt(_punctuationMarks.length)];
      if (mark == '"') {
        words[pIdx] = '"${words[pIdx]}"';
      } else {
        words[pIdx] = '${words[pIdx]}$mark';
      }
    }

    var result = words.join(' ');
    // Ensure terminal punctuation if punctuation mode is enabled
    if (punctuation && !result.endsWith('.') && !result.endsWith('!') && !result.endsWith('?')) {
      result += '.';
    }
    return result;
  }
}
