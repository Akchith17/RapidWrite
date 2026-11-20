import 'package:flutter/material.dart';
import '../models/aesthetic_evaluation.dart';
import '../models/algorithm_inspection_data.dart';

/// Modal dialog displaying transparent, step-by-step mathematical and geometric proof
/// of how the 5-Stage Adaptive Aesthetic Algorithm evaluated the student's handwriting.
class AlgorithmInspectionModal extends StatelessWidget {
  final AestheticEvaluation aesthetic;

  const AlgorithmInspectionModal({
    super.key,
    required this.aesthetic,
  });

  static Future<void> show(BuildContext context, AestheticEvaluation aesthetic) {
    final width = MediaQuery.of(context).size.width;
    if (width > 800) {
      // Desktop / Laptop: Show centered modal dialog
      return showDialog(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820, maxHeight: 860),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: AlgorithmInspectionModal(aesthetic: aesthetic),
            ),
          ),
        ),
      );
    } else {
      // Mobile / Tablet: Bottom sheet
      return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => AlgorithmInspectionModal(aesthetic: aesthetic),
      );
    }
  }

  // Brand Palette matching ResultsDashboard
  static const Color orangePrimary = Color(0xFFFF6B00);
  static const Color orangeDark = Color(0xFFEA580C);
  static const Color orangeBgSoft = Color(0xFFFFF7ED);
  static const Color orangeBorder = Color(0xFFFFD8BF);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final data = aesthetic.inspectionData;
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: isDesktop ? size.height * 0.88 : size.height * 0.92,
        maxWidth: 820,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: isDesktop
            ? BorderRadius.circular(24)
            : const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 28,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(context),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildVerificationBanner(),
                  const SizedBox(height: 16),
                  _buildStage1Card(data),
                  const SizedBox(height: 14),
                  _buildStage2Card(data),
                  const SizedBox(height: 14),
                  _buildStage3Card(data),
                  const SizedBox(height: 14),
                  _buildStage4Card(data),
                  const SizedBox(height: 14),
                  _buildStage5Card(data),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orangePrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'I Understand How My Score Was Derived',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
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
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
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
                child: const Icon(Icons.analytics_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aesthetic Algorithm Inspection',
                      style: TextStyle(
                        color: textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Transparent 5-stage mathematical verification of your writing',
                      style: TextStyle(color: textMuted, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: textMuted, size: 22),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_rounded, color: Color(0xFF059669), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '100% Genuine 5-Stage Adaptive Evaluation',
                  style: TextStyle(
                    color: Color(0xFF065F46),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Evaluated by ${aesthetic.evaluatedBy}. Your handwriting is assessed on intra-author consistency, baseline drift, and curvature fluidity — never penalizing natural personal slant or letter style.',
                  style: const TextStyle(color: Color(0xFF047857), fontSize: 11.5, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStage1Card(AlgorithmInspectionData? data) {
    final patternCount = data?.patterns.length ?? 0;
    return _StageContainer(
      stageNumber: 1,
      title: 'Repeated Letter & Stroke Pattern Analysis',
      subtitle: 'Measures consistency between repeated occurrences of the same letter',
      icon: Icons.repeat_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: orangeBgSoft,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: orangeBorder),
                ),
                child: Text(
                  '$patternCount repeated letter sets detected',
                  style: const TextStyle(color: orangeDark, fontSize: 11.5, fontWeight: FontWeight.bold),
                ),
              ),
              const Spacer(),
              Text(
                'Cohort: ${data?.ageCohort ?? "Standard"}',
                style: const TextStyle(color: textMuted, fontSize: 11),
              ),
            ],
          ),
          if (data != null && data.patterns.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: data.patterns.map((p) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 11,
                      backgroundColor: orangePrimary.withValues(alpha: 0.15),
                      child: Text(
                        p.letter,
                        style: const TextStyle(color: orangePrimary, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('×${p.occurrenceCount} occurrences', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        Text('h-var: ${p.heightMadPx}px • s-var: ${p.slantMadDeg}°', style: const TextStyle(fontSize: 9.5, color: textMuted)),
                      ],
                    ),
                  ],
                ),
              )).toList(),
            ),
          ] else ...[
            const SizedBox(height: 8),
            const Text(
              'No repeated letters detected in this short sample. Global stroke kinematics were utilized.',
              style: TextStyle(color: textMuted, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStage2Card(AlgorithmInspectionData? data) {
    if (data == null) return const SizedBox.shrink();

    return _StageContainer(
      stageNumber: 2,
      title: 'Extracted Geometric Feature Measurements',
      subtitle: 'Raw physical dimensions extracted from stylus vector coordinates',
      icon: Icons.straighten_rounded,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 480;
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildMetricTile('Median Height', '${data.medianHeightPx.toStringAsFixed(1)} px', 'MAD: ${data.heightMadPx.toStringAsFixed(1)} px (${data.heightVariationPct}% var)', isSmall),
              _buildMetricTile('Median Slant', '${data.medianSlantDeg.toStringAsFixed(1)}°', 'MAD: ${data.slantMadDeg.toStringAsFixed(1)}° angular stability', isSmall),
              _buildMetricTile('Letter Spacing', '${data.medianSpacingPx.toStringAsFixed(1)} px', 'MAD: ${data.spacingMadPx.toStringAsFixed(1)} px rhythm gap', isSmall),
              _buildMetricTile('Baseline Drift', '${data.baselineDriftPx.toStringAsFixed(1)} px', 'Linear regression residual fit', isSmall),
              _buildMetricTile('Curvature Smoothness', '${data.strokeSmoothnessPct.toStringAsFixed(1)}%', 'Low tremor & stroke fluency index', isSmall),
              _buildMetricTile('Total Strokes', '${data.totalStrokes}', '${data.estimatedGlyphs} estimated glyphs', isSmall),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, String sub, bool isSmall) {
    return Container(
      width: isSmall ? double.infinity : 220,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: orangeBgSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: orangeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: textMuted, fontSize: 10.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(color: textDark, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(color: orangeDark, fontSize: 9.5)),
        ],
      ),
    );
  }

  Widget _buildStage3Card(AlgorithmInspectionData? data) {
    final hasProf = data?.hasPersonalProfile ?? false;
    final tags = data?.personalStyleTags ?? aesthetic.personalStyleTags;

    return _StageContainer(
      stageNumber: 3,
      title: 'Personal Handwriting Reference Profile',
      subtitle: 'Constructs author-specific baseline to celebrate natural individual style',
      icon: Icons.person_pin_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasProf ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                color: hasProf ? const Color(0xFF16A34A) : orangePrimary,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                hasProf
                    ? 'Active Stored Personal Handwriting Profile'
                    : 'Calibrated from Current Session Baselines',
                style: TextStyle(
                  color: hasProf ? const Color(0xFF16A34A) : orangeDark,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'The algorithm registers your individual writing style (whether slanted, upright, tall, or compact) so you are judged only on consistency against yourself.',
            style: TextStyle(color: textMuted, fontSize: 11, height: 1.35),
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: tags.map((t) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: orangeBorder),
                ),
                child: Text(t, style: const TextStyle(color: orangeDark, fontSize: 10.5, fontWeight: FontWeight.w600)),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStage4Card(AlgorithmInspectionData? data) {
    final zeroPenalty = data?.zeroPenaltyApplied ?? true;
    final zH = data?.heightZScore ?? 0.0;
    final zS = data?.slantZScore ?? 0.0;
    final zSp = data?.spacingZScore ?? 0.0;

    return _StageContainer(
      stageNumber: 4,
      title: 'Deviation Analysis & Tolerance Interval Check',
      subtitle: 'Robust Z-score validation: deviations within |Z| ≤ 1.5 receive ZERO penalty',
      icon: Icons.tune_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: zeroPenalty ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: zeroPenalty ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  zeroPenalty ? Icons.verified_user_rounded : Icons.report_problem_outlined,
                  color: zeroPenalty ? const Color(0xFF059669) : const Color(0xFFD97706),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    zeroPenalty
                        ? 'Zero Penalty Applied: All deviations are within your natural |Z| ≤ 1.5 tolerance band.'
                        : 'Minor style drift detected outside tolerance interval (|Z| > 1.5).',
                    style: TextStyle(
                      color: zeroPenalty ? const Color(0xFF065F46) : const Color(0xFF92400E),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildZScorePill('Height Z-Score', zH),
              _buildZScorePill('Slant Z-Score', zS),
              _buildZScorePill('Spacing Z-Score', zSp),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildZScorePill(String title, double score) {
    final isWithin = score <= 1.5;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isWithin ? Colors.grey.shade100 : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isWithin ? Colors.grey.shade300 : const Color(0xFFFECACA)),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 10, color: textMuted)),
          Text(
            score.toStringAsFixed(2),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isWithin ? textDark : const Color(0xFFDC2626),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStage5Card(AlgorithmInspectionData? data) {
    return _StageContainer(
      stageNumber: 5,
      title: 'Multi-Dimensional Consistency Scoring',
      subtitle: 'Mathematical harmonic formula combining 6 validated scoring dimensions',
      icon: Icons.calculate_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mathematical Formula Box
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'EXACT HARMONIC FORMULA:',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 3),
                Text(
                  data?.formulaText ?? '0.22×Readability + 0.18×Formation + 0.18×Alignment + 0.16×Consistency + 0.14×Spacing + 0.12×Organisation',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    color: Color(0xFFF8FAFC),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Dimension Progress Bars
          _buildDimensionBar('Readability (Glyph Clarity & Scale)', aesthetic.readabilityScore, 0.22),
          const SizedBox(height: 8),
          _buildDimensionBar('Letter Formation (Uniformity)', aesthetic.letterFormationScore, 0.18),
          const SizedBox(height: 8),
          _buildDimensionBar('Alignment & Baseline Stability', aesthetic.alignmentScore, 0.18),
          const SizedBox(height: 8),
          _buildDimensionBar('Consistency (Intra-author Cadence)', aesthetic.consistencyScore, 0.16),
          const SizedBox(height: 8),
          _buildDimensionBar('Spacing (Word & Glyph Gap Rhythm)', aesthetic.spacingScore, 0.14),
          const SizedBox(height: 8),
          _buildDimensionBar('Visual Organisation (Page Balance)', aesthetic.visualOrganizationScore, 0.12),
          const SizedBox(height: 12),
          // Final Score Calculation Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [orangeBgSoft, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: orangePrimary, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('FINAL HARMONIC AESTHETIC SCORE', style: TextStyle(color: orangeDark, fontSize: 10, fontWeight: FontWeight.bold)),
                    Text(
                      '${aesthetic.overallAestheticScore.toStringAsFixed(1)} / 100',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textDark),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: orangePrimary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text('GRADE', style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold)),
                      Text(
                        aesthetic.grade,
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDimensionBar(String label, double score, double weight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textDark)),
            Text(
              '${score.toStringAsFixed(1)} / 100 • ${(weight * 100).toStringAsFixed(0)}% wt',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: orangeDark),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (score / 100.0).clamp(0.0, 1.0),
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              score >= 80 ? const Color(0xFF16A34A) : (score >= 65 ? orangePrimary : const Color(0xFFDC2626)),
            ),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

class _StageContainer extends StatelessWidget {
  final int stageNumber;
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  const _StageContainer({
    required this.stageNumber,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AlgorithmInspectionModal.orangePrimary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'STAGE $stageNumber',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AlgorithmInspectionModal.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(icon, color: AlgorithmInspectionModal.orangePrimary, size: 18),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(color: AlgorithmInspectionModal.textMuted, fontSize: 10.5),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
