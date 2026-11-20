import 'package:flutter/material.dart';
import '../models/practice_settings.dart';
import '../models/target_sentence_model.dart';
import '../services/sentence_engine_service.dart';
import '../theme/app_theme.dart';

/// Modal sheet & dialog providing comprehensive customization for handwriting practice.
/// Features target WPM presets, sentence length options, character category toggles,
/// difficulty tiers, and dynamic real-time target sentence previews with duration math.
class PracticeSettingsModal extends StatefulWidget {
  final PracticeSettings initialSettings;
  final ValueChanged<TargetSentenceModel> onStartPractice;
  final ValueChanged<PracticeSettings>? onSaveSettings;

  const PracticeSettingsModal({
    super.key,
    required this.initialSettings,
    required this.onStartPractice,
    this.onSaveSettings,
  });

  /// Displays the modal responsively: BottomSheet on mobile, Dialog on desktop/tablet.
  static Future<void> show({
    required BuildContext context,
    required PracticeSettings initialSettings,
    required ValueChanged<TargetSentenceModel> onStartPractice,
    ValueChanged<PracticeSettings>? onSaveSettings,
  }) async {
    final width = MediaQuery.of(context).size.width;
    if (width > 768) {
      // Desktop / large tablet dialog
      await showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680, maxHeight: 780),
            child: PracticeSettingsModal(
              initialSettings: initialSettings,
              onStartPractice: onStartPractice,
              onSaveSettings: onSaveSettings,
            ),
          ),
        ),
      );
    } else {
      // Mobile / small tablet bottom sheet
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.90,
          ),
          child: PracticeSettingsModal(
            initialSettings: initialSettings,
            onStartPractice: onStartPractice,
            onSaveSettings: onSaveSettings,
          ),
        ),
      );
    }
  }

  @override
  State<PracticeSettingsModal> createState() => _PracticeSettingsModalState();
}

class _PracticeSettingsModalState extends State<PracticeSettingsModal> {
  late PracticeSettings _settings;
  late TargetSentenceModel _previewModel;
  bool _isCustomWpm = false;
  late final TextEditingController _customWpmController;
  late final TextEditingController _customWordsController;
  late final TextEditingController _customTextController;

  // Visual Theme Constants
  static const Color solarOrange = Color(0xFFFF6B00);
  static const Color orangeDark   = Color(0xFFEA580C);
  static const Color bgDark       = Color(0xFF0F172A);
  static const Color cardDark     = Color(0xFF1E293B);
  static const Color borderDark   = Color(0xFF334155);

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings;
    _isCustomWpm = !PracticeSettings.wpmPresets.contains(_settings.targetWpm);
    _customWpmController = TextEditingController(text: _settings.targetWpm.toString());
    _customWordsController = TextEditingController(text: _settings.customWordCount.toString());
    _customTextController = TextEditingController(text: _settings.customText);

