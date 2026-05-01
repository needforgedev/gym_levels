import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/tokens.dart';
import '../widgets/founder_badge.dart';
import '../widgets/screen_base.dart';

/// **Founder reveal** — replaces the original paywall in v1
/// improvements. There is no paid tier in v1.x.0; instead the user is
/// told they've claimed one of the first 1,000 "founder" slots, with
/// a cosmetic slot number, ember + sparkle particles, and a single
/// "Begin Calibration" CTA.
///
/// Slot numbering is **cosmetic** — picked once per cold-launch from
/// `[200, 800)` so it feels live without server gating. (Real
/// founder-numbering would need a `public_profiles.founder_number`
/// column + an RPC; deferred per the design discussion.)
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen>
    with TickerProviderStateMixin {
  late final int _slot;
  late final AnimationController _ringSpin;
  late final AnimationController _glowPulse;

  @override
  void initState() {
    super.initState();
    _slot = 200 + math.Random().nextInt(600);
    _ringSpin = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();
    _glowPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ringSpin.dispose();
    _glowPulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = 1000 - _slot;
    final pct = _slot / 1000;
    final topInset = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return ScreenBase(
      background: AppPalette.voidBg,
      child: Stack(
        children: [
          // Layered ambient glow.
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.75),
                    radius: 0.95,
                    colors: [
                      AppPalette.amber.withValues(alpha: 0.32),
                      Colors.transparent,
                    ],
                    stops: const [0, 0.55],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, 0.7),
                    radius: 1.0,
                    colors: [
                      AppPalette.purple.withValues(alpha: 0.22),
                      Colors.transparent,
                    ],
                    stops: const [0, 0.6],
                  ),
                ),
              ),
            ),
          ),
          // Faint amber grid texture.
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: const _GridPainter()),
            ),
          ),
          // Header row.
          Positioned(
            top: topInset + 12,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _BackChip(onTap: () => context.go('/challenge-system')),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppPalette.amber.withValues(alpha: 0.10),
                    border: Border.all(
                      color: AppPalette.amber.withValues(alpha: 0.35),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '◆ SYSTEM ALERT',
                    style: TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 9,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700,
                      color: AppPalette.amber,
                    ),
                  ),
                ),
                const SizedBox(width: 34),
              ],
            ),
          ),
          // Scrollable body.
          Padding(
            padding: EdgeInsets.only(
              top: topInset + 60,
              bottom: 100 + bottomInset,
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _BadgeHero(
                    slot: _slot,
                    ringSpin: _ringSpin,
                    glowPulse: _glowPulse,
                  ),
                  const SizedBox(height: 4),
                  _StatusPill(slot: _slot),
                  const SizedBox(height: 18),
                  const _Headline(),
                  const SizedBox(height: 18),
                  _SlotProgress(slot: _slot, pct: pct, remaining: remaining),
                  const SizedBox(height: 18),
                  const _RewardsCard(),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Complete calibration to reveal your starting rank.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.5,
                        color: AppPalette.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // CTA pinned to bottom.
          Positioned(
            left: 24,
            right: 24,
            bottom: 28 + bottomInset,
            child: _BeginCalibrationButton(
              onTap: () => context.go('/loader-pre-home'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hero block: badge + halo + crown + laurels + embers + sparkles ──

class _BadgeHero extends StatelessWidget {
  const _BadgeHero({
    required this.slot,
    required this.ringSpin,
    required this.glowPulse,
  });
  final int slot;
  final AnimationController ringSpin;
  final AnimationController glowPulse;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Frosted disc backdrop.
          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppPalette.amber.withValues(alpha: 0.18),
                  AppPalette.purple.withValues(alpha: 0.12),
                  Colors.transparent,
                ],
                stops: const [0, 0.5, 0.8],
              ),
              border: Border.all(
                color: AppPalette.amber.withValues(alpha: 0.25),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppPalette.amber.withValues(alpha: 0.4),
                  blurRadius: 40,
                  spreadRadius: -8,
                ),
              ],
            ),
          ),
          // Inner dashed ring (rotating).
          AnimatedBuilder(
            animation: ringSpin,
            builder: (_, _) => Transform.rotate(
              angle: ringSpin.value * 2 * math.pi,
              child: CustomPaint(
                size: const Size(210, 210),
                painter: const _DashedRingPainter(),
              ),
            ),
          ),
          // Embers — drift up from below.
          Positioned.fill(
            child: IgnorePointer(child: const _EmberField()),
          ),
          // Sparkle ring.
          Positioned.fill(
            child: IgnorePointer(child: const _SparkleRing()),
          ),
          // Pulsing amber glow behind badge.
          AnimatedBuilder(
            animation: glowPulse,
            builder: (_, _) {
              final scale = 1.0 + 0.08 * glowPulse.value;
              final op = 0.85 + 0.15 * glowPulse.value;
              return Opacity(
                opacity: op,
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppPalette.amber.withValues(alpha: 0.5),
                          Colors.transparent,
                        ],
                        stops: const [0, 0.65],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          // Crown above.
          Positioned(
            top: 0,
            child: const _CrownAccent(),
          ),
          // Laurels left + right.
          const Positioned(left: 0, child: _Laurel()),
          const Positioned(
            right: 0,
            child: _Laurel(mirror: true),
          ),
          // Founder badge image.
          const FounderBadge(size: 200, animate: true),
          // Slot-number tag.
          Positioned(
            right: 36,
            bottom: 14,
            child: _SlotNumberTag(slot: slot),
          ),
        ],
      ),
    );
  }
}

