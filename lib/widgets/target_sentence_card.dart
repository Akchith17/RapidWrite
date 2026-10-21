import 'package:flutter/material.dart';
import '../services/prompt_generator_service.dart';
import '../theme/app_theme.dart';

/// Legacy presets compatibility
class TargetSentences {
  static const List<String> presets = [
    'Sphinx of black quartz, judge my vow',
    'The quick brown fox jumps over the lazy dog',
    'Pack my box with five dozen liquor jugs',
    'How vexingly quick daft zebras jump',
    'Bright vixens jump; dozy fowl quack',
    'Exploring graceful tablet calligraphy with digital ink',
  ];
}

/// Tablet & Web optimized handwriting practice generator card inspired by Monkeytype,
/// tailored specifically for stylus calligraphy and kinematics evaluation.
class TargetSentenceCard extends StatefulWidget {
  final String targetSentence;
  final bool hasStartedWriting;
  final int activeStrokeCount;
  final ValueChanged<String> onSentenceChanged;
  final ValueChanged<PracticeConfig>? onConfigChanged;

  const TargetSentenceCard({
    super.key,
    required this.targetSentence,
    required this.hasStartedWriting,
    required this.activeStrokeCount,
    required this.onSentenceChanged,
    this.onConfigChanged,
  });

  @override
  State<TargetSentenceCard> createState() => _TargetSentenceCardState();
}

