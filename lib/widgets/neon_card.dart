import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// Atomic glowing container — 95% of content lives inside one of these.
///
/// Visual matches the design v2 `Card` primitive (`design/v2/shared.jsx`):
/// a violet-tinted vertical gradient surface with a thin violet border, an
/// inset white top highlight, and an optional outer glow when [glow] is set
/// to anything other than [GlowColor.none].
///
/// The [glow] color tints the outer drop-shadow and the border emphasis.
/// When the caller asks for a non-purple glow (teal / amber / flame / etc.)
/// the border picks up that hue; otherwise the default violet stays.
class NeonCard extends StatefulWidget {
  const NeonCard({
    super.key,
    this.glow = GlowColor.purple,
    this.padding = const EdgeInsets.all(AppSpace.s5),
    this.onTap,
    this.pulse = false,
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

  // 18px matches the design v2 card radius. Using a local const so the
  // shared `AppRadius.lg` constant (16) isn't disturbed for other callers.
  static const double _radius = 18;

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

  bool get _isPurpleAccent =>
      widget.glow == GlowColor.purple || widget.glow == GlowColor.none;

  Color get _borderColor {
    if (widget.glow == GlowColor.none) {
      return AppPalette.borderViolet;
    }
    if (_isPurpleAccent) {
      return AppPalette.borderVioletGlow;
    }
    return AppGlow.border(widget.glow).withValues(alpha: 0.4);
  }

  @override
  Widget build(BuildContext context) {
    Widget content = AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final double pulseScale;
        if (widget.glow == GlowColor.none) {
          pulseScale = 0;
        } else if (widget.pulse) {
          pulseScale = 0.55 + (_anim.value * 0.45);
        } else {
          // Static cards still get a soft outer glow — the design's
          // `glow=true` Card has `boxShadow: 0 0 24px -8px rgba(...,0.4)`.
          pulseScale = 0.55;
        }

        final shadows = <BoxShadow>[
          if (widget.glow != GlowColor.none)
            BoxShadow(
              color: AppGlow.border(widget.glow)
                  .withValues(alpha: 0.4 * pulseScale),
              blurRadius: 24,
              spreadRadius: -8,
            ),
          // Inset highlight (top edge) — design's
          // `inset 0 1px 0 rgba(255,255,255,0.03)`.
          const BoxShadow(
            color: Color(0x08FFFFFF),
            blurRadius: 0,
            offset: Offset(0, 1),
            spreadRadius: -1,
          ),
        ];

        return Container(
          padding: widget.padding,
          decoration: BoxDecoration(
            gradient: widget.noBg
                ? null
                : const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xE61A0F2B), // bgCard2 @ 0.9
                      Color(0xE6120A1F), // bgCard  @ 0.9
                    ],
                  ),
            color: widget.noBg ? Colors.transparent : null,
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(color: _borderColor, width: 1),
            boxShadow: shadows,
          ),
          child: widget.child,
        );
      },
    );

    if (widget.clipBehavior != Clip.none) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        clipBehavior: widget.clipBehavior,
        child: content,
      );
    }

    if (widget.onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(_radius),
          child: content,
        ),
      );
    }
    return content;
  }
}
