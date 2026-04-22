import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// Ambient gridded radial-gradient backdrop. Matches the prototype's `.lvl-bg`.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: _Backdrop()),
        child,
      ],
    );
  }
}

class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF05070D),
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.6, -0.8),
                radius: 1.1,
                colors: [
                  AppPalette.purple.withValues(alpha: 0.10),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.7, 0.9),
                radius: 1.1,
                colors: [
                  AppPalette.teal.withValues(alpha: 0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          CustomPaint(painter: _GridPainter()),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x08E6EEF5)
      ..strokeWidth = 1;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => false;
}
