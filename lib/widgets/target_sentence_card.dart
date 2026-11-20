import 'package:flutter/material.dart';
import '../models/practice_settings.dart';
import '../models/target_sentence_model.dart';
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

/// Tablet, Mobile & Desktop adaptive Target Sentence Display Card.
/// Houses the clear target sentence display, adaptive pacing indicators,
/// the reliable sentence Shuffle button, and the SINGLE unified Practice Settings button.
class TargetSentenceCard extends StatefulWidget {
  final String targetSentence;
  final bool hasStartedWriting;
  final int activeStrokeCount;
  final ValueChanged<String> onSentenceChanged;
  final TargetSentenceModel? sentenceModel;
  final PracticeSettings? settings;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onRegenerate;

  const TargetSentenceCard({
    super.key,
    required this.targetSentence,
    required this.hasStartedWriting,
    required this.activeStrokeCount,
    required this.onSentenceChanged,
    this.sentenceModel,
    this.settings,
    this.onOpenSettings,
    this.onRegenerate,
  });

  @override
  State<TargetSentenceCard> createState() => _TargetSentenceCardState();
}

class _TargetSentenceCardState extends State<TargetSentenceCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Header: Badge, Word Count & Stylus Stroke Indicator ─────────────
            Row(
              children: [
                // Icon badge with glow
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.mode_edit_outline_rounded, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 10),

                // Title
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [AppTheme.primaryLight, AppTheme.secondary],
                  ).createShader(bounds),
                  child: const Text(
                    'TARGET PRACTICE SENTENCE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Word & Char Count Chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$wordCount words • $charCount chars',
                    style: const TextStyle(color: Colors.white54, fontSize: 10.5),
                  ),
                ),

                const Spacer(),

                // Live stylus timing indicator dot
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
                          : 'Ready',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: widget.hasStartedWriting ? AppTheme.success : AppTheme.accent,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ─── Target Sentence Text Display ──────────────────────────────────
            SelectableText(
              widget.targetSentence,
              style: const TextStyle(
                fontSize: 17.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.25,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 12),

            // ─── Footer: Sentence Metrics Badges & Action Buttons ──────────────
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 640;

                final badges = Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (widget.sentenceModel != null) ...[
                      _buildInfoBadge(Icons.speed_rounded, '${widget.sentenceModel!.targetWpm} WPM target', highlight: true),
                      _buildInfoBadge(Icons.timer_outlined, 'Rec: ${widget.sentenceModel!.formattedDuration}', highlight: true),
                      _buildInfoBadge(Icons.grade_outlined, widget.sentenceModel!.difficulty.label),
                      ...widget.sentenceModel!.categoriesPresent.map((c) => _buildInfoBadge(Icons.check_rounded, c)),
                    ] else if (widget.settings != null) ...[
                      _buildInfoBadge(Icons.speed_rounded, '${widget.settings!.targetWpm} WPM target', highlight: true),
                      _buildInfoBadge(Icons.grade_outlined, widget.settings!.difficulty.label),
                    ],
                  ],
                );

                final actionButtons = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. Shuffle Button
                    Material(
                      color: Colors.white.withValues(alpha: 0.06),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                      ),
                      child: InkWell(
                        onTap: () {
                          _spinController.forward(from: 0.0);
                          widget.onRegenerate?.call();
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              RotationTransition(
                                turns: _spinController,
                                child: const Icon(
                                  Icons.refresh_rounded,
                                  size: 15,
                                  color: AppTheme.secondary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Shuffle',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // 2. THE ONE UNIFIED "Practice Settings" Button
                    if (widget.onOpenSettings != null)
                      Material(
                        color: const Color(0xFFFF6B00).withValues(alpha: 0.18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: Color(0xFFFF6B00), width: 1.2),
                        ),
                        child: InkWell(
                          onTap: widget.onOpenSettings,
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.tune_rounded, size: 14, color: Color(0xFFFF8A3D)),
                                const SizedBox(width: 6),
                                const Text(
                                  'Practice Settings',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (widget.settings != null) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF6B00),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${widget.settings!.targetWpm} WPM',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                );

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      badges,
                      const SizedBox(height: 10),
                      actionButtons,
                    ],
                  );
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: badges),
                    const SizedBox(width: 12),
                    actionButtons,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String label, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: highlight
            ? const Color(0xFFFF6B00).withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: highlight
              ? const Color(0xFFFF6B00).withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 11,
            color: highlight ? const Color(0xFFFF8A3D) : Colors.white60,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: highlight ? const Color(0xFFFF8A3D) : Colors.white70,
              fontSize: 10.5,
              fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
