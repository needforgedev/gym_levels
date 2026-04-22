import 'package:flutter/material.dart';
import '../theme/tokens.dart';

enum MuscleHighlight { chest, back, legs, arms, core, none }

/// Anime-ish body silhouette with a highlighted region glow.
class MuscleFigure extends StatelessWidget {
  const MuscleFigure({
    super.key,
    this.highlight = MuscleHighlight.chest,
    this.color = AppPalette.purple,
    this.size = 140,
  });

  final MuscleHighlight highlight;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.5,
      child: CustomPaint(
        painter: _MusclePainter(highlight: highlight, color: color),
      ),
    );
  }
}

class _MusclePainter extends CustomPainter {
  _MusclePainter({required this.highlight, required this.color});
  final MuscleHighlight highlight;
  final Color color;

  // Muscle group keys matching the prototype.
  static const _chest = 'chest';
  static const _back = 'back';
  static const _shoulders = 'shoulders';
  static const _core = 'core';
  static const _biceps = 'biceps';
  static const _triceps = 'triceps';
  static const _glutes = 'glutes';
  static const _quads = 'quads';
  static const _hamstrings = 'hamstrings';
  static const _calves = 'calves';

  List<String> get _activeGroups {
    switch (highlight) {
      case MuscleHighlight.chest:
        return [_chest, _shoulders];
      case MuscleHighlight.back:
        return [_back];
      case MuscleHighlight.legs:
        return [_quads, _hamstrings, _glutes, _calves];
      case MuscleHighlight.arms:
        return [_biceps, _triceps, _shoulders];
      case MuscleHighlight.core:
        return [_core];
      case MuscleHighlight.none:
        return const [];
    }
  }

  bool _on(String k) => _activeGroups.contains(k);
  Color _fill(String k) => _on(k) ? color : AppPalette.slate;