class _DashedRingPainter extends CustomPainter {
  const _DashedRingPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = AppPalette.amber.withValues(alpha: 0.30)
      ..strokeWidth = 1;
    final path = Path()
      ..addOval(Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: size.width - 2,
        height: size.height - 2,
      ));
    // Dashed effect via PathMetrics.
    const dash = 6.0;
    const gap = 6.0;
    for (final m in path.computeMetrics()) {
      double d = 0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + dash), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRingPainter old) => false;
}

// ─── Crown ───────────────────────────────────────────────────────

class _CrownAccent extends StatelessWidget {
  const _CrownAccent();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 28,
      child: CustomPaint(painter: const _CrownPainter()),
    );
  }
}

class _CrownPainter extends CustomPainter {
  const _CrownPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final body = Path()
      ..moveTo(3, 22)
      ..lineTo(6, 6)
      ..lineTo(14, 14)
      ..lineTo(22, 3)
      ..lineTo(30, 14)
      ..lineTo(38, 6)
      ..lineTo(41, 22)
      ..close();
    final fill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFBBF24), Color(0xFFB8741A)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.5);
    canvas.drawPath(body, fill);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFFFCD34D)
      ..strokeWidth = 0.8;
    canvas.drawPath(body, stroke);
    final dot = Paint()..color = const Color(0xFFFBBF24);
    canvas.drawCircle(const Offset(6, 6), 1.8, dot);
    canvas.drawCircle(const Offset(22, 3), 2.2, dot);
    canvas.drawCircle(const Offset(38, 6), 1.8, dot);
    canvas.drawRect(
      Rect.fromLTWH(3, 22, 38, 3),
      Paint()..color = AppPalette.amber,
    );
  }

  @override
  bool shouldRepaint(covariant _CrownPainter old) => false;
}

// ─── Laurel ──────────────────────────────────────────────────────

class _Laurel extends StatelessWidget {
  const _Laurel({this.mirror = false});
  final bool mirror;

  @override
  Widget build(BuildContext context) {
    final paint = SizedBox(
      width: 60,
      height: 160,
      child: CustomPaint(painter: const _LaurelPainter()),
    );
    return mirror
        ? Transform(
            transform: Matrix4.identity()..scaleByDouble(-1.0, 1.0, 1.0, 1.0),
            alignment: Alignment.center,
            child: paint,
          )
        : paint;
  }
}

