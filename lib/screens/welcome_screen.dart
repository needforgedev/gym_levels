import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/tokens.dart';
import '../widgets/screen_base.dart';

/// Splash / launch screen — matches design v2 (`design/v2/screens-splash.jsx`).
///
/// Sequence:
///   1. Mount: starry particle field fades in; circular hero portrait with
///      a violet radial halo behind it; "LEVEL UP" violet→white gradient,
///      "— IRL —" amber, "TRAIN · TRACK · TRANSFORM" muted strapline.
///   2. While `_ready == false`: a 180×3 violet shimmer loader strip with
///      `INITIALIZING SYSTEM…` mono caption.
///   3. After ~1.8s the loader is replaced by a full-width amber-gradient
///      pill `TAP TO BEGIN` button that routes to the hype slides.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  bool _ready = false;
  late final AnimationController _loader;
  late final AnimationController _enter;
  late final List<_Particle> _particles;
  Timer? _readyTimer;

  @override
  void initState() {
    super.initState();
    _loader = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    final rng = math.Random(42);
    _particles = List.generate(20, (i) {
      final size = 2 + rng.nextDouble() * 3;
      return _Particle(
        leftFrac: rng.nextDouble(),
        topFrac: rng.nextDouble(),
        size: size,
        amber: i % 3 == 0,
        period: 2 + rng.nextDouble() * 2,
        delay: rng.nextDouble() * 2,
      );
    });

    // Use a stored Timer so dispose() can cancel it. `Future.delayed`
    // can't be cancelled, which trips the widget-test framework's
    // pending-timer check at teardown.
    _readyTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    _readyTimer?.cancel();
    _loader.dispose();
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenBase(
      background: AppPalette.voidBg,
      child: Stack(
        children: [
          // Top-centered violet radial wash.
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.4),
                    radius: 1.0,
                    colors: [
                      AppPalette.purple.withValues(alpha: 0.25),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Starry sparkle field.
          Positioned.fill(child: _ParticleField(particles: _particles)),

          // Center column: hero portrait + title block.
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FadeTransition(
                  opacity: _enter,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.05),
                      end: Offset.zero,
                    ).animate(_enter),
                    child: const _HeroBust(size: 220),
                  ),
                ),
                const SizedBox(height: 28),
                FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _enter,
                    curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
                  ),
                  child: const _TitleBlock(),
                ),
              ],
            ),
          ),

          // Bottom: loader → CTA.
          Positioned(
            left: 40,
            right: 40,
            bottom: 60 + MediaQuery.of(context).padding.bottom,
            child: _ready
                ? _BeginButton(onTap: () => context.go('/hype/ranks'))
                : _LoaderStrip(controller: _loader),
          ),
        ],
      ),
    );
  }
}

// ─── Hero bust portrait (circular violet halo + painted face) ─────────
class _HeroBust extends StatelessWidget {
  const _HeroBust({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer halo — violet radial blur.
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppPalette.purple.withValues(alpha: 0.45),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.65],
                ),
              ),
            ),
          ),
          // Portrait disc.
          Container(
            width: size * 0.85,
            height: size * 0.85,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2D1B4E), Color(0xFF1A0F2B)],
              ),
              border: Border.all(
                color: AppPalette.purple.withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppPalette.purple.withValues(alpha: 0.5),
                  blurRadius: 40,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: -10,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/hero-bust.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Title block: LEVEL UP / — IRL — / TRAIN · TRACK · TRANSFORM ──────
class _TitleBlock extends StatelessWidget {
  const _TitleBlock();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // "LEVEL UP" — white→violet gradient.
          ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppPalette.textPrimary, Color(0xFFA78BFA)],
            ).createShader(rect),
            child: Text(
              'LEVEL UP',
              textAlign: TextAlign.center,
              style: AppType.displayXL(color: Colors.white).copyWith(
                fontSize: 64,
                height: 0.9,
                letterSpacing: 2.5,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '— IRL —',
            textAlign: TextAlign.center,
            style: AppType.displayLG(color: AppPalette.amber).copyWith(
              fontSize: 38,
              shadows: [
                Shadow(
                  color: AppPalette.amber.withValues(alpha: 0.6),
                  blurRadius: 20,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'TRAIN · TRACK · TRANSFORM',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 4,
              color: AppPalette.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Loader strip ─────────────────────────────────────────────────────
class _LoaderStrip extends StatelessWidget {
  const _LoaderStrip({required this.controller});
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 180,
          height: 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Stack(
              children: [
                Container(color: AppPalette.purple.withValues(alpha: 0.15)),
                AnimatedBuilder(
                  animation: controller,
                  builder: (context, _) {
                    final t = controller.value; // 0..1
                    final left = (-0.4 + t * 1.4).clamp(-0.4, 1.0);
                    return Positioned(
                      left: 180 * left,
                      top: 0,
                      bottom: 0,
                      width: 72,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              AppPalette.purple,
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'INITIALIZING SYSTEM…',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 2,
            fontFamily: 'JetBrainsMono',
            color: AppPalette.textDim,
          ),
        ),
      ],
    );
  }
}

// ─── TAP TO BEGIN amber pill ──────────────────────────────────────────
class _BeginButton extends StatelessWidget {
  const _BeginButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - t)),
          child: child,
        ),
      ),
      child: Material(
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
                colors: [AppPalette.amber, AppPalette.amberSoft],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppPalette.amber.withValues(alpha: 0.5),
                  blurRadius: 30,
                ),
              ],
            ),
            child: Text(
              'TAP TO BEGIN',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                color: AppPalette.voidBg,
                shadows: [
                  Shadow(
                    color: Colors.white.withValues(alpha: 0.3),
                    blurRadius: 0,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Particle field ───────────────────────────────────────────────────
class _Particle {
  const _Particle({
    required this.leftFrac,
    required this.topFrac,
    required this.size,
    required this.amber,
    required this.period,
    required this.delay,
  });
  final double leftFrac;
  final double topFrac;
  final double size;
  final bool amber;
  final double period;
  final double delay;
}

class _ParticleField extends StatefulWidget {
  const _ParticleField({required this.particles});
  final List<_Particle> particles;

  @override
  State<_ParticleField> createState() => _ParticleFieldState();
}

class _ParticleFieldState extends State<_ParticleField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctl,
        builder: (context, _) => CustomPaint(
          painter: _ParticlePainter(
            particles: widget.particles,
            time: _ctl.value * 4, // seconds
          ),
        ),
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({required this.particles, required this.time});
  final List<_Particle> particles;
  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final phase = (time - p.delay) % p.period;
      final t = phase / p.period; // 0..1
      // 0 → 0.5 → 1 maps to opacity 0.3 → 1.0 → 0.3 (ping-pong).
      final opacity = 0.3 + 0.7 * (1 - (t - 0.5).abs() * 2);
      final scale = 0.8 + 0.4 * (1 - (t - 0.5).abs() * 2);
      final color = p.amber ? AppPalette.amber : const Color(0xFFC4B5FD);
      final paint = Paint()
        ..color = color.withValues(alpha: 0.6 * opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.size * 1.5);
      final cx = p.leftFrac * size.width;
      final cy = p.topFrac * size.height;
      canvas.drawCircle(Offset(cx, cy), p.size * scale, paint);
      // Solid core.
      final core = Paint()..color = color.withValues(alpha: opacity);
      canvas.drawCircle(Offset(cx, cy), p.size * scale * 0.7, core);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => true;
}