  void _drawShape(
    Canvas canvas,
    String key,
    Path path, {
    double opacity = 1,
  }) {
    if (_on(key)) {
      // glow
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: 0.5 * opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
    canvas.drawPath(
      path,
      Paint()..color = _fill(key).withValues(alpha: opacity),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Base viewBox: 100 x 150
    final sx = size.width / 100;
    final sy = size.height / 150;
    Offset p(double x, double y) => Offset(x * sx, y * sy);

    // Head
    canvas.drawCircle(
      p(50, 15),
      10 * sx,
      Paint()..color = AppPalette.slate,
    );
    canvas.drawCircle(
      p(50, 15),
      10 * sx,
      Paint()
        ..color = AppPalette.strokeSubtle
        ..style = PaintingStyle.stroke,
    );

    // Neck
    canvas.drawRect(
      Rect.fromLTWH(45 * sx, 24 * sy, 10 * sx, 6 * sy),
      Paint()..color = AppPalette.slate,
    );

    // Shoulders
    _drawShape(
      canvas,
      _shoulders,
      Path()
        ..moveTo(p(30, 32).dx, p(30, 32).dy)
        ..quadraticBezierTo(p(50, 26).dx, p(50, 26).dy, p(70, 32).dx, p(70, 32).dy)
        ..lineTo(p(70, 38).dx, p(70, 38).dy)
        ..quadraticBezierTo(p(50, 34).dx, p(50, 34).dy, p(30, 38).dx, p(30, 38).dy)
        ..close(),
    );

    // Chest
    _drawShape(
      canvas,
      _chest,
      Path()
        ..moveTo(p(32, 38).dx, p(32, 38).dy)
        ..quadraticBezierTo(p(50, 42).dx, p(50, 42).dy, p(68, 38).dx, p(68, 38).dy)
        ..lineTo(p(68, 58).dx, p(68, 58).dy)
        ..quadraticBezierTo(p(50, 62).dx, p(50, 62).dy, p(32, 58).dx, p(32, 58).dy)
        ..close(),
    );

    // Core
    _drawShape(
      canvas,
      _core,
      Path()
        ..moveTo(p(38, 58).dx, p(38, 58).dy)
        ..quadraticBezierTo(p(50, 60).dx, p(50, 60).dy, p(62, 58).dx, p(62, 58).dy)
        ..lineTo(p(60, 82).dx, p(60, 82).dy)
        ..quadraticBezierTo(p(50, 84).dx, p(50, 84).dy, p(40, 82).dx, p(40, 82).dy)
        ..close(),
    );

    // Biceps
    for (final cx in [25.0, 75.0]) {
      _drawShape(
        canvas,
        _biceps,
        Path()
          ..addOval(
            Rect.fromCenter(center: p(cx, 50), width: 12 * sx, height: 20 * sy),
          ),
      );
    }

    // Triceps
    for (final cx in [22.0, 78.0]) {
      _drawShape(
        canvas,
        _triceps,
        Path()
          ..addOval(
            Rect.fromCenter(center: p(cx, 65), width: 10 * sx, height: 18 * sy),
          ),
        opacity: 0.8,
      );
    }

    // Forearms (always slate)
    for (final x in [19.0, 75.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x * sx, 72 * sy, 6 * sx, 18 * sy),
          const Radius.circular(3),
        ),
        Paint()..color = AppPalette.slate,
      );
    }

    // Glutes
    _drawShape(
      canvas,
      _glutes,
      Path()
        ..moveTo(p(38, 82).dx, p(38, 82).dy)
        ..quadraticBezierTo(p(50, 84).dx, p(50, 84).dy, p(62, 82).dx, p(62, 82).dy)
        ..lineTo(p(62, 92).dx, p(62, 92).dy)
        ..quadraticBezierTo(p(50, 94).dx, p(50, 94).dy, p(38, 92).dx, p(38, 92).dy)
        ..close(),
    );

    // Quads
    _drawShape(
      canvas,
      _quads,
      Path()
        ..moveTo(p(38, 92).dx, p(38, 92).dy)
        ..lineTo(p(42, 122).dx, p(42, 122).dy)
        ..lineTo(p(48, 122).dx, p(48, 122).dy)
        ..lineTo(p(48, 94).dx, p(48, 94).dy)
        ..close(),
    );
    _drawShape(
      canvas,
      _quads,
      Path()
        ..moveTo(p(52, 94).dx, p(52, 94).dy)
        ..lineTo(p(52, 122).dx, p(52, 122).dy)
        ..lineTo(p(58, 122).dx, p(58, 122).dy)
        ..lineTo(p(62, 92).dx, p(62, 92).dy)
        ..close(),
    );

    // Hamstrings (faint)
    _drawShape(
      canvas,
      _hamstrings,
      Path()
        ..moveTo(p(40, 92).dx, p(40, 92).dy)
        ..lineTo(p(40, 120).dx, p(40, 120).dy)
        ..lineTo(p(44, 120).dx, p(44, 120).dy)
        ..lineTo(p(46, 94).dx, p(46, 94).dy)
        ..close(),
      opacity: 0.5,
    );
    _drawShape(
      canvas,
      _hamstrings,
      Path()
        ..moveTo(p(54, 94).dx, p(54, 94).dy)
        ..lineTo(p(56, 120).dx, p(56, 120).dy)
        ..lineTo(p(60, 120).dx, p(60, 120).dy)
        ..lineTo(p(60, 92).dx, p(60, 92).dy)
        ..close(),
      opacity: 0.5,
    );

    // Calves
    for (final x in [41.0, 52.0]) {
      _drawShape(
        canvas,
        _calves,
        Path()
          ..addRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(x * sx, 122 * sy, 7 * sx, 18 * sy),
              const Radius.circular(3),
            ),
          ),
      );
    }

    // Back (overlay if highlighted)
    if (_on(_back)) {
      final back = Path()
        ..moveTo(p(32, 38).dx, p(32, 38).dy)
        ..quadraticBezierTo(p(50, 44).dx, p(50, 44).dy, p(68, 38).dx, p(68, 38).dy)
        ..lineTo(p(68, 80).dx, p(68, 80).dy)
        ..quadraticBezierTo(p(50, 84).dx, p(50, 84).dy, p(32, 80).dx, p(32, 80).dy)
        ..close();
      canvas.drawPath(
        back,
        Paint()
          ..color = color.withValues(alpha: 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawPath(back, Paint()..color = color.withValues(alpha: 0.25));
    }
  }

  @override
  bool shouldRepaint(covariant _MusclePainter oldDelegate) =>
      oldDelegate.highlight != highlight || oldDelegate.color != color;
}
