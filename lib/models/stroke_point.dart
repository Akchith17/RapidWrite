import 'dart:ui';

/// Represents a single sampled point from a stylus or pointer event.
class StrokePoint {
  final double x;
  final double y;
  final double pressure;
  final int timestampMs;
  final double tilt;
  final double orientation;
  final PointerDeviceKind deviceKind;

  StrokePoint({
    required this.x,
    required this.y,
    this.pressure = 1.0,
    required this.timestampMs,
    this.tilt = 0.0,
    this.orientation = 0.0,
    this.deviceKind = PointerDeviceKind.stylus,
  });

  Offset get offset => Offset(x, y);

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'pressure': pressure,
        'timestampMs': timestampMs,
        'tilt': tilt,
        'orientation': orientation,
        'deviceKind': deviceKind.name,
      };
}
