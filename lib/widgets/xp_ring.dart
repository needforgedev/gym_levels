import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class XPRing extends StatelessWidget {
  const XPRing({
    super.key,
    required this.level,
    required this.percent,
    this.size = 100,
  });

  /// Percent in [0, 1].
  final double percent;
  final int level;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _RingPainter(percent: percent.clamp(0, 1)),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'LVL',
                style: AppType.label(color: AppPalette.textMuted).copyWith(
                  fontSize: 9,
                ),
              ),
              Text(
                '$level',
                style: AppType.monoLG(color: AppPalette.xpGold).copyWith(
                  fontSize: size * 0.28,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.percent});
  final double percent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = (size.width - 8) / 2;

    final track = Paint()
      ..color = AppPalette.slate
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final fill = Paint()
      ..color = AppPalette.xpGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    // glow behind the filled arc
    canvas.drawCircle(center, r, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      -math.pi / 2,
      percent * 2 * math.pi,
      false,
      Paint()
        ..color = AppPalette.xpGold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      -math.pi / 2,
      percent * 2 * math.pi,
      false,
      fill,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.percent != percent;
}
