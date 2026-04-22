import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// Rising & fading "+XX XP" pill used by the workout logger.
class XPToast extends StatefulWidget {
  const XPToast({super.key, required this.amount});
  final int amount;

  @override
  State<XPToast> createState() => _XPToastState();
}

class _XPToastState extends State<XPToast> with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
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
        final t = _ctl.value;
        final opacity = t < 0.2
            ? (t / 0.2)
            : (1 - ((t - 0.2) / 0.8)).clamp(0.0, 1.0);
        final translateY = -40 * t;
        return IgnorePointer(
          child: Transform.translate(
            offset: Offset(0, translateY),
            child: Opacity(
              opacity: opacity,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: AppPalette.xpGold.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: AppPalette.xpGold),
                  boxShadow: [
                    BoxShadow(
                      color: AppPalette.xpGold.withValues(alpha: 0.66),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Text(
                  '+${widget.amount} XP',
                  style: AppType.monoLG(color: AppPalette.xpGold).copyWith(
                    fontSize: 20,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
