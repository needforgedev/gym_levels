import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/tokens.dart';
import '../widgets/screen_base.dart';

/// Hype slides — matches design v2 (`design/v2/screens-hype.jsx`).
///
/// Two swipe-able slides on a single screen:
///   - Slide 1 "TRACK EVERY GAIN" with hero portrait + 6 tier chips
///   - Slide 2 "LEVEL UP IRL" with conic-gradient XP burst + 3 attribute rows
///
/// Top-right `Skip` link, dot indicator above the CTA. CTA reads
/// `Continue` on slide 0 and `Level Up IRL →` on slide 1; tapping it on
/// the second slide advances to `/signup` (auth-gate per socials_plan
/// Path A — every user gets a cloud account on day one).
class RanksHypeScreen extends StatefulWidget {
  const RanksHypeScreen({super.key});

  @override
  State<RanksHypeScreen> createState() => _RanksHypeScreenState();
}

class _RanksHypeScreenState extends State<RanksHypeScreen> {
  final _pager = PageController();
  int _idx = 0;

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  void _next() {
    if (_idx < 1) {
      _pager.animateToPage(
        1,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      context.go('/signup');
    }
  }

  void _skip() => context.go('/signup');

  @override
  Widget build(BuildContext context) {
    return ScreenBase(
      background: AppPalette.voidBg,
      child: Stack(
        children: [
          Positioned.fill(child: _AmbientBg(slideIndex: _idx)),
          Column(
            children: [
              // Top bar with Skip.
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _skip,
                    style: TextButton.styleFrom(
                      foregroundColor: AppPalette.textMuted,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                    ),
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
              // Page view.
              Expanded(
                child: PageView(
                  controller: _pager,
                  onPageChanged: (i) => setState(() => _idx = i),
                  children: const [_Slide1(), _Slide2()],
                ),
              ),
              // Dots.
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < 2; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == _idx ? 24 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: i == _idx
                              ? AppPalette.amber
                              : AppPalette.purple.withValues(alpha: 0.3),
                        ),
                      ),
                  ],
                ),
              ),
              // CTA.
              Padding(
                padding: EdgeInsets.fromLTRB(
                  28,
                  0,
                  28,
                  60 + MediaQuery.of(context).padding.bottom,
                ),
                child: _CtaButton(
                  label: _idx == 0 ? 'CONTINUE' : 'LEVEL UP IRL →',
                  onTap: _next,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Ambient background — switches per slide ──────────────────────────
class _AmbientBg extends StatelessWidget {
  const _AmbientBg({required this.slideIndex});
  final int slideIndex;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: slideIndex == 0
            ? const _BgViolet(key: ValueKey('violet'))
            : const _BgAmberViolet(key: ValueKey('amber')),
      ),
    );
  }
}

class _BgViolet extends StatelessWidget {
  const _BgViolet({super.key});
  @override
  Widget build(BuildContext context) => DecoratedBox(
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
        child: const SizedBox.expand(),
      );
}

class _BgAmberViolet extends StatelessWidget {
  const _BgAmberViolet({super.key});
  @override
  Widget build(BuildContext context) => Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.4),
                  radius: 1.0,
                  colors: [
                    AppPalette.amber.withValues(alpha: 0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, 0.4),
                  radius: 1.0,
                  colors: [
                    AppPalette.purple.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      );
}

// ─── Slide 1: TRACK EVERY GAIN ────────────────────────────────────────
class _Slide1 extends StatelessWidget {
  const _Slide1();

  static const _tiers = [
    ('BRONZE', Color(0xFFCD7F32)),
    ('SILVER', Color(0xFFB8B8C8)),
    ('GOLD', Color(0xFFF5A623)),
    ('PLATINUM', Color(0xFF6FC9FF)),
    ('DIAMOND', Color(0xFF19E3E3)),
    ('MASTER', Color(0xFFC4B5FD)),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
      child: Column(
        children: [
          // Hero portrait card.
          SizedBox(
            width: 230,
            height: 270,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Halo — Positioned with negative offsets is the
                // Flutter equivalent of the design's `inset: -16`
                // CSS rule. Negative padding isn't allowed by the
                // framework.
                Positioned(
                  left: -16,
                  top: -16,
                  right: -16,
                  bottom: -16,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: RadialGradient(
                        colors: [
                          AppPalette.purple.withValues(alpha: 0.4),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.65],
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2D1B4E), Color(0xFF1A0F2B)],
                    ),
                    border: Border.all(
                      color: AppPalette.purple.withValues(alpha: 0.4),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 50,
                        offset: const Offset(0, 20),
                      ),
                      BoxShadow(
                        color: AppPalette.purple.withValues(alpha: 0.3),
                        blurRadius: 40,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/hero-character.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Sparkle decoration top-right.
                Positioned(
                  top: -8,
                  right: -8,
                  child: Icon(
                    Icons.auto_awesome,
                    color: AppPalette.amber,
                    size: 24,
                    shadows: [
                      Shadow(
                        color: AppPalette.amber.withValues(alpha: 0.7),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Title with amber GAIN.
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: AppType.displayXL(color: AppPalette.textPrimary)
                  .copyWith(fontSize: 44, height: 1.05),
              children: [
                const TextSpan(text: 'TRACK EVERY '),
                TextSpan(
                  text: 'GAIN',
                  style: AppType.displayXL(color: AppPalette.amber).copyWith(
                    fontSize: 44,
                    height: 1.05,
                    shadows: [
                      Shadow(
                        color: AppPalette.amber.withValues(alpha: 0.6),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              'Every muscle gets a rank. Every rep moves you forward. Your body is the game.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppPalette.textMuted,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 28),
          // Tier chips.
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              for (final (label, color) in _tiers)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: color.withValues(alpha: 0.10),
                    border: Border.all(
                      color: color.withValues(alpha: 0.33),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: color,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Slide 2: LEVEL UP IRL with XP burst ──────────────────────────────
class _Slide2 extends StatelessWidget {
  const _Slide2();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
      child: Column(
        children: [
          // XP burst.
          SizedBox(
            width: 260,
            height: 240,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer halo.
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppPalette.amber.withValues(alpha: 0.5),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.65],
                      ),
                    ),
                  ),
                ),
                // 4 burst lines at 0/45/90/135 deg.
                for (final angle in const [0.0, 45.0, 90.0, 135.0])
                  Transform.rotate(
                    angle: angle * math.pi / 180,
                    child: Container(
                      width: 2,
                      height: 90,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [AppPalette.amber, Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                // Conic-gradient outer ring.
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const SweepGradient(
                      colors: [
                        AppPalette.amber,
                        AppPalette.amberSoft,
                        AppPalette.amber,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppPalette.amber.withValues(alpha: 0.6),
                        blurRadius: 40,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppPalette.voidBg,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '+XP',
                            style: AppType.displayLG(color: AppPalette.amber)
                                .copyWith(fontSize: 36, height: 1),
                          ),
                          Text(
                            'EARNED',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                              color: const Color(0xFFC4B5FD),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Title with violet IRL.
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: AppType.displayXL(color: AppPalette.textPrimary)
                  .copyWith(fontSize: 44, height: 1.05),
              children: [
                const TextSpan(text: 'LEVEL UP '),
                TextSpan(
                  text: 'IRL',
                  style: AppType.displayXL(color: AppPalette.purpleSoft)
                      .copyWith(
                    fontSize: 44,
                    height: 1.05,
                    shadows: [
                      Shadow(
                        color: AppPalette.purple.withValues(alpha: 0.7),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              'Real reps. Real XP. Real gains. Every session counts towards your next rank.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppPalette.textMuted,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Attribute rows.
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Column(
              children: const [
                _AttrRow(
                  label: 'STRENGTH',
                  value: '+42 XP',
                  color: AppPalette.amber,
                ),
                SizedBox(height: 8),
                _AttrRow(
                  label: 'ENDURANCE',
                  value: '+28 XP',
                  color: AppPalette.purple,
                ),
                SizedBox(height: 8),
                _AttrRow(
                  label: 'POWER',
                  value: '+56 XP',
                  color: AppPalette.teal,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AttrRow extends StatelessWidget {
  const _AttrRow({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: AppPalette.purple.withValues(alpha: 0.08),
        border: Border.all(
          color: color.withValues(alpha: 0.27),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
              color: AppPalette.textPrimary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'JetBrainsMono',
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── CTA pill ─────────────────────────────────────────────────────────
class _CtaButton extends StatelessWidget {
  const _CtaButton({required this.label, required this.onTap});
  final String label;
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
              colors: [AppPalette.amber, AppPalette.amberSoft],
            ),
            boxShadow: [
              BoxShadow(
                color: AppPalette.amber.withValues(alpha: 0.45),
                blurRadius: 24,
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
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
