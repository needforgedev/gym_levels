import 'package:flutter/material.dart';
import '../theme/tokens.dart';

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
