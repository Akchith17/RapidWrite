import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/aesthetic_breakdown_model.dart';
import '../models/evaluation_result.dart';
import '../models/handwriting_stroke.dart';

enum BreakdownDisplayMode {
  all('All Annotations', Icons.layers_rounded),
  letterSize('Letter Size', Icons.straighten_rounded),
  slant('Slant', Icons.rotate_right_rounded),
  spacing('Spacing', Icons.space_bar_rounded),
  baseline('Baseline', Icons.horizontal_rule_rounded),
  outliers('Inconsistencies', Icons.warning_amber_rounded),
  original('Original Ink', Icons.brush_rounded);

  final String label;
  final IconData icon;
  const BreakdownDisplayMode(this.label, this.icon);
}

/// Comprehensive, interactive visual breakdown viewer.
/// Renders the student's actual handwritten ink strokes with verifiable geometric overlays,
/// allows interactive switching between measurement layers, and provides explainable
/// category score cards for all 5 handwriting dimensions.
class AestheticBreakdownViewer extends StatefulWidget {
  final EvaluationResult result;

  const AestheticBreakdownViewer({
    super.key,
    required this.result,
  });

  static Future<void> show(BuildContext context, EvaluationResult result) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AestheticBreakdownViewer(result: result),
    );
  }

  // Consistent Warm Solar Theme
  static const Color orangePrimary = Color(0xFFFF6B00);
  static const Color orangeDark    = Color(0xFFEA580C);
  static const Color orangeLight   = Color(0xFFFF8A3D);
  static const Color orangeBgSoft  = Color(0xFFFFF7ED);
  static const Color orangeBorder  = Color(0xFFFFD8BF);
  static const Color textDark      = Color(0xFF0F172A);
  static const Color textMuted     = Color(0xFF64748B);

  @override
  State<AestheticBreakdownViewer> createState() => _AestheticBreakdownViewerState();
}

class _AestheticBreakdownViewerState extends State<AestheticBreakdownViewer> {
  BreakdownDisplayMode _displayMode = BreakdownDisplayMode.all;
  LetterSegmentation? _selectedLetter;