    _regeneratePreview();
  }

  @override
  void dispose() {
    _customWpmController.dispose();
    _customWordsController.dispose();
    _customTextController.dispose();
    super.dispose();
  }

  void _regeneratePreview() {
    setState(() {
      _previewModel = SentenceEngineService.generateSentence(_settings);
    });
  }

  void _updateSettings(PracticeSettings newSettings) {
    setState(() {
      _settings = newSettings;
    });
    _regeneratePreview();
  }

  void _startSession() {
    widget.onSaveSettings?.call(_settings);
    widget.onStartPractice(_previewModel);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bgDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: borderDark, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 30,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          _buildHeader(),

          // Scrollable Settings Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Live Adaptive Preview Card (shows target, counts, recommended duration)
                  _buildLivePreviewCard(),
                  const SizedBox(height: 18),

                  // 2. Section A: Target Writing Speed (WPM)
                  _buildSpeedSection(),
                  const SizedBox(height: 18),

                  // 3. Section B: Sentence Length (Short, Medium, Long, Custom)
                  _buildLengthSection(),
                  const SizedBox(height: 18),

                  // 4. Section D: Difficulty Level
                  _buildDifficultySection(),
                  const SizedBox(height: 18),

                  // 5. Section C: Character Content Options (Numbers, Symbols, Casing, Punctuation)
                  _buildContentOptionsSection(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          _buildBottomBar(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION BUILDERS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: borderDark, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: solarOrange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.tune_rounded, color: solarOrange, size: 20),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Practice Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
              Text(
                'Customize speed target, sentence length & character types',
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  /// Live preview card demonstrating real-time duration calculation
  Widget _buildLivePreviewCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderDark, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_stories_rounded, color: solarOrange, size: 16),
              const SizedBox(width: 6),
              const Text(
                'TARGET SENTENCE PREVIEW',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              // Generate Another Button
              InkWell(
                onTap: _regeneratePreview,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: solarOrange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: solarOrange.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded, color: solarOrange, size: 13),
                      SizedBox(width: 4),
                      Text(
                        'Generate Another',
                        style: TextStyle(
                          color: solarOrange,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Sentence Text
          SelectableText(
            _previewModel.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14.5,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),

          // Metadata Badges (Words, Chars, Target WPM, Recommended Duration)
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildBadge(
                icon: Icons.text_fields_rounded,
                label: '${_previewModel.wordCount} words',
              ),
              _buildBadge(
                icon: Icons.abc_rounded,
                label: '${_previewModel.characterCount} chars',
              ),
              _buildBadge(
                icon: Icons.speed_rounded,
                label: '${_previewModel.targetWpm} WPM target',
                highlight: true,
              ),
              _buildBadge(
                icon: Icons.timer_outlined,
                label: 'Recommended: ${_previewModel.formattedDuration}',
                highlight: true,
              ),
            ],
          ),

          // Adaptation Note if any
          if (_previewModel.adaptationNote != null) ...[
            const SizedBox(height: 8),
            Text(
              'ℹ️ ${_previewModel.adaptationNote}',
              style: const TextStyle(color: Color(0xFFFBBF24), fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSpeedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'A. Target Writing Speed',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 6),
            Text(
              '(determines recommended session duration)',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            ...PracticeSettings.wpmPresets.map((wpm) {
              final isSelected = !_isCustomWpm && _settings.targetWpm == wpm;
              return _buildPill(
                label: '$wpm WPM',
                isSelected: isSelected,
                onTap: () {
                  setState(() => _isCustomWpm = false);
                  _updateSettings(_settings.copyWith(targetWpm: wpm));
                },
              );
            }),
            _buildPill(
              label: 'Custom',
              isSelected: _isCustomWpm,
              onTap: () {
                setState(() => _isCustomWpm = true);
              },
            ),
          ],
        ),

        // Custom WPM Input Field
        if (_isCustomWpm) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('Target WPM:', style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(width: 10),
              SizedBox(
                width: 90,
                child: TextField(
                  controller: _customWpmController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    filled: true,
                    fillColor: cardDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: borderDark),
                    ),
                    suffixText: 'WPM',
                    suffixStyle: const TextStyle(color: solarOrange, fontSize: 11),
                  ),
                  onChanged: (val) {
                    final parsed = int.tryParse(val);
                    if (parsed != null && parsed >= 5 && parsed <= 120) {
                      _updateSettings(_settings.copyWith(targetWpm: parsed));
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Range: 5 to 120 WPM',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildLengthSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'B. Sentence Length',
          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: SentenceLengthCategory.values.map((cat) {
            final isSelected = _settings.lengthCategory == cat;
            return _buildPill(
              label: '${cat.label} (${cat.description})',
              isSelected: isSelected,
              onTap: () {
                _updateSettings(_settings.copyWith(lengthCategory: cat));
              },
            );
          }).toList(),
        ),

        // Custom word count input
        if (_settings.lengthCategory == SentenceLengthCategory.custom) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('Word count:', style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(width: 10),
              SizedBox(
                width: 90,
                child: TextField(
                  controller: _customWordsController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    filled: true,
                    fillColor: cardDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: borderDark),
                    ),
                    suffixText: 'words',
                    suffixStyle: const TextStyle(color: solarOrange, fontSize: 11),
                  ),
                  onChanged: (val) {
                    final parsed = int.tryParse(val);
                    if (parsed != null && parsed >= 4 && parsed <= 120) {
                      _updateSettings(_settings.copyWith(customWordCount: parsed));
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Range: 4 to 120 words',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDifficultySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'D. Difficulty Level',
          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: PracticeDifficulty.values.map((diff) {
            final isSelected = _settings.difficulty == diff;
            return _buildPill(
              label: diff.label,
              isSelected: isSelected,
              onTap: () {
                _updateSettings(_settings.copyWith(difficulty: diff));
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildContentOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'C. Sentence Content & Character Categories',
          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderDark, width: 1),
          ),
          child: Column(
            children: [
              _buildToggleRow(
                title: 'Lowercase Letters',
                subtitle: 'Include standard lowercase alphabet (a-z)',
                value: _settings.includeLowercase,
                onChanged: (v) {
                  if (!v && !_settings.includeUppercase) return; // Must have at least one casing
                  _updateSettings(_settings.copyWith(includeLowercase: v));
                },
              ),
              const Divider(color: borderDark, height: 16),
              _buildToggleRow(
                title: 'Uppercase Letters',
                subtitle: 'Include capital letters at word or sentence boundaries (A-Z)',
                value: _settings.includeUppercase,
                onChanged: (v) {
                  if (!v && !_settings.includeLowercase) return;
                  _updateSettings(_settings.copyWith(includeUppercase: v));
                },
              ),
              const Divider(color: borderDark, height: 16),
              _buildToggleRow(
                title: 'Meaningful Numbers',
                subtitle: 'Embed realistic dates, counts, and measurements (0-9)',
                value: _settings.includeNumbers,
                onChanged: (v) => _updateSettings(_settings.copyWith(includeNumbers: v)),
              ),
              const Divider(color: borderDark, height: 16),
              _buildToggleRow(
                title: 'Special Characters',
                subtitle: 'Include symbols like @, #, %, &, +, =, and \$',
                value: _settings.includeSpecialCharacters,
                onChanged: (v) => _updateSettings(_settings.copyWith(includeSpecialCharacters: v)),
              ),
              const Divider(color: borderDark, height: 16),
              _buildToggleRow(
                title: 'Standard Punctuation',
                subtitle: 'Commas, periods, semicolons, and quotation marks',
                value: _settings.includePunctuation,
                onChanged: (v) => _updateSettings(_settings.copyWith(includePunctuation: v)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: bgDark,
        border: Border(top: BorderSide(color: borderDark, width: 1)),
      ),
      child: Row(
        children: [
          // Duration summary
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Recommended: ${_previewModel.formattedDuration}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Target speed: ${_settings.targetWpm} WPM (${_previewModel.wordCount} words)',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),

          // Start Practice Primary Button
          ElevatedButton(
            onPressed: _startSession,
            style: ElevatedButton.styleFrom(
              backgroundColor: solarOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit_rounded, size: 16),
                SizedBox(width: 8),
                Text(
                  'Start Practice',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REUSABLE MICRO-COMPONENTS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? solarOrange.withValues(alpha: 0.18) : cardDark,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? solarOrange : borderDark,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildToggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white38, fontSize: 10.5),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          activeColor: solarOrange,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: highlight ? solarOrange.withValues(alpha: 0.15) : bgDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highlight ? solarOrange.withValues(alpha: 0.4) : borderDark,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: highlight ? solarOrange : Colors.white60,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: highlight ? solarOrange : Colors.white70,
              fontSize: 11,
              fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
