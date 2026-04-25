import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// Amber-gradient XP progress bar with a moving shimmer sheen — matches the
/// design v2 `XPBar` (`design/v2/shared.jsx`). Used on Home, Profile, and
/// any place player XP is shown.
class XpBar extends StatefulWidget {
  const XpBar({
    super.key,
    required this.percent,
    this.height = 10,
  });

  /// 0..100. Values outside the range are clamped.
  final double percent;
  final double height;

  @override
  State<XpBar> createState() => _XpBarState();
}

class _XpBarState extends State<XpBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clamped = (widget.percent.clamp(0, 100)) / 100;
    final radius = widget.height / 2;
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: AppPalette.purple.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: AppPalette.purple.withValues(alpha: 0.20),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: clamped,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xFFF59E0B),
                  Color(0xFFF5A623),
                  Color(0xFFFBBF24),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
              borderRadius: BorderRadius.circular(radius),
              boxShadow: [
                BoxShadow(
                  color: AppPalette.amber.withValues(alpha: 0.6),
                  blurRadius: 10,
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _ctl,
              builder: (context, _) {
                // Shimmer band travels left → right; matches the
                // `@keyframes shimmer` rule in design/v2/index.html.
                return ShaderMask(
                  blendMode: BlendMode.srcATop,
                  shaderCallback: (rect) {
                    final shift = _ctl.value * 2 * rect.width;
                    return LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.4),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                      transform: _ShimmerTransform(shift),
                    ).createShader(rect);
                  },
                  child: const SizedBox.expand(),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ShimmerTransform extends GradientTransform {
  const _ShimmerTransform(this.dx);
  final double dx;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(dx - bounds.width, 0, 0);
}

/// Thin gradient progress bar with optional glow.
class Bar extends StatelessWidget {
  const Bar({
    super.key,
    required this.percent,
    this.color = AppPalette.purple,
    this.height = 6,
    this.glowOn = true,
  });

  /// Percent in [0, 100].
  final double percent;
  final Color color;
  final double height;
  final bool glowOn;

  @override
  Widget build(BuildContext context) {
    final clamped = percent.clamp(0, 100) / 100;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppPalette.slate,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: clamped,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [color.withValues(alpha: 0.66), color],
              ),
              boxShadow: glowOn
                  ? [
                      BoxShadow(
                        color: color,
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
