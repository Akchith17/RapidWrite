import 'package:flutter/material.dart';

enum PaperStyle {
  ruled,
  dottedGrid,
  blank,
}

/// Custom painter for rendering tablet notebook guidelines and digital paper texture.
class CanvasBackgroundPainter extends CustomPainter {
  final PaperStyle paperStyle;
  final double lineSpacing;
  final Color lineColor;
  final Color marginColor;

  CanvasBackgroundPainter({
    this.paperStyle = PaperStyle.ruled,
    this.lineSpacing = 42.0,
    this.lineColor = const Color(0xFFE2E8F0),
    this.marginColor = const Color(0xFFFCA5A5),
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (paperStyle == PaperStyle.blank) return;

    if (paperStyle == PaperStyle.ruled) {
      _paintRuledLines(canvas, size);
    } else if (paperStyle == PaperStyle.dottedGrid) {
      _paintDottedGrid(canvas, size);
    }
  }

  void _paintRuledLines(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.0;

    final baselinePaint = Paint()
      ..color = lineColor.withOpacity(0.4)
      ..strokeWidth = 0.8;

    // Draw horizontal notebook lines
    final startY = lineSpacing * 1.5;
    for (double y = startY; y < size.height; y += lineSpacing) {
      // Main baseline
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);

      // Mid-line (x-height guide for handwriting alignment)
      final midY = y - (lineSpacing * 0.45);
      if (midY > 0) {
        _drawDashedLine(canvas, Offset(0, midY), Offset(size.width, midY), baselinePaint);
      }
    }

    // Left tablet margin guide
    final marginX = 64.0;
    final marginPaint = Paint()
      ..color = marginColor.withOpacity(0.5)
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(marginX, 0), Offset(marginX, size.height), marginPaint);
  }

  void _paintDottedGrid(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    const spacing = 28.0;
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashWidth = 5.0;
    const dashSpace = 4.0;
    double startX = p1.dx;
    final y = p1.dy;

    while (startX < p2.dx) {
      canvas.drawLine(
        Offset(startX, y),
        Offset((startX + dashWidth).clamp(p1.dx, p2.dx), y),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CanvasBackgroundPainter oldDelegate) {
    return oldDelegate.paperStyle != paperStyle ||
        oldDelegate.lineSpacing != lineSpacing ||
        oldDelegate.lineColor != lineColor;
  }
}
