import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Animated circular gauge for aesthetic and neatness score displays.
class CircularScoreGauge extends StatelessWidget {
  final double score; // 0 - 100
  final String label;
  final String? subtitle;
  final double size;
  final Color? color;

  const CircularScoreGauge({
    super.key,
    required this.score,
    required this.label,
    this.subtitle,
    this.size = 140.0,
    this.color,
  });

  Color _resolveColor(double val) {
    if (color != null) return color!;
    if (val >= 90) return AppTheme.success;
    if (val >= 78) return AppTheme.primaryLight;
    if (val >= 65) return AppTheme.accent;
    return AppTheme.error;
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = _resolveColor(score);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _CircularGaugePainter(
              value: score / 100.0,
              strokeWidth: 10.0,
              progressColor: activeColor,
              backgroundColor: AppTheme.bgDark.withOpacity(0.5),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                score.toStringAsFixed(0),
                style: TextStyle(
                  fontSize: size * 0.28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: size * 0.085,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: size * 0.075,
                    color: activeColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _CircularGaugePainter extends CustomPainter {
  final double value;
  final double strokeWidth;
  final Color progressColor;
  final Color backgroundColor;

  _CircularGaugePainter({
    required this.value,
    required this.strokeWidth,
    required this.progressColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Draw background track
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Draw active arc with neon glow
    final sweepAngle = 2 * math.pi * value.clamp(0.0, 1.0);
    if (sweepAngle > 0.01) {
      final glowPaint = Paint()
        ..color = progressColor.withOpacity(0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 6.0
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        glowPaint,
      );
    }

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularGaugePainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.progressColor != progressColor;
  }
}

/// Linear metric bar for horizontal breakdown metrics.
class LinearMetricBar extends StatelessWidget {
  final String label;
  final double value; // 0 - 100
  final String? displayValue;
  final Color? barColor;

  const LinearMetricBar({
    super.key,
    required this.label,
    required this.value,
    this.displayValue,
    this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = barColor ?? AppTheme.primaryLight;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              displayValue ?? '${value.toStringAsFixed(1)}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: (value / 100.0).clamp(0.0, 1.0),
            backgroundColor: AppTheme.bgDark.withOpacity(0.6),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
