import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/tokens.dart';

/// Striped "> LABEL" placeholder for hero art.
class PlaceholderBlock extends StatelessWidget {
  const PlaceholderBlock({
    super.key,
    this.label = 'IMAGE',
    this.height = 160,
    this.color = AppPalette.purple,
    this.borderRadius,
    this.border = true,
  });

  final String label;
  final double height;
  final Color color;
  final BorderRadius? borderRadius;
  final bool border;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        border: border
            ? Border.all(color: color.withValues(alpha: 0.4))
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _StripePainter()),
          Center(
            child: Text(
              '> ${label.toUpperCase()}',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                letterSpacing: 1.5,
                color: color.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p1 = Paint()..color = AppPalette.slate;
    final p2 = Paint()..color = AppPalette.carbon;
    canvas.drawRect(Offset.zero & size, p1);

    final step = 20.0;
    final paint = Paint()
      ..color = AppPalette.carbon
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;

    // 135deg repeating stripes
    final diag = size.width + size.height;
    for (double d = -diag; d < diag; d += step) {
      canvas.drawLine(Offset(d, 0), Offset(d + size.height, size.height), paint);
    }

    // suppress unused
    p2.color;
  }

  @override
  bool shouldRepaint(covariant _StripePainter oldDelegate) => false;
}
