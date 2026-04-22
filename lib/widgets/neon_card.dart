import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// Atomic glowing container. 95% of content lives inside one of these.
class NeonCard extends StatefulWidget {
  const NeonCard({
    super.key,
    this.glow = GlowColor.teal,
    this.padding = const EdgeInsets.all(AppSpace.s5),
    this.onTap,
    this.pulse = true,
    this.noBg = false,
    this.clipBehavior = Clip.none,
    required this.child,
  });

  final GlowColor glow;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool pulse;
  final bool noBg;
  final Clip clipBehavior;
  final Widget child;

  @override
  State<NeonCard> createState() => _NeonCardState();
}

class _NeonCardState extends State<NeonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _anim = CurvedAnimation(parent: _ctl, curve: Curves.easeInOut);
    if (widget.pulse && widget.glow != GlowColor.none) {
      _ctl.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant NeonCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulse && widget.glow != GlowColor.none) {
      if (!_ctl.isAnimating) _ctl.repeat(reverse: true);
    } else {
      _ctl.stop();
    }
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = AppGlow.border(widget.glow);

    Widget content = AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final double pulseScale;
        if (widget.glow == GlowColor.none) {
          pulseScale = 0;
        } else if (widget.pulse) {
          // 0.55 → 1.0
          pulseScale = 0.55 + (_anim.value * 0.45);
        } else {
          pulseScale = 0.8;
        }
        return Container(
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.noBg ? Colors.transparent : AppPalette.carbon,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: AppGlow.shadow(
              widget.glow,
              intensity: pulseScale,
              alpha: 0.45,
            ),
          ),
          child: widget.child,
        );
      },
    );

    if (widget.clipBehavior != Clip.none) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        clipBehavior: widget.clipBehavior,
        child: content,
      );
    }

    if (widget.onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: content,
        ),
      );
    }
    return content;
  }
}
