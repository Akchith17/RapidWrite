import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/evaluation_result.dart';

/// Clean, compact handwriting evaluation dashboard in a radiant Orange & White theme,
/// focusing on the core essential metrics without screen-overwhelming clutter.
class ResultsDashboard extends StatelessWidget {
  final EvaluationResult result;
  final VoidCallback onDismiss;
  final VoidCallback onRetry;

  const ResultsDashboard({
    super.key,
    required this.result,
    required this.onDismiss,
    required this.onRetry,
  });

  // ─── Orange & White Theme Tokens ──────────────────────────────────────────
  static const Color orangePrimary = Color(0xFFFF6B00); // Radiant Solar Orange
  static const Color orangeDark    = Color(0xFFEA580C); // Deep Orange
  static const Color orangeLight   = Color(0xFFFF8A3D); // Warm Tangerine
  static const Color orangeBgSoft  = Color(0xFFFFF7ED); // Soft Creamsicle
  static const Color orangeBorder  = Color(0xFFFFD8BF); // Delicate Orange Border
  static const Color textDark      = Color(0xFF0F172A); // High-contrast Charcoal
  static const Color textMuted     = Color(0xFF64748B); // Slate Gray

  void _shareResults() {
    final summary = '''
RAPID WRITE Assessment
------------------------------------
Target: "${result.targetSentence}"
Written: "${result.recognizedText}"
• Net Speed: ${result.netWpm.toStringAsFixed(1)} WPM (Gross: ${result.grossWpm.toStringAsFixed(1)} WPM)
• Accuracy: ${result.characterAccuracy.toStringAsFixed(1)}% (${result.errorCount} errors)
• Aesthetic: ${result.aesthetic.overallAestheticScore.toStringAsFixed(0)} / 100 (Grade ${result.aesthetic.grade})
• Neatness: ${result.aesthetic.neatnessScore.toStringAsFixed(0)}%
• Active Time: ${(result.metrics.activeDrawingTimeMs / 1000).toStringAsFixed(1)}s
''';

    if (!kIsWeb && result.screenshotPath != null && File(result.screenshotPath!).existsSync()) {
      SharePlus.instance.share(
        ShareParams(
          files: [XFile(result.screenshotPath!)],
          text: summary,
          subject: 'Handwriting Assessment Report',
        ),
      );
    } else {
      SharePlus.instance.share(
        ShareParams(
          text: summary,
          subject: 'Handwriting Assessment Report',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.78,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: orangeBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: orangePrimary.withValues(alpha: 0.12),
            blurRadius: 32,
            offset: const Offset(0, -8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle & Header Bar
          _buildHeader(context),

          // Scrollable Body
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Top 3 Hero Metric Cards (Speed, Accuracy, Aesthetic)
                  _buildHeroCards(context),
                  const SizedBox(height: 14),

                  // 2. Clean Target vs Written Text Comparison Card
                  _buildOcrComparisonCard(),
                  const SizedBox(height: 14),

                  // 3. Calligraphy Geometry Indicators (Baseline, Slant, Smoothness)
                  _buildGeometryBars(),
                  const SizedBox(height: 14),

                  // 4. Personalized Coaching Tip
                  if (result.aesthetic.coachingTips.isNotEmpty)
                    _buildCoachingTipCard(),

                  const SizedBox(height: 18),

                  // 5. Action Buttons (Practice Next / Close)
                  _buildActionButtons(context),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 16, top: 12, bottom: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Subtle drag handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Orange Header Pill Badge
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [orangePrimary, orangeDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Handwriting Evaluation',
                        style: TextStyle(
                          color: textDark,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Instant Stylus Speed & Aesthetic Insights',
                        style: TextStyle(color: textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),

              // Action Buttons
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.share_outlined, color: orangePrimary, size: 20),
                    tooltip: 'Share Report',
                    onPressed: _shareResults,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: textMuted, size: 22),
                    tooltip: 'Close',
                    onPressed: onDismiss,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCards(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 580;
        final cardWidth = isSmall ? constraints.maxWidth : (constraints.maxWidth - 20) / 3;

        final cardSpeed = _MetricBox(
          icon: Icons.electric_bolt_rounded,
          title: 'ACTUAL SPEED',
          value: result.netWpm.toStringAsFixed(1),
          unit: 'WPM',
          subtitle: 'Gross ${result.grossWpm.toStringAsFixed(1)} • ${(result.metrics.activeDrawingTimeMs / 1000).toStringAsFixed(1)}s active',
          isHighlighted: true,
        );

        final cardAccuracy = _MetricBox(
          icon: Icons.check_circle_outline_rounded,
          title: 'ACCURACY',
          value: result.characterAccuracy.toStringAsFixed(0),
          unit: '%',
          subtitle: '${result.errorCount} error deductions • ${result.wordAccuracy.toStringAsFixed(0)}% word match',
          isHighlighted: false,
        );

        final cardAesthetic = _MetricBox(
          icon: Icons.draw_rounded,
          title: 'AESTHETIC',
          value: result.aesthetic.overallAestheticScore.toStringAsFixed(0),
          unit: '/ 100',
          subtitle: 'Grade ${result.aesthetic.grade} • Neatness ${result.aesthetic.neatnessScore.toStringAsFixed(0)}%',
          isHighlighted: false,
        );

        if (isSmall) {
          return Column(
            children: [
              cardSpeed,
              const SizedBox(height: 8),
              cardAccuracy,
              const SizedBox(height: 8),
              cardAesthetic,
            ],
          );
        }

        return Row(
          children: [
            SizedBox(width: cardWidth, child: cardSpeed),
            const SizedBox(width: 10),
            SizedBox(width: cardWidth, child: cardAccuracy),
            const SizedBox(width: 10),
            SizedBox(width: cardWidth, child: cardAesthetic),
          ],
        );
      },
    );
  }

  Widget _buildOcrComparisonCard() {
    final bool isExactMatch = result.characterAccuracy >= 95.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: orangeBgSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: orangeBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.text_fields_rounded, color: orangePrimary, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'TEXT RECOGNITION COMPARISON',
                    style: TextStyle(
                      color: orangeDark,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isExactMatch ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isExactMatch ? '✓ Verified Match' : '${result.characterAccuracy.toStringAsFixed(0)}% Match',
                  style: TextStyle(
                    color: isExactMatch ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Target sentence
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                width: 75,
                child: Text('Target:', style: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
              Expanded(
                child: Text(
                  result.targetSentence,
                  style: const TextStyle(color: textDark, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Recognized text
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                width: 75,
                child: Text('Written:', style: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
              Expanded(
                child: Text(
                  result.recognizedText.isNotEmpty
                      ? result.recognizedText
                      : '(Strokes registered • local computer vision evaluation applied)',
                  style: TextStyle(
                    color: result.recognizedText.isNotEmpty ? orangePrimary : textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGeometryBars() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CALLIGRAPHY & NEATNESS BREAKDOWN',
            style: TextStyle(
              color: textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          _ProgressBarRow(
            label: 'Baseline Straightness',
            score: result.aesthetic.baselineAlignmentScore,
          ),
          const SizedBox(height: 10),
          _ProgressBarRow(
            label: 'Slant Angle Consistency',
            score: result.aesthetic.slantConsistencyScore,
          ),
          const SizedBox(height: 10),
          _ProgressBarRow(
            label: 'Stroke Smoothness & Curvature',
            score: result.aesthetic.strokeSmoothnessScore,
          ),
        ],
      ),
    );
  }

  Widget _buildCoachingTipCard() {
    final tip = result.aesthetic.coachingTips.first;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: orangeBgSoft,
        borderRadius: BorderRadius.circular(14),
        border: const Border(
          left: BorderSide(color: orangePrimary, width: 4.0),
          top: BorderSide(color: orangeBorder, width: 0.8),
          right: BorderSide(color: orangeBorder, width: 0.8),
          bottom: BorderSide(color: orangeBorder, width: 0.8),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline_rounded, color: orangePrimary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Coaching Tip',
                  style: TextStyle(color: orangeDark, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 3),
                Text(
                  tip,
                  style: const TextStyle(color: textDark, fontSize: 13, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [orangePrimary, orangeDark],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: orangePrimary.withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onRetry,
          borderRadius: BorderRadius.circular(14),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'Practice Next Sentence',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String unit;
  final String subtitle;
  final bool isHighlighted;

  const _MetricBox({
    required this.icon,
    required this.title,
    required this.value,
    required this.unit,
    required this.subtitle,
    required this.isHighlighted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isHighlighted ? ResultsDashboard.orangeBgSoft : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlighted ? ResultsDashboard.orangePrimary : Colors.grey.shade200,
          width: isHighlighted ? 1.5 : 1.2,
        ),
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: ResultsDashboard.orangePrimary.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: isHighlighted ? ResultsDashboard.orangePrimary : ResultsDashboard.textMuted,
                size: 15,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: isHighlighted ? ResultsDashboard.orangeDark : ResultsDashboard.textMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: ResultsDashboard.textDark,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(
                  color: ResultsDashboard.orangePrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: ResultsDashboard.textMuted,
              fontSize: 10.5,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ProgressBarRow extends StatelessWidget {
  final String label;
  final double score;

  const _ProgressBarRow({
    required this.label,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = (score / 100.0).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: ResultsDashboard.textDark, fontSize: 12, fontWeight: FontWeight.w600)),
            Text('${score.toStringAsFixed(0)}%', style: const TextStyle(color: ResultsDashboard.orangePrimary, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: clamped,
            minHeight: 6,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: const AlwaysStoppedAnimation<Color>(ResultsDashboard.orangePrimary),
          ),
        ),
      ],
    );
  }
}