class _TargetSentenceCardState extends State<TargetSentenceCard>
    with SingleTickerProviderStateMixin {
  late PracticeConfig _config;
  late final AnimationController _spinController;
  final TextEditingController _customController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _config = const PracticeConfig(
      mode: PracticeMode.words,
      wordCount: 10,
      timeSeconds: 30,
      quoteLength: QuoteLength.short,
      vocabDeck: VocabularyDeck.pangrams,
      hasPunctuation: false,
      hasNumbers: false,
    );
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
  }

  @override
  void dispose() {
    _spinController.dispose();
    _customController.dispose();
    super.dispose();
  }

  void _updateConfig(PracticeConfig newConfig) {
    setState(() {
      _config = newConfig;
    });
    widget.onConfigChanged?.call(newConfig);

    if (newConfig.mode == PracticeMode.custom) {
      _showCustomInputDialog();
    } else {
      _regeneratePrompt();
    }
  }

  void _regeneratePrompt() {
    _spinController.forward(from: 0.0);
    final prompt = PromptGeneratorService.generatePrompt(_config);
    widget.onSentenceChanged(prompt);
  }

  void _showVocabSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.75,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF0D121F),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: Color(0xFF6C63FF), width: 1.0),
              left: BorderSide(color: Color(0xFF1E293B), width: 0.8),
              right: BorderSide(color: Color(0xFF1E293B), width: 0.8),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sheet handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.menu_book_rounded, color: AppTheme.primaryLight, size: 18),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Language / Vocabulary Deck',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Select dictionary to practice specific letter transitions',
                          style: TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white38, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(color: Color(0xFF1E293B), height: 1),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  itemCount: VocabularyDeck.values.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final deck = VocabularyDeck.values[index];
                    final isSelected = _config.vocabDeck == deck;

                    return InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        _updateConfig(_config.copyWith(vocabDeck: deck));
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primary.withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(color: AppTheme.primary.withValues(alpha: 0.4))
                              : null,
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 24,
                              child: isSelected
                                  ? const Icon(Icons.check_rounded, color: AppTheme.secondary, size: 18)
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    deck.label,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.white70,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    deck.description,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white54 : Colors.white30,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (deck == VocabularyDeck.pangrams)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.secondary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'A-Z',
                                  style: TextStyle(
                                    color: AppTheme.secondary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCustomInputDialog() {
    _customController.text = _config.customText;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF101626),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.3)),
        ),
        title: const Row(
          children: [
            Icon(Icons.edit_note_rounded, color: AppTheme.primaryLight, size: 22),
            SizedBox(width: 8),
            Text('Custom Practice Text', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: TextField(
          controller: _customController,
          maxLines: 4,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Paste or type custom sentences, notes, or quotes...',
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final text = _customController.text.trim();
              Navigator.pop(ctx);
              if (text.isNotEmpty) {
                _updateConfig(_config.copyWith(customText: text));
                widget.onSentenceChanged(text);
              }
            },
            child: const Text('Apply Custom Text', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wordCount = widget.targetSentence
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;
    final charCount = widget.targetSentence.length;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1424),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.hasStartedWriting
              ? AppTheme.secondary.withValues(alpha: 0.35)
              : AppTheme.borderDark.withValues(alpha: 0.45),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.hasStartedWriting
                ? AppTheme.secondary.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Monkeytype-style Configuration Bar ──────────────────────────────
          _buildConfigBar(),

          const Divider(color: Color(0xFF1E293B), height: 1),

          // ─── Target Sentence Display Area ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon badge with glow
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.mode_edit_outline_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),

                // Sentence Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [AppTheme.primaryLight, AppTheme.secondary],
                            ).createShader(bounds),
                            child: const Text(
                              'TARGET PRACTICE PROMPT',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.3,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$wordCount words • $charCount chars',
                              style: const TextStyle(color: Colors.white38, fontSize: 10),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Live timer status dot
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: widget.hasStartedWriting ? AppTheme.success : AppTheme.accent,
                                  boxShadow: [
                                    BoxShadow(
                                      color: (widget.hasStartedWriting ? AppTheme.success : AppTheme.accent)
                                          .withValues(alpha: 0.5),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                widget.hasStartedWriting
                                    ? 'Timing (${widget.activeStrokeCount} strokes)'
                                    : 'Ready for stylus stroke',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: widget.hasStartedWriting ? AppTheme.success : AppTheme.accent,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.targetSentence,
                        style: TextStyle(
                          fontSize: _config.mode == PracticeMode.zen ? 15 : 18,
                          fontWeight: FontWeight.w600,
                          color: _config.mode == PracticeMode.zen ? Colors.white60 : Colors.white,
                          letterSpacing: 0.3,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Roll New / Shuffle Button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: _regeneratePrompt,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RotationTransition(
                              turns: _spinController,
                              child: const Icon(
                                Icons.refresh_rounded,
                                size: 16,
                                color: AppTheme.secondary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Shuffle',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF090D1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // ── Section 1: Modifiers (@ punctuation, # numbers) ──────────────
            _buildModifierPill(
              symbol: '@',
              label: 'punctuation',
              isActive: _config.hasPunctuation,
              onTap: () => _updateConfig(_config.copyWith(hasPunctuation: !_config.hasPunctuation)),
            ),
            const SizedBox(width: 6),
            _buildModifierPill(
              symbol: '#',
              label: 'numbers',
              isActive: _config.hasNumbers,
              onTap: () => _updateConfig(_config.copyWith(hasNumbers: !_config.hasNumbers)),
            ),

            _buildSectionDivider(),

            // ── Section 2: Modes (time, words, quote, zen, custom) ───────────
            _buildModePill(
              icon: Icons.timer_outlined,
              label: 'time',
              isActive: _config.mode == PracticeMode.time,
              onTap: () => _updateConfig(_config.copyWith(mode: PracticeMode.time)),
            ),
            const SizedBox(width: 6),
            _buildModePill(
              icon: Icons.text_fields_rounded,
              label: 'words',
              isActive: _config.mode == PracticeMode.words,
              onTap: () => _updateConfig(_config.copyWith(mode: PracticeMode.words)),
            ),
            const SizedBox(width: 6),
            _buildModePill(
              icon: Icons.format_quote_rounded,
              label: 'quote',
              isActive: _config.mode == PracticeMode.quote,
              onTap: () => _updateConfig(_config.copyWith(mode: PracticeMode.quote)),
            ),
            const SizedBox(width: 6),
            _buildModePill(
              icon: Icons.spa_outlined,
              label: 'zen',
              isActive: _config.mode == PracticeMode.zen,
              onTap: () => _updateConfig(_config.copyWith(mode: PracticeMode.zen)),
            ),
            const SizedBox(width: 6),
            _buildModePill(
              icon: Icons.edit_note_rounded,
              label: 'custom',
              isActive: _config.mode == PracticeMode.custom,
              onTap: () => _updateConfig(_config.copyWith(mode: PracticeMode.custom)),
            ),

            _buildSectionDivider(),

            // ── Section 3: Sub-options (dependent on active mode) ─────────────
            if (_config.mode == PracticeMode.words) ...[
              _buildSubOptionPill('10', _config.wordCount == 10, () => _updateConfig(_config.copyWith(wordCount: 10))),
              const SizedBox(width: 4),
              _buildSubOptionPill('25', _config.wordCount == 25, () => _updateConfig(_config.copyWith(wordCount: 25))),
              const SizedBox(width: 4),
              _buildSubOptionPill('50', _config.wordCount == 50, () => _updateConfig(_config.copyWith(wordCount: 50))),
            ] else if (_config.mode == PracticeMode.time) ...[
              _buildSubOptionPill('15s', _config.timeSeconds == 15, () => _updateConfig(_config.copyWith(timeSeconds: 15))),
              const SizedBox(width: 4),
              _buildSubOptionPill('30s', _config.timeSeconds == 30, () => _updateConfig(_config.copyWith(timeSeconds: 30))),
              const SizedBox(width: 4),
              _buildSubOptionPill('60s', _config.timeSeconds == 60, () => _updateConfig(_config.copyWith(timeSeconds: 60))),
              const SizedBox(width: 4),
              _buildSubOptionPill('120s', _config.timeSeconds == 120, () => _updateConfig(_config.copyWith(timeSeconds: 120))),
            ] else if (_config.mode == PracticeMode.quote) ...[
              _buildSubOptionPill('short', _config.quoteLength == QuoteLength.short, () => _updateConfig(_config.copyWith(quoteLength: QuoteLength.short))),
              const SizedBox(width: 4),
              _buildSubOptionPill('medium', _config.quoteLength == QuoteLength.medium, () => _updateConfig(_config.copyWith(quoteLength: QuoteLength.medium))),
              const SizedBox(width: 4),
              _buildSubOptionPill('long', _config.quoteLength == QuoteLength.long, () => _updateConfig(_config.copyWith(quoteLength: QuoteLength.long))),
            ] else if (_config.mode == PracticeMode.custom) ...[
              _buildSubOptionPill('edit text', true, _showCustomInputDialog),
            ] else ...[
              _buildSubOptionPill('freeflow', true, () {}),
            ],

            _buildSectionDivider(),

            // ── Section 4: Vocab Dictionary Dropdown Button ──────────────────
            InkWell(
              onTap: _showVocabSelector,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.language_rounded, size: 14, color: AppTheme.primaryLight),
                    const SizedBox(width: 6),
                    Text(
                      _config.vocabDeck.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down_rounded, size: 18, color: Colors.white54),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModifierPill({
    required String symbol,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final activeColor = const Color(0xFFFBBF24); // Warm amber
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withValues(alpha: 0.14) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? activeColor.withValues(alpha: 0.5) : Colors.transparent,
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              symbol,
              style: TextStyle(
                color: isActive ? activeColor : Colors.white30,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? activeColor : Colors.white38,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModePill({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary.withValues(alpha: 0.22) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? AppTheme.primaryLight.withValues(alpha: 0.6) : Colors.transparent,
            width: 1.0,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    spreadRadius: -1,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isActive ? AppTheme.primaryLight : Colors.white30,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white38,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubOptionPill(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.secondary.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: isSelected
              ? Border.all(color: AppTheme.secondary.withValues(alpha: 0.5), width: 1.0)
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.secondary : Colors.white30,
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionDivider() {
    return Container(
      width: 1,
      height: 18,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: const Color(0xFF1E293B),
    );
  }
}
