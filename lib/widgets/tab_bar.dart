import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import '../theme/tokens.dart';

enum AppTab { home, quests, leaderboard, streak, profile }

/// Floating glass pill tab bar with a center hero leaderboard button.
///
/// Layout (per the v1-improvements design — `shared.jsx` lines 145-297):
///   • 66px tall translucent-glass pill (24px backdrop blur, violet
///     border, layered shadows, inner radial ambient + top shine).
///   • 4 regular pills (Home, Quests, Streak, Profile) — amber gradient
///     active state with a soft glow.
///   • A 64×64 **circular gold "Leaderboard" button** that floats 28px
///     above the bar's top edge with a pulsing animation, rotating
///     conic-gradient shimmer, and a halo ring that scales out.
///   • "LEADERBOARD" label sits BELOW the bar in amber mono.
///
/// Caller should layer this over the screen body via `Stack` and
/// reserve [InAppShell.tabBarSafeBottom] worth of bottom padding on
/// scrollable content so nothing sits under it.
class AppTabBar extends StatefulWidget {
  const AppTabBar({
    super.key,
    required this.active,
    required this.onChange,
  });

  final AppTab active;
  final ValueChanged<AppTab> onChange;

  @override
  State<AppTabBar> createState() => _AppTabBarState();
}

class _AppTabBarState extends State<AppTabBar>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _halo;
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    _halo = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _halo.dispose();
    _shimmer.dispose();
    super.dispose();
  }

  static const _normalTabs = [
    (AppTab.home, Icons.home_outlined, 'Home'),
    (AppTab.quests, Icons.menu_book_outlined, 'Quests'),
    // Center spacer goes here in the row (handled separately).
    (AppTab.streak, Icons.local_fire_department_outlined, 'Streak'),
    (AppTab.profile, Icons.emoji_events_outlined, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // Bar (66) + label space below (~16) + floating button rise (~28).
      // Stack uses Clip.none so the floating button paints outside this
      // box anyway; the height just gives the layout something to lay
      // its children against.
      height: 86,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // Bar surface — translucent glass pill with backdrop blur.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BarSurface(
              regular: _normalTabs,
              active: widget.active,
              onChange: widget.onChange,
            ),
          ),
          // Floating gold Leaderboard button — extends ~27px above the
          // bar's top edge to match the design's `marginTop: -28`.
          //
          // Bar surface top sits at y=20 within this Stack (Stack is
          // 86 tall, bar 66 at bottom). Design wants ball top at
          // bar_top − 27 = y=−7. The 88×88 SizedBox centers the 64×64
          // gold ball, so SizedBox top is 12px above ball top → −19.
          Positioned(
            top: -19,
            child: _LeaderboardHero(
              active: widget.active == AppTab.leaderboard,
              pulse: _pulse,
              halo: _halo,
              shimmer: _shimmer,
              onTap: () => widget.onChange(AppTab.leaderboard),
            ),
          ),
          // "LEADERBOARD" label — sits INSIDE the bar near the bottom
          // edge, matching the design's `bottom: -16` from the
          // floating button (which lands ≈9px above the bar bottom).
          Positioned(
            bottom: 9,
            child: Text(
              'LEADERBOARD',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: AppPalette.amber,
                shadows: [
                  Shadow(
                    color: AppPalette.amber.withValues(alpha: 0.6),
                    blurRadius: 8,
                  ),
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.8),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bar surface (translucent glass pill) ────────────────────────

class _BarSurface extends StatelessWidget {
  const _BarSurface({
    required this.regular,
    required this.active,
    required this.onChange,
  });

  final List<(AppTab, IconData, String)> regular;
  final AppTab active;
  final ValueChanged<AppTab> onChange;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(33),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: 66,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xB81A0F2B),
                Color(0xC70A0612),
              ],
            ),
            borderRadius: BorderRadius.circular(33),
            border: Border.all(
              color: AppPalette.purple.withValues(alpha: 0.30),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 40,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: AppPalette.purple.withValues(alpha: 0.4),
                blurRadius: 30,
                spreadRadius: -8,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Inner violet ambient gradient.
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(33),
                      gradient: RadialGradient(
                        center: const Alignment(0, 1.5),
                        radius: 1.0,
                        colors: [
                          AppPalette.purple.withValues(alpha: 0.20),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Top shine highlight.
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    height: 1,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.transparent,
                          Color(0x40FFFFFF),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // 4 regular pills + invisible spacer in the middle.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _TabPill(
                      icon: regular[0].$2,
                      label: regular[0].$3,
                      active: active == regular[0].$1,
                      onTap: () => onChange(regular[0].$1),
                    ),
                    _TabPill(
                      icon: regular[1].$2,
                      label: regular[1].$3,
                      active: active == regular[1].$1,
                      onTap: () => onChange(regular[1].$1),
                    ),
                    // Center spacer so the floating leaderboard button
                    // has room without overlapping the side pills.
                    const SizedBox(width: 64),
                    _TabPill(
                      icon: regular[2].$2,
                      label: regular[2].$3,
                      active: active == regular[2].$1,
                      onTap: () => onChange(regular[2].$1),
                    ),
                    _TabPill(
                      icon: regular[3].$2,
                      label: regular[3].$3,
                      active: active == regular[3].$1,
                      onTap: () => onChange(regular[3].$1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Regular tab pill ────────────────────────────────────────────

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppPalette.amber : AppPalette.textMuted;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(27),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          width: 56,
          height: 54,
          decoration: BoxDecoration(
            gradient: active
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppPalette.amber.withValues(alpha: 0.22),
                      AppPalette.amber.withValues(alpha: 0.08),
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(27),
            border: Border.all(
              color: active
                  ? AppPalette.amber.withValues(alpha: 0.45)
                  : Colors.transparent,
              width: 1,
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppPalette.amber.withValues(alpha: 0.55),
                      blurRadius: 18,
                      spreadRadius: -2,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                transform: Matrix4.translationValues(0, active ? -1 : 0, 0),
                child: Icon(
                  icon,
                  size: 20,
                  color: color,
                  shadows: active
                      ? [
                          Shadow(
                            color: AppPalette.amber.withValues(alpha: 0.8),
                            blurRadius: 6,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.9,
                  color: color,
                  shadows: active
                      ? [
                          Shadow(
                            color: AppPalette.amber.withValues(alpha: 0.4),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Floating gold leaderboard button ────────────────────────────

class _LeaderboardHero extends StatelessWidget {
  const _LeaderboardHero({
    required this.active,
    required this.pulse,
    required this.halo,
    required this.shimmer,
    required this.onTap,
  });

  final bool active;
  final AnimationController pulse;
  final AnimationController halo;
  final AnimationController shimmer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 88,
          height: 88,
          child: Center(
            child: AnimatedBuilder(
              animation: pulse,
              builder: (_, _) {
                final p = pulse.value; // 0..1
                final scale = 1.0 + 0.04 * p;
                final lift = -2 * p;
                return Transform.translate(
                  offset: Offset(0, lift),
                  child: Transform.scale(
                    scale: scale,
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          // Halo — outer ring that scales + fades.
                          AnimatedBuilder(
                            animation: halo,
                            builder: (_, _) {
                              final t = halo.value; // 0..1
                              final scaleH = 1.0 + 0.15 * t;
                              final op = (0.6 - 0.6 * t).clamp(0.0, 1.0);
                              return IgnorePointer(
                                child: Transform.scale(
                                  scale: scaleH,
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppPalette.amber.withValues(
                                            alpha: 0.5 * op),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          // Gold ball.
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const RadialGradient(
                                center: Alignment(-0.4, -0.4),
                                colors: [
                                  Color(0xFFFBBF24),
                                  AppPalette.amber,
                                  Color(0xFF8C5814),
                                ],
                                stops: [0, 0.55, 1.0],
                              ),
                              border: Border.all(
                                color: const Color(0xFFFCD34D),
                                width: 2,
                              ),
                              boxShadow: [
                                // Void ring so the bar visually parts
                                // around the floating button.
                                BoxShadow(
                                  color: AppPalette.voidBg
                                      .withValues(alpha: 0.9),
                                  blurRadius: 0,
                                  spreadRadius: 4,
                                ),
                                BoxShadow(
                                  color: AppPalette.amber
                                      .withValues(alpha: 0.85),
                                  blurRadius: 28,
                                ),
                                BoxShadow(
                                  color: AppPalette.amber
                                      .withValues(alpha: 0.45),
                                  blurRadius: 22,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                          ),
                          // Conic-gradient shimmer (rotating sweep over the ball).
                          AnimatedBuilder(
                            animation: shimmer,
                            builder: (_, _) => IgnorePointer(
                              child: ClipOval(
                                child: SizedBox(
                                  width: 60,
                                  height: 60,
                                  child: Transform.rotate(
                                    angle: shimmer.value * 2 * math.pi,
                                    child: const _ConicShimmer(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Trophy / barbell-figure icon.
                          Icon(
                            active
                                ? Icons.emoji_events
                                : Icons.fitness_center,
                            size: 26,
                            color: AppPalette.voidBg,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                offset: const Offset(0, 1),
                              ),
                              Shadow(
                                color: Colors.white.withValues(alpha: 0.5),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ConicShimmer extends StatelessWidget {
  const _ConicShimmer();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: const _ConicShimmerPainter());
  }
}

class _ConicShimmerPainter extends CustomPainter {
  const _ConicShimmerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // 60° highlight wedge sweeping. Approximated with a SweepGradient.
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: size.width / 2,
    );
    final paint = Paint()
      ..blendMode = BlendMode.overlay
      ..shader = const SweepGradient(
        colors: [
          Colors.transparent,
          Colors.transparent,
          Color(0x59FFFFFF), // ~35% white
          Colors.transparent,
          Colors.transparent,
        ],
        stops: [0, 0.10, 0.18, 0.30, 1.0],
      ).createShader(rect);
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ConicShimmerPainter old) => false;
}
