import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/tokens.dart';
import '../widgets/screen_base.dart';

/// Challenge System intro — matches design v2 (`design/v2/screens-outro.jsx`).
///
/// Layout: round amber medallion with a trophy icon at the top, big
/// `BRING ON THE / CHALLENGES` headline (CHALLENGES in amber), short
/// strapline, then 3 tier cards (Daily / Weekly / Boss) each showing
/// their icon, label, cadence subtitle, and XP range. Bottom CTA
/// `BRING IT ON →` advances to the paywall.
class ChallengeSystemScreen extends StatelessWidget {
  const ChallengeSystemScreen({super.key});

  static const _tiers = [
    _Tier(
      label: 'DAILY',
      caption: 'Fresh every 24hrs',
      xp: '40-100 XP',
      icon: Icons.gps_fixed,
      color: AppPalette.amber,
      pro: false,
    ),
    _Tier(
      label: 'WEEKLY',
      caption: 'Resets Monday',
      xp: '200-500 XP',
      icon: Icons.calendar_month,
      color: AppPalette.purpleSoft,
      pro: false,
    ),
    _Tier(
      label: 'BOSS',
      caption: 'Multi-week hunt',
      xp: '2000+ XP',
      icon: Icons.shield_outlined,
      color: AppPalette.flame,
      pro: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ScreenBase(
      background: AppPalette.voidBg,
      child: Stack(
        children: [
          // Ambient amber → violet wash (top to bottom).
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.4),
                    radius: 1.0,
                    colors: [
                      AppPalette.amber.withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Column(
            children: [
              // Top back button.
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _BackButton(onTap: () => context.go('/notification-prefs')),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Trophy medallion.
                      Center(child: _TrophyMedallion()),
                      const SizedBox(height: 24),
                      // Title — BRING ON THE / CHALLENGES.
                      Center(
                        child: Text(
                          'BRING ON THE',
                          textAlign: TextAlign.center,
                          style: AppType.displayXL(
                            color: AppPalette.textPrimary,
                          ).copyWith(fontSize: 36, height: 1.05),
                        ),
                      ),
                      Center(
                        child: Text(
                          'CHALLENGES',
                          textAlign: TextAlign.center,
                          style: AppType.displayXL(color: AppPalette.amber)
                              .copyWith(
                            fontSize: 36,
                            height: 1.05,
                            shadows: [
                              Shadow(
                                color: AppPalette.amber.withValues(alpha: 0.6),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Center(
                        child: Text(
                          'Three quest tiers. Infinite motivation.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppPalette.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      for (final t in _tiers) ...[
                        _TierCard(tier: t),
                        const SizedBox(height: 10),
                      ],
                      const SizedBox(height: 16),
                      _BringItOnButton(
                        onTap: () => context.go('/paywall'),
                      ),
                    ],
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

class _Tier {
  const _Tier({
    required this.label,
    required this.caption,
    required this.xp,
    required this.icon,
    required this.color,
    required this.pro,
  });
  final String label;
  final String caption;
  final String xp;
  final IconData icon;
  final Color color;
  final bool pro;
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
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
      ),
    );
  }
}

class _TrophyMedallion extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppPalette.amber, AppPalette.amberSoft],
        ),
        boxShadow: [
          BoxShadow(
            color: AppPalette.amber.withValues(alpha: 0.6),
            blurRadius: 40,
          ),
        ],
      ),
      child: const Icon(
        Icons.emoji_events,
        size: 52,
        color: AppPalette.voidBg,
      ),
    );
  }
}

class _TierCard extends StatelessWidget {
  const _TierCard({required this.tier});
  final _Tier tier;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: tier.color.withValues(alpha: 0.06),
        border: Border.all(
          color: tier.color.withValues(alpha: 0.30),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: tier.color.withValues(alpha: 0.18),
              border: Border.all(
                color: tier.color.withValues(alpha: 0.40),
                width: 1,
              ),
            ),
            child: Icon(tier.icon, size: 18, color: tier.color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      tier.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: tier.color,
                      ),
                    ),
                    if (tier.pro) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: AppPalette.flame.withValues(alpha: 0.20),
                          border: Border.all(
                            color: AppPalette.flame.withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          'PRO',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: AppPalette.flame,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  tier.caption,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppPalette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            tier.xp,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              fontFamily: 'JetBrainsMono',
              color: tier.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _BringItOnButton extends StatelessWidget {
  const _BringItOnButton({required this.onTap});
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
                color: AppPalette.amber.withValues(alpha: 0.5),
                blurRadius: 24,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'BRING IT ON',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  color: AppPalette.voidBg,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward,
                size: 14,
                color: AppPalette.voidBg,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