  @override
  Widget build(BuildContext context) {
    final breakdown = widget.result.aestheticBreakdown;
    final strokes = widget.result.strokes ?? [];
    final size = MediaQuery.of(context).size;

    return Container(
      constraints: BoxConstraints(
        maxHeight: size.height * 0.92,
        maxWidth: 960,
      ),
      margin: EdgeInsets.only(
        top: 24,
        left: size.width > 980 ? (size.width - 960) / 2 : 0,
        right: size.width > 980 ? (size.width - 960) / 2 : 0,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 32,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag Handle & Header
          _buildHeader(context),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Scrollable Body
          Expanded(
            child: breakdown != null && strokes.isNotEmpty
                ? SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Sentence Target Banner
                        _buildSentenceTargetCard(breakdown),
                        const SizedBox(height: 14),

                        // Layer Switcher Buttons
                        _buildLayerSelector(),
                        const SizedBox(height: 12),

                        // Visual Annotation Handwriting Canvas
                        _buildInteractiveCanvas(strokes, breakdown),
                        const SizedBox(height: 10),

                        // Selected Letter Detail Pill (if clicked)
                        if (_selectedLetter != null) ...[
                          _buildSelectedLetterCard(_selectedLetter!),
                          const SizedBox(height: 14),
                        ],

                        // Canvas Legend & Helper
                        _buildCanvasLegend(),
                        const SizedBox(height: 18),

                        // The 5 Explainable Category Cards
                        const Text(
                          'DETAILED MEASUREMENT CATEGORIES',
                          style: TextStyle(
                            color: AestheticBreakdownViewer.orangeDark,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.9,
                          ),
                        ),
                        const SizedBox(height: 10),

                        _buildCategoryCard(
                          category: breakdown.letterSize,
                          icon: Icons.straighten_rounded,
                          accentColor: const Color(0xFF2563EB),
                          badge: '${breakdown.letterSize.score.toStringAsFixed(0)}/100',
                          extraDetails: [
                            'Median Height: ${(breakdown.letterSize.metrics['medianHeightPx'] as num?)?.toStringAsFixed(1) ?? 'N/A'}px',
                            'Variation MAD: ${(breakdown.letterSize.metrics['heightMadPx'] as num?)?.toStringAsFixed(1) ?? 'N/A'}px',
                            'Size Variance: ${(breakdown.letterSize.metrics['heightVariationPct'] as num?)?.toStringAsFixed(1) ?? 'N/A'}%',
                          ],
                        ),
                        const SizedBox(height: 12),

                        _buildCategoryCard(
                          category: breakdown.slant,
                          icon: Icons.rotate_right_rounded,
                          accentColor: const Color(0xFF7C3AED),
                          badge: '${breakdown.slant.score.toStringAsFixed(0)}/100',
                          extraDetails: [
                            'Natural Style: ${breakdown.slant.metrics['slantStyle'] ?? 'Upright'}',
                            'Angular MAD: ${(breakdown.slant.metrics['slantMadDeg'] as num?)?.toStringAsFixed(1) ?? 'N/A'}°',
                          ],
                        ),
                        const SizedBox(height: 12),

                        _buildCategoryCard(
                          category: breakdown.spacing,
                          icon: Icons.space_bar_rounded,
                          accentColor: const Color(0xFF059669),
                          badge: '${breakdown.spacing.score.toStringAsFixed(0)}/100',
                          extraDetails: [
                            'Letter Spacing: ${(breakdown.spacing.metrics['letterSpacingScore'] as num?)?.toStringAsFixed(0) ?? 'N/A'}/100',
                            'Word Spacing: ${(breakdown.spacing.metrics['wordSpacingScore'] as num?)?.toStringAsFixed(0) ?? 'N/A'}/100',
                            'Letter Gap: ${(breakdown.spacing.metrics['medianLetterGapPx'] as num?)?.toStringAsFixed(1) ?? 'N/A'}px',
                            'Word Gap: ${(breakdown.spacing.metrics['medianWordGapPx'] as num?)?.toStringAsFixed(1) ?? 'N/A'}px',
                          ],
                        ),
                        const SizedBox(height: 12),

                        _buildCategoryCard(
                          category: breakdown.baselineCategory,
                          icon: Icons.horizontal_rule_rounded,
                          accentColor: const Color(0xFFD97706),
                          badge: '${breakdown.baselineCategory.score.toStringAsFixed(0)}/100',
                          extraDetails: [
                            'Trajectory: ${breakdown.baselineCategory.metrics['trajectory'] ?? 'Level'}',
                            'Incline Angle: ${(breakdown.baselineCategory.metrics['angleDeg'] as num?)?.toStringAsFixed(1) ?? '0.0'}°',
                            'Drift MAD: ${(breakdown.baselineCategory.metrics['residualDriftPx'] as num?)?.toStringAsFixed(1) ?? 'N/A'}px',
                          ],
                        ),
                        const SizedBox(height: 12),

                        _buildCategoryCard(
                          category: breakdown.consistency,
                          icon: Icons.auto_awesome_rounded,
                          accentColor: AestheticBreakdownViewer.orangePrimary,
                          badge: '${breakdown.consistency.score.toStringAsFixed(0)}/100',
                          extraDetails: [
                            'Overall Aesthetic: ${breakdown.overallAestheticScore.toStringAsFixed(1)} / 100',
                            'Letter Grade: ${breakdown.grade}',
                            'Smoothness: ${(breakdown.consistency.metrics['smoothnessScore'] as num?)?.toStringAsFixed(0) ?? 'N/A'}%',
                            breakdown.hasPersonalProfile ? 'Personal Profile Active' : 'General Criteria',
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Close button
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AestheticBreakdownViewer.orangePrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Close Aesthetic Breakdown',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  )
                : _buildEmptyState(),
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
                    colors: [AestheticBreakdownViewer.orangePrimary, AestheticBreakdownViewer.orangeDark],
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
                      'Visual Aesthetic Breakdown',
                      style: TextStyle(
                        color: AestheticBreakdownViewer.textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Direct geometric overlays & measurements on your written strokes',
                      style: TextStyle(color: AestheticBreakdownViewer.textMuted, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AestheticBreakdownViewer.textMuted, size: 22),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSentenceTargetCard(AestheticBreakdown breakdown) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AestheticBreakdownViewer.orangeBgSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AestheticBreakdownViewer.orangeBorder, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.menu_book_rounded, color: AestheticBreakdownViewer.orangePrimary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ANALYZED TARGET SENTENCE:',
                  style: TextStyle(
                    color: AestheticBreakdownViewer.orangeDark,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  breakdown.targetSentence,
                  style: const TextStyle(
                    color: AestheticBreakdownViewer.textDark,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AestheticBreakdownViewer.orangePrimary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                const Text('SCORE', style: TextStyle(color: Colors.white70, fontSize: 8.5, fontWeight: FontWeight.bold)),
                Text(
                  '${breakdown.overallAestheticScore.toStringAsFixed(0)} (${breakdown.grade})',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayerSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: BreakdownDisplayMode.values.map((mode) {
          final isSelected = _displayMode == mode;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              avatar: Icon(
                mode.icon,
                size: 14,
                color: isSelected ? Colors.white : AestheticBreakdownViewer.textMuted,
              ),
              label: Text(
                mode.label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? Colors.white : AestheticBreakdownViewer.textDark,
                ),
              ),
              selected: isSelected,
              selectedColor: AestheticBreakdownViewer.orangePrimary,
              backgroundColor: Colors.grey.shade100,
              showCheckmark: false,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: isSelected ? AestheticBreakdownViewer.orangePrimary : Colors.grey.shade300,
                ),
              ),
              onSelected: (val) {
                if (val) {
                  setState(() => _displayMode = mode);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInteractiveCanvas(List<HandwritingStroke> strokes, AestheticBreakdown breakdown) {
    // Calculate bounding box of all strokes
    double minX = double.infinity, minY = double.infinity;
    double maxX = double.negativeInfinity, maxY = double.negativeInfinity;

    for (final s in strokes) {
      for (final p in s.points) {
        if (p.x < minX) minX = p.x;
        if (p.x > maxX) maxX = p.x;
        if (p.y < minY) minY = p.y;
        if (p.y > maxY) maxY = p.y;
      }
    }

    if (minX == double.infinity) {
      minX = 0;
      minY = 0;
      maxX = 300;
      maxY = 150;
    }

    final double contentWidth = math.max(320.0, (maxX - minX) + 60.0);
    final double contentHeight = math.max(160.0, (maxY - minY) + 60.0);
    final double padX = 30.0 - minX;
    final double padY = 30.0 - minY;

    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300, width: 1.2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InteractiveViewer(
          boundaryMargin: const EdgeInsets.all(40),
          minScale: 0.6,
          maxScale: 3.5,
          child: GestureDetector(
            onTapUp: (details) {
              final localPos = details.localPosition;
              // Map local tap to letter
              for (final letter in breakdown.letters) {
                final shiftedRect = letter.boundingBox.shift(Offset(padX, padY));
                if (shiftedRect.inflate(6).contains(localPos)) {
                  setState(() => _selectedLetter = letter);
                  return;
                }
              }
              setState(() => _selectedLetter = null);
            },
            child: CustomPaint(
              size: Size(contentWidth, contentHeight),
              painter: _BreakdownOverlayPainter(
                strokes: strokes,
                breakdown: breakdown,
                mode: _displayMode,
                shiftOffset: Offset(padX, padY),
                selectedLetter: _selectedLetter,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedLetterCard(LetterSegmentation letter) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AestheticBreakdownViewer.orangeBgSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AestheticBreakdownViewer.orangeBorder, width: 1.2),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AestheticBreakdownViewer.orangePrimary,
            child: Text(
              letter.char,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Letter "${letter.char}" Details',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: letter.hasAnyOutlier ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        letter.hasAnyOutlier ? 'Inconsistency Flagged' : 'Consistent',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: letter.hasAnyOutlier ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Size: ${letter.width.toStringAsFixed(1)}×${letter.height.toStringAsFixed(1)}px • Slant: ${letter.slantAngleDeg.toStringAsFixed(1)}° • Baseline Dev: ${letter.baselineDeviationPx > 0 ? "+" : ""}${letter.baselineDeviationPx.toStringAsFixed(1)}px',
                  style: const TextStyle(fontSize: 11, color: AestheticBreakdownViewer.textMuted),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            onPressed: () => setState(() => _selectedLetter = null),
          ),
        ],
      ),
    );
  }

  Widget _buildCanvasLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _LegendPill(color: Color(0xFF2563EB), label: 'Letter Bounding Box'),
          _LegendPill(color: Color(0xFF7C3AED), label: 'Slant Vector'),
          _LegendPill(color: Color(0xFFD97706), label: 'Fitted Baseline'),
          _LegendPill(color: Color(0xFFDC2626), label: 'Detected Outlier'),
        ],
      ),
    );
  }

  Widget _buildCategoryCard({
    required CategoryBreakdown category,
    required IconData icon,
    required Color accentColor,
    required String badge,
    required List<String> extraDetails,
  }) {
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
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentColor, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.categoryName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AestheticBreakdownViewer.textDark),
                    ),
                    Text(
                      'Confidence: ${(category.confidence * 100).toStringAsFixed(0)}% • ${category.isReliable ? "Verified measurement" : "Low confidence"}',
                      style: const TextStyle(fontSize: 10.5, color: AestheticBreakdownViewer.textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  badge,
                  style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Key Extra Metrics Pills
          if (extraDetails.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: extraDetails.map((d) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(d, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AestheticBreakdownViewer.textDark)),
              )).toList(),
            ),
            const SizedBox(height: 10),
          ],

          // What was measured & detected
          _buildDetailRow('What was measured:', category.whatWasMeasured),
          const SizedBox(height: 4),
          _buildDetailRow('What was detected:', category.whatWasDetected),
          const SizedBox(height: 6),

          // Affected regions
          if (category.affectedRegions.isNotEmpty) ...[
            const Text(
              'Regions affecting score:',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AestheticBreakdownViewer.orangeDark),
            ),
            const SizedBox(height: 2),
            ...category.affectedRegions.map((r) => Padding(
              padding: const EdgeInsets.only(left: 6, bottom: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: AestheticBreakdownViewer.orangePrimary, fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Text(
                      r,
                      style: const TextStyle(fontSize: 11, color: AestheticBreakdownViewer.textDark, height: 1.3),
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 6),
          ],

          // Coaching Suggestion Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AestheticBreakdownViewer.orangeBgSoft,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AestheticBreakdownViewer.orangeBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline_rounded, color: AestheticBreakdownViewer.orangePrimary, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    category.suggestion,
                    style: const TextStyle(color: AestheticBreakdownViewer.orangeDark, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String title, String content) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 11, color: AestheticBreakdownViewer.textDark, height: 1.3),
        children: [
          TextSpan(text: '$title ', style: const TextStyle(fontWeight: FontWeight.bold, color: AestheticBreakdownViewer.textMuted)),
          TextSpan(text: content),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.draw_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'No handwriting strokes available for visual breakdown.',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendPill extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendPill({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 9.5, color: AestheticBreakdownViewer.textMuted, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

/// CustomPainter rendering the student's actual handwritten ink strokes
/// along with selectable geometric visual annotation overlays.
class _BreakdownOverlayPainter extends CustomPainter {
  final List<HandwritingStroke> strokes;
  final AestheticBreakdown breakdown;
  final BreakdownDisplayMode mode;
  final Offset shiftOffset;
  final LetterSegmentation? selectedLetter;

  _BreakdownOverlayPainter({
    required this.strokes,
    required this.breakdown,
    required this.mode,
    required this.shiftOffset,
    this.selectedLetter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw student's actual handwriting ink strokes
    final strokePaint = Paint()
      ..color = const Color(0xFF1E293B) // Premium dark ink
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final s in strokes) {
      if (s.points.length < 2) continue;
      strokePaint.strokeWidth = math.max(1.8, s.strokeWidth);

      final path = Path();
      final p0 = s.points.first;
      path.moveTo(p0.x + shiftOffset.dx, p0.y + shiftOffset.dy);

      for (int i = 1; i < s.points.length; i++) {
        final p = s.points[i];
        path.lineTo(p.x + shiftOffset.dx, p.y + shiftOffset.dy);
      }
      canvas.drawPath(path, strokePaint);
    }

    if (mode == BreakdownDisplayMode.original) return;

    // 2. BASELINE OVERLAY
    if (mode == BreakdownDisplayMode.all ||
        mode == BreakdownDisplayMode.baseline ||
        mode == BreakdownDisplayMode.outliers) {
      _paintBaselineOverlay(canvas);
    }

    // 3. LETTER BOUNDING BOXES & LETTER SIZE OVERLAY
    if (mode == BreakdownDisplayMode.all ||
        mode == BreakdownDisplayMode.letterSize ||
        mode == BreakdownDisplayMode.outliers) {
      _paintLetterBoxesOverlay(canvas);
    }

    // 4. SLANT VECTORS OVERLAY
    if (mode == BreakdownDisplayMode.all ||
        mode == BreakdownDisplayMode.slant ||
        mode == BreakdownDisplayMode.outliers) {
      _paintSlantVectorsOverlay(canvas);
    }

    // 5. SPACING MEASUREMENTS OVERLAY
    if (mode == BreakdownDisplayMode.all ||
        mode == BreakdownDisplayMode.spacing ||
        mode == BreakdownDisplayMode.outliers) {
      _paintSpacingOverlay(canvas);
    }
  }

  void _paintBaselineOverlay(Canvas canvas) {
    final b = breakdown.baseline;
    final pStart = b.lineStart + shiftOffset;
    final pEnd = b.lineEnd + shiftOffset;

    final linePaint = Paint()
      ..color = const Color(0xFFD97706) // Amber baseline rule
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    // Draw baseline regression line
    canvas.drawLine(pStart, pEnd, linePaint);

    // Trajectory tag badge
    final tagPainter = TextPainter(
      text: TextSpan(
        text: ' Baseline: ${b.trajectoryName} ',
        style: const TextStyle(
          backgroundColor: Color(0xFFD97706),
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tagPainter.paint(canvas, Offset(pStart.dx, pStart.dy - 14));

    // Vertical deviation drops from letters to baseline
    final dropPaint = Paint()
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (final l in breakdown.letters) {
      final shifted = l.boundingBox.shift(shiftOffset);
      final letterContact = Offset(shifted.center.dx, shifted.bottom);
      final expectedY = b.expectedYAt(l.boundingBox.center.dx) + shiftOffset.dy;
      final baselinePoint = Offset(shifted.center.dx, expectedY);

      dropPaint.color = l.isBaselineOutlier ? const Color(0xFFDC2626) : const Color(0xFFF59E0B);
      canvas.drawLine(letterContact, baselinePoint, dropPaint);

      // Contact dot
      final dotPaint = Paint()
        ..color = dropPaint.color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(letterContact, 2.5, dotPaint);
    }
  }

  void _paintLetterBoxesOverlay(Canvas canvas) {
    final boxPaint = Paint()..style = PaintingStyle.stroke;

    for (final l in breakdown.letters) {
      if (mode == BreakdownDisplayMode.outliers && !l.hasAnyOutlier) continue;

      final shifted = l.boundingBox.shift(shiftOffset);
      final isSelected = selectedLetter == l;

      if (l.isHeightOutlier || (mode == BreakdownDisplayMode.outliers && l.hasAnyOutlier)) {
        boxPaint.color = const Color(0xFFDC2626); // Outlier Red
        boxPaint.strokeWidth = isSelected ? 2.5 : 1.6;
      } else {
        boxPaint.color = isSelected ? AestheticBreakdownViewer.orangePrimary : const Color(0xFF2563EB); // Blue
        boxPaint.strokeWidth = isSelected ? 2.5 : 1.2;
      }

      canvas.drawRRect(
        RRect.fromRectAndRadius(shifted, const Radius.circular(3)),
        boxPaint,
      );

      // Character & dimensions label
      final tp = TextPainter(
        text: TextSpan(
          text: '${l.char} (${l.height.round()}px)',
          style: TextStyle(
            color: boxPaint.color,
            fontSize: 8.5,
            fontWeight: FontWeight.bold,
            backgroundColor: Colors.white.withValues(alpha: 0.85),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(shifted.left, shifted.top - 11));
    }
  }

  void _paintSlantVectorsOverlay(Canvas canvas) {
    final slantPaint = Paint()
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    for (final l in breakdown.letters) {
      if (mode == BreakdownDisplayMode.outliers && !l.isSlantOutlier) continue;

      final shifted = l.boundingBox.shift(shiftOffset);
      final rad = l.slantAngleDeg * (math.pi / 180.0);
      final center = shifted.center;
      final len = shifted.height * 0.45;

      final dx = math.sin(rad) * len;
      final dy = math.cos(rad) * len;

      slantPaint.color = l.isSlantOutlier ? const Color(0xFFDC2626) : const Color(0xFF7C3AED); // Purple
      final p1 = Offset(center.dx - dx, center.dy - dy);
      final p2 = Offset(center.dx + dx, center.dy + dy);

      canvas.drawLine(p1, p2, slantPaint);

      // Slant angle indicator
      final tp = TextPainter(
        text: TextSpan(
          text: '${l.slantAngleDeg.round()}°',
          style: TextStyle(
            color: slantPaint.color,
            fontSize: 8.0,
            fontWeight: FontWeight.bold,
            backgroundColor: Colors.white.withValues(alpha: 0.85),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(p2.dx - 4, p2.dy + 1));
    }
  }

  void _paintSpacingOverlay(Canvas canvas) {
    final spacingPaint = Paint()
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    for (final s in breakdown.spacings) {
      if (mode == BreakdownDisplayMode.outliers && !s.isOutlier) continue;

      final p1 = s.startPoint + shiftOffset;
      final p2 = s.endPoint + shiftOffset;

      spacingPaint.color = s.isOutlier
          ? const Color(0xFFDC2626)
          : (s.isWordGap ? const Color(0xFF059669) : const Color(0xFF0284C7));

      // Draw horizontal bracket line
      canvas.drawLine(p1, p2, spacingPaint);

      // Bracket caps
      canvas.drawLine(Offset(p1.dx, p1.dy - 4), Offset(p1.dx, p1.dy + 4), spacingPaint);
      canvas.drawLine(Offset(p2.dx, p2.dy - 4), Offset(p2.dx, p2.dy + 4), spacingPaint);

      // Gap pixel dimension text
      final mid = Offset((p1.dx + p2.dx) / 2.0, (p1.dy + p2.dy) / 2.0);
      final tp = TextPainter(
        text: TextSpan(
          text: '${s.gapPx.round()}px',
          style: TextStyle(
            color: spacingPaint.color,
            fontSize: 8.0,
            fontWeight: FontWeight.bold,
            backgroundColor: Colors.white.withValues(alpha: 0.9),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(mid.dx - (tp.width / 2.0), mid.dy - 10));
    }
  }

  @override
  bool shouldRepaint(covariant _BreakdownOverlayPainter oldDelegate) {
    return oldDelegate.mode != mode ||
        oldDelegate.selectedLetter != selectedLetter ||
        oldDelegate.breakdown != breakdown;
  }
}
