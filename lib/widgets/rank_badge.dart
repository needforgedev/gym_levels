import 'package:flutter/material.dart';
import '../theme/tokens.dart';

enum Rank { bronze, silver, gold, platinum, diamond, master, grandmaster }

Rank rankFromString(String s) => Rank.values.firstWhere(
      (r) => r.name == s,
      orElse: () => Rank.gold,
    );

class _RankColors {
  final Color a;
  final Color b;
  const _RankColors(this.a, this.b);
}

_RankColors _colorsFor(Rank r) {
  switch (r) {
    case Rank.bronze:
      return const _RankColors(AppPalette.bronzeA, AppPalette.bronzeB);
    case Rank.silver:
      return const _RankColors(AppPalette.silverA, AppPalette.silverB);
    case Rank.gold:
      return const _RankColors(AppPalette.goldA, AppPalette.goldB);
    case Rank.platinum:
      return const _RankColors(AppPalette.platinumA, AppPalette.platinumB);
    case Rank.diamond:
      return const _RankColors(AppPalette.diamondA, AppPalette.diamondB);
    case Rank.master:
      return const _RankColors(AppPalette.masterA, AppPalette.masterB);
    case Rank.grandmaster:
      return const _RankColors(AppPalette.grandmasterA, AppPalette.grandmasterB);
  }
}

Color rankBarColor(Rank r) => _colorsFor(r).a;

class RankBadge extends StatefulWidget {
  const RankBadge({
    super.key,
    this.rank = Rank.gold,
    this.subRank = 'II',
    this.size = 48,
    this.animated = false,
  });

  final Rank rank;
  final String subRank;
  final double size;
  final bool animated;

  @override
  State<RankBadge> createState() => _RankBadgeState();
}

class _RankBadgeState extends State<RankBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    if (widget.animated) _ctl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = _colorsFor(widget.rank);
    final badge = SizedBox(
      width: widget.size,
      height: widget.size,
      child: CustomPaint(
        painter: _HexShield(colors: colors),
        child: Center(
          child: Text(
            widget.subRank,
            style: AppType.displaySM(color: AppPalette.obsidian).copyWith(
              fontSize: widget.size * 0.30,
              fontWeight: FontWeight.w700,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
    if (!widget.animated) return badge;
    return AnimatedBuilder(
      animation: _ctl,
      builder: (context, child) {
        final angle = _ctl.value * 0.04; // ~2deg
        final scale = 1 + (_ctl.value * 0.03);
        return Transform.rotate(
          angle: angle,
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: badge,
    );
  }
}

class _HexShield extends CustomPainter {
  _HexShield({required this.colors});
  final _RankColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    Path hex(double inset) {
      final p = Path();
      // Emulates the prototype polygon at viewBox 0 0 48 48.
      // points: 24,2  44,12  44,36  24,46  4,36  4,12  (in % of 48)
      final pts = [
        const Offset(24 / 48, 2 / 48),
        const Offset(44 / 48, 12 / 48),
        const Offset(44 / 48, 36 / 48),
        const Offset(24 / 48, 46 / 48),
        const Offset(4 / 48, 36 / 48),
        const Offset(4 / 48, 12 / 48),
      ];
      // inset scales towards the center 24,24
      final cx = 24 / 48;
      final cy = 24 / 48;
      for (var i = 0; i < pts.length; i++) {
        final px = cx + (pts[i].dx - cx) * (1 - inset);
        final py = cy + (pts[i].dy - cy) * (1 - inset);
        final abs = Offset(px * w, py * h);
        if (i == 0) {
          p.moveTo(abs.dx, abs.dy);
        } else {
          p.lineTo(abs.dx, abs.dy);
        }
      }
      p.close();
      return p;
    }

    final outer = hex(0);
    final inner = hex(0.25);

    // glow
    canvas.drawPath(
      outer,
      Paint()
        ..color = colors.a.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    canvas.drawPath(
      outer,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.a, colors.b],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      outer,
      Paint()
        ..color = colors.a
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.drawPath(
      inner,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  @override
  bool shouldRepaint(covariant _HexShield oldDelegate) =>
      oldDelegate.colors.a != colors.a || oldDelegate.colors.b != colors.b;
}
