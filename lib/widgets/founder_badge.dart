import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Sparkly hex badge worn by founder players.
///
/// Two intended sizes:
///   • Small (32–36px) — overlay on the player's profile avatar to
///     mark them as one of the first 1,000 players.
///   • Large (~200px) — centerpiece of the Founder reveal screen
///     (post-onboarding, in place of the old paywall).
///
/// Renders [assets/founder-badge.png] (already has gold hex frame +
/// purple core + cyan trim + "F" wordmark + "1" chip baked in) and
/// layers four orbiting sparkle stars + a diagonal shimmer sweep on
/// top when [animate] is true.
class FounderBadge extends StatefulWidget {
  const FounderBadge({
    super.key,
    this.size = 36,
    this.animate = true,
  });

  final double size;
  final bool animate;

  @override
  State<FounderBadge> createState() => _FounderBadgeState();
}

class _FounderBadgeState extends State<FounderBadge>
    with TickerProviderStateMixin {
  AnimationController? _sparkle;
  AnimationController? _shimmer;

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _sparkle = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1600),
      )..repeat();
      _shimmer = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 3),
      )..repeat();
    }
  }

  @override
  void dispose() {
    _sparkle?.dispose();
    _shimmer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final h = s * 1.08;
    return SizedBox(
      width: s + 12,
      height: h + 12,
      child: Center(
        child: SizedBox(
          width: s,
          height: h,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Ambient gold halo behind the badge.
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppPalette.amber.withValues(alpha: 0.55),
                          Colors.transparent,
                        ],
                        stops: const [0, 0.7],
                      ),
                    ),
                  ),
                ),
              ),
              // The actual badge image.
              Positioned.fill(
                child: Image.asset(
                  'assets/founder-badge.png',
                  fit: BoxFit.contain,
                ),
              ),
              // Diagonal shimmer sweep over the gold.
              if (widget.animate && _shimmer != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _shimmer!,
                      builder: (_, _) => ClipPath(
                        clipper: const _HexClipper(),
                        child: Align(
                          alignment:
                              Alignment(-1.5 + _shimmer!.value * 3, 0),
                          child: FractionallySizedBox(
                            widthFactor: 0.45,
                            heightFactor: 1,
                            child: Transform.rotate(
                              angle: -0.4,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Colors.white
                                          .withValues(alpha: 0.55),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              // Four orbiting sparkles.
              if (widget.animate && _sparkle != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _sparkle!,
                      builder: (_, _) => CustomPaint(
                        painter: _SparklesPainter(
                          time: _sparkle!.value,
                          size: s,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HexClipper extends CustomClipper<Path> {
  const _HexClipper();
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.5, h * 0.04)
      ..lineTo(w * 0.92, h * 0.28)
      ..lineTo(w * 0.92, h * 0.78)
      ..lineTo(w * 0.5, h)
      ..lineTo(w * 0.08, h * 0.78)
      ..lineTo(w * 0.08, h * 0.28)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _SparklesPainter extends CustomPainter {
  _SparklesPainter({required this.time, required this.size});
  final double time; // 0..1, loops every 1.6s
  final double size;

  static const _stars = [
    // (xFrac, yFrac, phase, color)
    (-0.04, 0.15, 0.0, Color(0xFFFFF6CC)),
    (1.04, 0.6, 0.7 / 1.6, Color(0xFFFBBF24)),
    (0.5, -0.03, 1.4 / 1.6, Color(0xFFFFF6CC)),
    (0.15, 1.04, 1.0 / 1.6, AppPalette.teal),
  ];

  @override
  void paint(Canvas canvas, Size canvasSize) {
    for (final star in _stars) {
      final phase = (time + star.$3) % 1.0;
      // Sparkle pulse: opacity peaks at phase 0.5.
      final pulse = (1 - (phase - 0.5).abs() * 2).clamp(0.0, 1.0);
      final opacity = pulse;
      final scale = 0.4 + 0.7 * pulse;
      final rot = phase * math.pi;
      final cx = star.$1 * canvasSize.width;
      final cy = star.$2 * canvasSize.height;
      _drawStar(canvas, Offset(cx, cy), 4 * scale, rot,
          star.$4.withValues(alpha: opacity));
    }
  }

  void _drawStar(
    Canvas canvas,
    Offset center,
    double radius,
    double rotation,
    Color color,
  ) {
    final paint = Paint()
      ..color = color
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
    // Simple 4-pointed sparkle: two crossed thin diamonds.
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    final path = Path()
      ..moveTo(0, -radius)
      ..lineTo(radius * 0.3, 0)
      ..lineTo(0, radius)
      ..lineTo(-radius * 0.3, 0)
      ..close();
    canvas.drawPath(path, paint);
    canvas.rotate(math.pi / 2);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SparklesPainter old) => true;
}
