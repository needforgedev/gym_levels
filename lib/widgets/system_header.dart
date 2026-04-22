import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// "● ● ● KICKER" — animated dot row + uppercase kicker label.
class SystemHeader extends StatefulWidget {
  const SystemHeader({
    super.key,
    required this.kicker,
    this.color = AppPalette.teal,
  });

  final String kicker;
  final Color color;

  @override
  State<SystemHeader> createState() => _SystemHeaderState();
}

class _SystemHeaderState extends State<SystemHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctl,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final phase = (_ctl.value + i * 0.15) % 1.0;
                final wave = 0.5 + 0.5 * -math.cos(phase * 2 * math.pi);
                final opacity = (0.6 + 0.4 * wave).clamp(0.0, 1.0);
                final scale = 1 + 0.3 * wave;
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: opacity),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: widget.color, blurRadius: 6),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                widget.kicker.toUpperCase(),
                style: AppType.label(color: widget.color).copyWith(
                  letterSpacing: 2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
  }
}