class _LaurelPainter extends CustomPainter {
  const _LaurelPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final stem = Path()
      ..moveTo(50, 10)
      ..quadraticBezierTo(20, 80, 50, 150);
    canvas.drawPath(
      stem,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..shader = const LinearGradient(
          colors: [Color(0xFF8C5814), AppPalette.amber, Color(0xFFFBBF24)],
        ).createShader(Rect.fromLTWH(0, 0, 60, 160)),
    );
    final fill = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF8C5814), AppPalette.amber, Color(0xFFFBBF24)],
      ).createShader(Rect.fromLTWH(0, 0, 60, 160))
      ..color = AppPalette.amber.withValues(alpha: 0.9);
    const ys = [15, 30, 50, 70, 90, 110, 130, 145];
    for (var i = 0; i < ys.length; i++) {
      final y = ys[i].toDouble();
      final offset = math.sin((y / 160) * math.pi) * 22;
      final cx = 50 - offset;
      canvas.save();
      canvas.translate(cx - 10, y);
      canvas.rotate((-30 - i * 2) * math.pi / 180);
      final r = Rect.fromCenter(
        center: Offset.zero,
        width: 22,
        height: 9,
      );
      canvas.drawOval(r, fill);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _LaurelPainter old) => false;
}

// ─── Embers (rising sparks) ──────────────────────────────────────

class _EmberField extends StatefulWidget {
  const _EmberField();
  @override
  State<_EmberField> createState() => _EmberFieldState();
}

class _EmberFieldState extends State<_EmberField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;
  late final List<_Ember> _embers;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
    _embers = List.generate(18, (i) {
      final color = i % 4 == 0
          ? const Color(0xFFFF6B35)
          : i % 3 == 0
              ? const Color(0xFFFBBF24)
              : AppPalette.amber;
      return _Ember(
        leftFrac: 0.25 + ((i * 13) % 50) / 100,
        size: 2.0 + (i % 3),
        delay: ((i * 0.27) % 3) / 3, // 0..1
        period: 2.4 + (i % 4) * 0.4,
        drift: -10.0 + ((i * 7) % 20),
        color: color,
      );
    });
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
      builder: (_, _) => CustomPaint(
        painter: _EmberPainter(_embers, _ctl.value * 5),
      ),
    );
  }
}

class _Ember {
  const _Ember({
    required this.leftFrac,
    required this.size,
    required this.delay,
    required this.period,
    required this.drift,
    required this.color,
  });
  final double leftFrac;
  final double size;
  final double delay;
  final double period;
  final double drift;
  final Color color;
}

class _EmberPainter extends CustomPainter {
  _EmberPainter(this.embers, this.time);
  final List<_Ember> embers;
  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    for (final e in embers) {
      final phase = ((time / e.period) + e.delay) % 1.0;
      // Opacity: 0 at start → 1 by 15% → 0.9 at 70% → 0 at 100%.
      double opacity;
      if (phase < 0.15) {
        opacity = phase / 0.15;
      } else if (phase < 0.7) {
        opacity = 1.0;
      } else {
        opacity = (1 - (phase - 0.7) / 0.3) * 0.9;
      }
      final scale = 0.6 + (1 - phase) * 0.4;
      // Position: starts 10px above bottom, drifts up to -180.
      final x = e.leftFrac * size.width + phase * e.drift;
      final y = (size.height - 10) - phase * 180;
      final paint = Paint()
        ..color = e.color.withValues(alpha: opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, e.size * 2);
      canvas.drawCircle(Offset(x, y), e.size * scale, paint);
      final core = Paint()..color = e.color.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), e.size * scale * 0.6, core);
    }
  }

  @override
  bool shouldRepaint(covariant _EmberPainter old) => true;
}

// ─── Sparkle ring ────────────────────────────────────────────────

class _SparkleRing extends StatefulWidget {
  const _SparkleRing();
  @override
  State<_SparkleRing> createState() => _SparkleRingState();
}

class _SparkleRingState extends State<_SparkleRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
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
      builder: (_, _) => CustomPaint(
        painter: _SparkleRingPainter(_ctl.value),
      ),
    );
  }
}

