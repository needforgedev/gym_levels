import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// Stylized gradient flame used in the streak hero and milestone.
class BigFlame extends StatelessWidget {
  const BigFlame({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _FlamePainter()),
    );
  }
}

class _FlamePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final sx = w / 96;
    final sy = h / 96;
    Offset p(double x, double y) => Offset(x * sx, y * sy);

    final path = Path()
      ..moveTo(p(48, 8).dx, p(48, 8).dy)
      ..cubicTo(p(56, 22).dx, p(56, 22).dy, p(38, 28).dx, p(38, 28).dy, p(48, 48).dx, p(48, 48).dy)
      ..cubicTo(p(52, 44).dx, p(52, 44).dy, p(56, 36).dx, p(56, 36).dy, p(56, 30).dx, p(56, 30).dy)
      ..cubicTo(p(64, 44).dx, p(64, 44).dy, p(72, 56).dx, p(72, 56).dy, p(72, 68).dx, p(72, 68).dy)
      ..arcToPoint(p(24, 68),
          radius: const Radius.circular(24), clockwise: false)
      ..cubicTo(p(24, 54).dx, p(24, 54).dy, p(34, 46).dx, p(34, 46).dy, p(34, 36).dx, p(34, 36).dy)
      ..cubicTo(p(38, 40).dx, p(38, 40).dy, p(42, 44).dx, p(42, 44).dy, p(46, 48).dx, p(46, 48).dy)
      ..cubicTo(p(42, 36).dx, p(42, 36).dy, p(42, 24).dx, p(42, 24).dy, p(48, 8).dx, p(48, 8).dy)
      ..close();

    final gradient = const LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [AppPalette.xpGold, AppPalette.flame, AppPalette.danger],
      stops: [0, 0.6, 1],
    );

    canvas.drawPath(
      path,
      Paint()..shader = gradient.createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant _FlamePainter oldDelegate) => false;
}
