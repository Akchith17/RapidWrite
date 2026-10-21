import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import '../models/handwriting_stroke.dart';
import '../models/stroke_point.dart';
import '../theme/app_theme.dart';
import 'canvas_background_painter.dart';

/// Fixed Static Tablet Drawing Canvas:
/// - Completely STATIC note: Cannot be scrolled or moved while writing.
/// - Apple Pencil / Stylus: Writes strokes with pressure modulation, tilt, and smoothing.
/// - Palm Guard (strictStylusMode): Rejects accidental touch/palm input when enabled.
/// - Zero scrolling, zero page movement, perfectly rock-solid handwriting experience.
class DrawingCanvas extends StatefulWidget {
  final ScreenshotController screenshotController;
  final ValueChanged<int>? onFirstStrokeDown;
  final ValueChanged<List<HandwritingStroke>>? onStrokesChanged;
  final Color inkColor;
  final double strokeWidth;
  final bool isEraser;
  final bool strictStylusMode;
  final PaperStyle paperStyle;

  const DrawingCanvas({
    super.key,
    required this.screenshotController,
    this.onFirstStrokeDown,
    this.onStrokesChanged,
    this.inkColor = AppTheme.inkMidnight,
    this.strokeWidth = 3.0,
    this.isEraser = false,
    this.strictStylusMode = true,
    this.paperStyle = PaperStyle.ruled,
  });

  @override
  State<DrawingCanvas> createState() => DrawingCanvasState();
}

class DrawingCanvasState extends State<DrawingCanvas> {
  final List<HandwritingStroke> _strokes = [];
  final List<HandwritingStroke> _redoStack = [];
  HandwritingStroke? _currentStroke;
  bool _hasStartedWriting = false;

  List<HandwritingStroke> get strokes => List.unmodifiable(_strokes);
  bool get canUndo => _strokes.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void undo() {
    if (_strokes.isNotEmpty) {
      setState(() {
        _redoStack.add(_strokes.removeLast());
      });
      widget.onStrokesChanged?.call(_strokes);
    }
  }

  void redo() {
    if (_redoStack.isNotEmpty) {
      setState(() {
        _strokes.add(_redoStack.removeLast());
      });
      widget.onStrokesChanged?.call(_strokes);
    }
  }

  void clearCanvas() {
    setState(() {
      _strokes.clear();
      _redoStack.clear();
      _currentStroke = null;
      _hasStartedWriting = false;
    });
    widget.onStrokesChanged?.call(_strokes);
  }