class _SparkleRingPainter extends CustomPainter {
  _SparkleRingPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    for (var i = 0; i < 10; i++) {
      final angle = (i / 10) * 2 * math.pi;
      final radius = 95 + (i % 3) * 8;
      final x = cx + math.cos(angle) * radius;
      final y = cy + math.sin(angle) * radius;
      final delay = (i * 0.31) % 1.0;
      final phase = (t + delay) % 1.0;
      final pulse = (1 - (phase - 0.5).abs() * 2).clamp(0.0, 1.0);
      final scale = 0.7 + 0.5 * pulse;
      final color =
          i % 2 == 0 ? AppPalette.amber : const Color(0xFFFBBF24);
      _drawStar(
        canvas,
        Offset(x, y),
        (6 + (i % 3) * 2) * scale,
        phase * math.pi,
        color.withValues(alpha: 0.2 + 0.8 * pulse),
      );
    }
  }

  void _drawStar(
    Canvas canvas,
    Offset c,
    double r,
    double rot,
    Color color,
  ) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(rot);
    final paint = Paint()
      ..color = color
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
    final p = Path()
      ..moveTo(0, -r)
      ..lineTo(r * 0.18, -r * 0.18)
      ..lineTo(r, 0)
      ..lineTo(r * 0.18, r * 0.18)
      ..lineTo(0, r)
      ..lineTo(-r * 0.18, r * 0.18)
      ..lineTo(-r, 0)
      ..lineTo(-r * 0.18, -r * 0.18)
      ..close();
    canvas.drawPath(p, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SparkleRingPainter old) => true;
}

// ─── Slot number tag ─────────────────────────────────────────────

class _SlotNumberTag extends StatelessWidget {
  const _SlotNumberTag({required this.slot});
  final int slot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFBBF24), AppPalette.amber],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: AppPalette.amber.withValues(alpha: 0.6),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'NO.',
            style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 7,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
              color: AppPalette.voidBg.withValues(alpha: 0.8),
              height: 1,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            slot.toString().padLeft(3, '0'),
            style: AppType.displaySM(color: AppPalette.voidBg).copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Status pill ─────────────────────────────────────────────────

class _StatusPill extends StatefulWidget {
  const _StatusPill({required this.slot});
  final int slot;
  @override
  State<_StatusPill> createState() => _StatusPillState();
}

