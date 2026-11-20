import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/evaluation_result.dart';
import 'aesthetic_breakdown_viewer.dart';
import 'algorithm_inspection_modal.dart';

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
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: isDesktop ? size.height * 0.88 : size.height * 0.80,
        maxWidth: 720,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: isDesktop
            ? BorderRadius.circular(24)
            : const BorderRadius.vertical(top: Radius.circular(28)),
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

                  // 1.5 Target Speed Benchmark Comparison (Target WPM vs Actual)
                  if (result.targetWpm != null) ...[
                    _buildSpeedBenchmarkCard(),
                    const SizedBox(height: 14),
                  ],

                  // 2. Clean Target vs Written Text Comparison Card
                  _buildOcrComparisonCard(),
                  const SizedBox(height: 14),

                  // 3. Full 7-Dimension Aesthetic Breakdown
                  _buildAestheticBreakdown(context),
                  const SizedBox(height: 14),

                  // 4. Personal Style Tags & Shift Observations (if available)
                  if (result.aesthetic.hasPersonalReference ||
                      result.aesthetic.personalStyleTags.isNotEmpty ||
                      result.aesthetic.styleShiftObservations.isNotEmpty) ...[
                    _buildPersonalReferenceCard(),
                    const SizedBox(height: 14),
                  ],

                  // 5. Personalized Coaching Tips
                  if (result.aesthetic.coachingTips.isNotEmpty)
                    _buildCoachingTipCard(),

                  const SizedBox(height: 18),

                  // 6. Action Buttons (Practice Next / Close)
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
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    child: Material(
                      color: orangePrimary.withValues(alpha: 0.12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: orangePrimary.withValues(alpha: 0.4)),
                      ),
                      child: InkWell(
                        onTap: () => AestheticBreakdownViewer.show(context, result),
                        borderRadius: BorderRadius.circular(20),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.analytics_rounded, size: 14, color: orangePrimary),
                              SizedBox(width: 4),
                              Text(
                                'View Breakdown',
                                style: TextStyle(
                                  color: orangeDark,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
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
          subtitle: 'Grade ${result.aesthetic.grade} • Tap for Visual Breakdown',
          isHighlighted: false,
          onTap: () => AestheticBreakdownViewer.show(context, result),
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

  /// Target Speed Benchmark Card comparing target WPM against student's actual net WPM
  Widget _buildSpeedBenchmarkCard() {
    if (result.targetWpm == null) return const SizedBox.shrink();
    final targetWpm = result.targetWpm!;
    final actualWpm = result.netWpm;
    final deltaWpm = actualWpm - targetWpm;
    final isAhead = deltaWpm >= 0;
    final activeSec = result.metrics.activeDrawingTimeMs / 1000.0;
    final recSec = result.recommendedDurationSec;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: orangeBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: orangePrimary.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.speed_rounded, color: orangePrimary, size: 16),
              const SizedBox(width: 6),
              const Text(
                'TARGET SPEED BENCHMARK',
                style: TextStyle(
                  color: orangeDark,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isAhead ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isAhead ? const Color(0xFF4ADE80) : const Color(0xFFFBBF24),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isAhead ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                      size: 11,
                      color: isAhead ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      isAhead
                          ? '+${deltaWpm.toStringAsFixed(1)} WPM ahead'
                          : '${deltaWpm.abs().toStringAsFixed(1)} WPM below target',
                      style: TextStyle(
                        color: isAhead ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            alignment: WrapAlignment.spaceAround,
            children: [
              _buildBenchmarkItem('Target WPM', '$targetWpm WPM', Icons.flag_outlined),
              _buildBenchmarkItem('Actual Net Speed', '${actualWpm.toStringAsFixed(1)} WPM', Icons.speed_rounded),
              if (recSec != null)
                _buildBenchmarkItem(
                  'Recommended Time',
                  '${recSec.round()}s',
                  Icons.hourglass_top_rounded,
                ),
              _buildBenchmarkItem(
                'Actual Time',
                '${activeSec.toStringAsFixed(1)}s',
                Icons.timer_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBenchmarkItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: orangeBgSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: orangePrimary),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: const TextStyle(color: textMuted, fontSize: 9.5, fontWeight: FontWeight.w600)),
              Text(value, style: const TextStyle(color: textDark, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
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

  /// Full 7-dimension aesthetic breakdown replacing the old 3-bar section.
  Widget _buildAestheticBreakdown(BuildContext context) {
    final a = result.aesthetic;
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
          Row(
            children: [
              const Text(
                'AESTHETIC BREAKDOWN',
                style: TextStyle(
                  color: textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              if (a.hasPersonalReference)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF4ADE80), width: 1),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_rounded, color: Color(0xFF16A34A), size: 11),
                      SizedBox(width: 3),
                      Text(
                        'Personalised',
                        style: TextStyle(color: Color(0xFF16A34A), fontSize: 10, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'General Assessment',
                    style: TextStyle(color: textMuted, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _ProgressBarRow(label: 'Readability', score: a.readabilityScore),
          const SizedBox(height: 10),
          _ProgressBarRow(label: 'Letter Formation', score: a.letterFormationScore),
          const SizedBox(height: 10),
          _ProgressBarRow(label: 'Spacing', score: a.spacingScore),
          const SizedBox(height: 10),
          _ProgressBarRow(label: 'Alignment & Baseline', score: a.alignmentScore),
          const SizedBox(height: 10),
          _ProgressBarRow(label: 'Consistency', score: a.consistencyScore),
          const SizedBox(height: 10),
          _ProgressBarRow(label: 'Visual Organisation', score: a.visualOrganizationScore),
          const SizedBox(height: 10),
          _ProgressBarRow(label: 'Stroke Smoothness', score: a.strokeSmoothnessScore),
          const SizedBox(height: 16),

          // Primary Visual Aesthetic Breakdown Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => AestheticBreakdownViewer.show(context, result),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [orangePrimary, orangeDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: orangePrimary.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.draw_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Aesthetic Breakdown (Visual Letter, Slant & Spacing Analysis)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Secondary Inspection Button
          InkWell(
            onTap: () => AlgorithmInspectionModal.show(context, a),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: orangeBgSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: orangeBorder, width: 1.0),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calculate_outlined, color: orangePrimary, size: 15),
                  SizedBox(width: 6),
                  Text(
                    'Inspect Mathematical Formula & Algorithm Profile',
                    style: TextStyle(
                      color: orangeDark,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Personal style tags and shift observations card.
  Widget _buildPersonalReferenceCard() {
    final a = result.aesthetic;
    final hasTags = a.personalStyleTags.isNotEmpty;
    final hasShifts = a.styleShiftObservations.isNotEmpty;
    if (!hasTags && !hasShifts) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: orangeBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasTags) ...[
            const Text(
              'YOUR WRITING STYLE',
              style: TextStyle(
                color: orangeDark,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.7,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: a.personalStyleTags.map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: orangePrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: orangeBorder),
                ),
                child: Text(tag, style: const TextStyle(color: orangeDark, fontSize: 11, fontWeight: FontWeight.w600)),
              )).toList(),
            ),
          ],
          if (hasTags && hasShifts) const SizedBox(height: 10),
          if (hasShifts) ...[
            const Text(
              'SESSION OBSERVATIONS',
              style: TextStyle(
                color: orangeDark,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.7,
              ),
            ),
            const SizedBox(height: 6),
            ...a.styleShiftObservations.map((obs) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.arrow_right_rounded, color: orangePrimary, size: 16),
                  const SizedBox(width: 4),
                  Expanded(child: Text(obs, style: const TextStyle(color: textDark, fontSize: 11.5))),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildCoachingTipCard() {
    final tip = result.aesthetic.coachingTips.isNotEmpty
        ? result.aesthetic.coachingTips.first
        : 'Maintain steady stroke rhythm and relaxed grip.';

    String? pacingTip;
    if (result.targetWpm != null) {
      final target = result.targetWpm!;
      final actual = result.netWpm;
      if (actual > target * 1.25 && result.characterAccuracy < 88.0) {
        pacingTip = 'You reached ${actual.toStringAsFixed(1)} WPM (target was $target WPM), but accuracy dropped. Slow down slightly to steady your letter formation.';
      } else if (actual < target * 0.75 && result.characterAccuracy >= 94.0) {
        pacingTip = 'Your accuracy is superb (${result.characterAccuracy.toStringAsFixed(0)}%). With this solid control, gently increase writing cadence toward your $target WPM target.';
      } else if ((actual - target).abs() <= target * 0.20) {
        pacingTip = 'Splendid pacing! Your speed (${actual.toStringAsFixed(1)} WPM) closely aligns with your $target WPM target.';
      }
    }

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lightbulb_outline_rounded, color: orangePrimary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Personalized Coaching & Pacing Tip',
                      style: TextStyle(color: orangeDark, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      tip,
                      style: const TextStyle(color: textDark, fontSize: 13, height: 1.3),
                    ),
                    if (pacingTip != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        pacingTip,
                        style: const TextStyle(color: orangeDark, fontSize: 12, fontStyle: FontStyle.italic, height: 1.3),
                      ),
                    ],
                  ],
                ),
              ),
            ],
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
  final VoidCallback? onTap;

  const _MetricBox({
    required this.icon,
    required this.title,
    required this.value,
    required this.unit,
    required this.subtitle,
    required this.isHighlighted,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final box = Container(
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

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: box,
        ),
      );
    }
    return box;
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