  /// High-resolution offscreen capture of the complete written area on the static note.
  Future<Uint8List?> captureFullCanvas({double pixelRatio = 2.0}) async {
    if (_strokes.isEmpty) return null;

    double minX = double.infinity, minY = double.infinity;
    double maxX = 0, maxY = 0;

    for (final s in _strokes) {
      for (final p in s.points) {
        if (p.x < minX) minX = p.x;
        if (p.y < minY) minY = p.y;
        if (p.x > maxX) maxX = p.x;
        if (p.y > maxY) maxY = p.y;
      }
    }

    minX = (minX - 40).clamp(0.0, double.infinity);
    minY = (minY - 40).clamp(0.0, double.infinity);
    maxX = maxX + 40;
    maxY = maxY + 40;

    final width = (maxX - minX).clamp(400.0, 3000.0);
    final height = (maxY - minY).clamp(300.0, 3000.0);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height));

    // Fill ivory paper background
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), Paint()..color = AppTheme.paperIvory);

    // Draw background paper lines
    canvas.save();
    canvas.translate(-minX, -minY);
    final bgPainter = CanvasBackgroundPainter(paperStyle: widget.paperStyle);
    bgPainter.paint(canvas, Size(maxX + 100, maxY + 100));

    // Draw all handwriting strokes
    final strokePainter = _HandwritingPainter(strokes: _strokes);
    strokePainter.paint(canvas, Size(maxX + 100, maxY + 100));
    canvas.restore();

    final picture = recorder.endRecording();
    final img = await picture.toImage((width * pixelRatio).toInt(), (height * pixelRatio).toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  void _handlePointerDown(PointerDownEvent event) {
    // If strictStylusMode (Palm Guard) is ON, reject touch events so palm does not leave ink
    if (widget.strictStylusMode && event.kind == PointerDeviceKind.touch) {
      return;
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;

    if (!_hasStartedWriting) {
      _hasStartedWriting = true;
      widget.onFirstStrokeDown?.call(timestamp);
    }

    if (widget.isEraser) {
      _eraseNearbyStrokes(event.localPosition);
      return;
    }

    final newPoint = StrokePoint(
      x: event.localPosition.dx,
      y: event.localPosition.dy,
      pressure: event.pressure > 0.0 ? event.pressure : 1.0,
      timestampMs: timestamp,
      tilt: event.tilt,
      orientation: event.orientation,
      deviceKind: event.kind,
    );

    setState(() {
      _currentStroke = HandwritingStroke(
        points: [newPoint],
        color: widget.inkColor,
        strokeWidth: widget.strokeWidth,
      );
      _redoStack.clear();
    });
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (widget.strictStylusMode && event.kind == PointerDeviceKind.touch) {
      return;
    }

    if (widget.isEraser) {
      _eraseNearbyStrokes(event.localPosition);
      return;
    }

    if (_currentStroke == null) return;

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final newPoint = StrokePoint(
      x: event.localPosition.dx,
      y: event.localPosition.dy,
      pressure: event.pressure > 0.0 ? event.pressure : 1.0,
      timestampMs: timestamp,
      tilt: event.tilt,
      orientation: event.orientation,
      deviceKind: event.kind,
    );

    setState(() {
      _currentStroke!.addPoint(newPoint);
    });
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (widget.strictStylusMode && event.kind == PointerDeviceKind.touch) {
      return;
    }

    if (_currentStroke != null) {
      setState(() {
        if (_currentStroke!.points.isNotEmpty) {
          _strokes.add(_currentStroke!);
        }
        _currentStroke = null;
      });
      widget.onStrokesChanged?.call(_strokes);
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (_currentStroke != null) {
      setState(() {
        _currentStroke = null;
      });
    }
  }

  void _eraseNearbyStrokes(Offset touchPosition) {
    const eraserRadius = 26.0;
    final remaining = <HandwritingStroke>[];
    bool erasedAny = false;

    for (final stroke in _strokes) {
      bool intersects = false;
      for (final p in stroke.points) {
        final dist = (p.offset - touchPosition).distance;
        if (dist <= eraserRadius) {
          intersects = true;
          erasedAny = true;
          break;
        }
      }
      if (!intersects) {
        remaining.add(stroke);
      }
    }

    if (erasedAny) {
      setState(() {
        _strokes.clear();
        _strokes.addAll(remaining);
      });
      widget.onStrokesChanged?.call(_strokes);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Screenshot(
      controller: widget.screenshotController,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.paperIvory,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ─── 1. Continuous Static Background Paper Guidelines ───────────
            Positioned.fill(
              child: CustomPaint(
                painter: CanvasBackgroundPainter(
                  paperStyle: widget.paperStyle,
                ),
              ),
            ),

            // ─── 2. Interactive Static Stroke Surface (Zero Scroll, Pure Draw) ─
            Positioned.fill(
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: _handlePointerDown,
                onPointerMove: _handlePointerMove,
                onPointerUp: _handlePointerUp,
                onPointerCancel: _handlePointerCancel,
                child: CustomPaint(
                  painter: _HandwritingPainter(
                    strokes: _strokes,
                    currentStroke: _currentStroke,
                  ),
                ),
              ),
            ),

            // ─── 3. Top-Right Canvas Mode Badge ────────────────────────────
            Positioned(
              top: 12,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: const Color(0xFFFF6B00).withValues(alpha: 0.5),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.edit_rounded,
                      color: Color(0xFFFF6B00),
                      size: 13,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.strictStylusMode
                          ? 'Apple Pencil Only (Palm Guard ON)'
                          : 'Static Note • Stylus & Touch Ready',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ─── 4. Stroke Counter Badge (Bottom Left) ─────────────────────
            Positioned(
              bottom: 12,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.gesture_rounded, color: Colors.white70, size: 12),
                    const SizedBox(width: 5),
                    Text(
                      '${_strokes.length} strokes',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// High-performance painter rendering anti-aliased calligraphy strokes with pressure modulation.
class _HandwritingPainter extends CustomPainter {
  final List<HandwritingStroke> strokes;
  final HandwritingStroke? currentStroke;

  _HandwritingPainter({
    required this.strokes,
    this.currentStroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      _paintStroke(canvas, stroke);
    }
    if (currentStroke != null) {
      _paintStroke(canvas, currentStroke!);
    }
  }

  void _paintStroke(Canvas canvas, HandwritingStroke stroke) {
    if (stroke.points.isEmpty) return;

    if (stroke.points.length == 1) {
      final p = stroke.points.first;
      final dotPaint = Paint()
        ..color = stroke.color
        ..style = PaintingStyle.fill;
      final radius = (stroke.strokeWidth * p.pressure).clamp(1.5, 12.0) / 2;
      canvas.drawCircle(p.offset, radius, dotPaint);
      return;
    }

    for (int i = 0; i < stroke.points.length - 1; i++) {
      final p1 = stroke.points[i];
      final p2 = stroke.points[i + 1];

      final avgPressure = (p1.pressure + p2.pressure) / 2.0;
      final width = (stroke.strokeWidth * (0.6 + avgPressure * 0.6))
          .clamp(1.0, stroke.strokeWidth * 2.2);

      final segmentPaint = Paint()
        ..color = stroke.color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true;

      canvas.drawLine(p1.offset, p2.offset, segmentPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HandwritingPainter oldDelegate) {
    return true;
  }
}