class _StatusPillState extends State<_StatusPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppPalette.teal.withValues(alpha: 0.08),
        border: Border.all(
          color: AppPalette.teal.withValues(alpha: 0.4),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _ctl,
            builder: (_, _) {
              final t = _ctl.value;
              final op = 0.5 + 0.5 * t;
              final scale = 0.85 + 0.15 * t;
              return Opacity(
                opacity: op,
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppPalette.teal,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: AppPalette.teal, blurRadius: 8),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 7),
          Text(
            'SLOT RESERVED · ${widget.slot} / 1000',
            style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 9,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
              color: AppPalette.teal,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Headline ────────────────────────────────────────────────────

class _Headline extends StatelessWidget {
  const _Headline();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            'FOUNDING PLAYER',
            textAlign: TextAlign.center,
            style: AppType.displayLG(color: AppPalette.textPrimary).copyWith(
              fontSize: 30,
              height: 1,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 2),
          ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppPalette.amber, Color(0xFFFBBF24)],
            ).createShader(rect),
            child: Text(
              'UNLOCKED',
              textAlign: TextAlign.center,
              style: AppType.displayLG(color: Colors.white).copyWith(
                fontSize: 30,
                height: 1,
                letterSpacing: 1,
                shadows: [
                  Shadow(
                    color: AppPalette.amber.withValues(alpha: 0.4),
                    blurRadius: 24,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AppPalette.textPrimary.withValues(alpha: 0.85),
              ),
              children: [
                const TextSpan(
                    text: 'You\'re one of the first '),
                TextSpan(
                  text: '1,000 players',
                  style: TextStyle(
                    color: AppPalette.amber,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(
                    text: ' to enter the System. Your '),
                TextSpan(
                  text: 'Founder badge',
                  style: TextStyle(
                    color: AppPalette.amber,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(text: ' has been reserved.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Slot progress bar ───────────────────────────────────────────

class _SlotProgress extends StatelessWidget {
  const _SlotProgress({
    required this.slot,
    required this.pct,
    required this.remaining,
  });
  final int slot;
  final double pct;
  final int remaining;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'FOUNDER SLOTS',
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 9,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.textMuted,
                ),
              ),
              Text(
                '${_fmt(slot)} / 1,000',
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 6,
              child: Stack(
                children: [
                  ColoredBox(color: AppPalette.purple.withValues(alpha: 0.15)),
                  FractionallySizedBox(
                    widthFactor: pct,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [AppPalette.purpleSoft, AppPalette.amber],
                        ),
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          BoxShadow(
                            color: AppPalette.amber.withValues(alpha: 0.6),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontSize: 10,
                color: AppPalette.textDisabled,
              ),
              children: [
                const TextSpan(text: 'Only '),
                TextSpan(
                  text: '$remaining',
                  style: TextStyle(
                    color: AppPalette.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(text: ' founder slots remaining'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(int n) {
    final s = n.toString();
    return s.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (m) => '${m[1]},',
    );
  }
}

// ─── Rewards card ────────────────────────────────────────────────

class _RewardsCard extends StatelessWidget {
  const _RewardsCard();

  static const _rewards = [
    (
      icon: Icons.shield_outlined,
      label: 'Founder Badge',
      sub: 'Permanent profile crest',
      accent: AppPalette.amber,
    ),
    (
      icon: Icons.local_fire_department_outlined,
      label: '+1,000 XP',
      sub: 'Head-start bonus',
      accent: Color(0xFFFBBF24),
    ),
    (
      icon: Icons.bolt_outlined,
      label: 'Early Access Status',
      sub: 'Beta features first',
      accent: AppPalette.purpleSoft,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppPalette.amber.withValues(alpha: 0.14),
              AppPalette.purple.withValues(alpha: 0.10),
            ],
          ),
          border: Border.all(
            color: AppPalette.amber.withValues(alpha: 0.40),
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '◆ FOUNDER REWARDS',
              style: TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 9,
                letterSpacing: 2,
                fontWeight: FontWeight.w800,
                color: AppPalette.amber,
              ),
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < _rewards.length; i++) ...[
              _RewardRow(
                icon: _rewards[i].icon,
                label: _rewards[i].label,
                sub: _rewards[i].sub,
                accent: _rewards[i].accent,
              ),
              if (i < _rewards.length - 1) const SizedBox(height: 9),
            ],
          ],
        ),
      ),
    );
  }
}

class _RewardRow extends StatelessWidget {
  const _RewardRow({
    required this.icon,
    required this.label,
    required this.sub,
    required this.accent,
  });
  final IconData icon;
  final String label;
  final String sub;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.13),
            border: Border.all(color: accent.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(9),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 17, color: accent),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.textPrimary,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                sub,
                style: TextStyle(
                  fontSize: 10.5,
                  color: AppPalette.textMuted,
                ),
              ),
            ],
          ),
        ),
        Icon(Icons.check, size: 14, color: accent),
      ],
    );
  }
}

// ─── CTA + Back chip + grid bg ───────────────────────────────────

class _BeginCalibrationButton extends StatelessWidget {
  const _BeginCalibrationButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppPalette.amber, Color(0xFFFBBF24)],
            ),
            boxShadow: [
              BoxShadow(
                color: AppPalette.amber.withValues(alpha: 0.55),
                blurRadius: 28,
              ),
            ],
          ),
          child: Text(
            'BEGIN CALIBRATION  →',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: AppPalette.voidBg,
            ),
          ),
        ),
      ),
    );
  }
}

class _BackChip extends StatelessWidget {
  const _BackChip({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppPalette.purple.withValues(alpha: 0.12),
          border: Border.all(
            color: AppPalette.purple.withValues(alpha: 0.25),
          ),
        ),
        child: const Icon(
          Icons.chevron_left,
          size: 18,
          color: AppPalette.textPrimary,
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppPalette.amber.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    const step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) => false;
}
