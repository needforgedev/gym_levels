import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/tokens.dart';
import '../widgets/buttons.dart';
import '../widgets/neon_card.dart';
import '../widgets/placeholder_block.dart';
import '../widgets/rank_badge.dart';
import '../widgets/screen_base.dart';
import '../widgets/system_header.dart';

/// PRD §8 Pre-quiz Slide 1 — "TRACK EVERY GAIN".
class RanksHypeScreen extends StatelessWidget {
  const RanksHypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenBase(
      background: AppPalette.obsidian,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpace.s7),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpace.s7),
                    const PlaceholderBlock(
                      label: 'ANIME HERO KEY ART',
                      height: 260,
                      color: AppPalette.teal,
                    ),
                    const Spacer(),
                    const SizedBox(height: AppSpace.s6),
                    NeonCard(
                      glow: GlowColor.teal,
                      padding: const EdgeInsets.all(AppSpace.s6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SystemHeader(
                            kicker: 'MUSCLE RANKS',
                            color: AppPalette.teal,
                          ),
                          const SizedBox(height: AppSpace.s4),
                          Text(
                            'TRACK\nEVERY GAIN',
                            style: AppType.displayXL(
                              color: AppPalette.textPrimary,
                            ).copyWith(height: 44 / 40),
                          ),
                          const SizedBox(height: AppSpace.s4),
                          Text(
                            'Every muscle gets ranked Bronze → Grandmaster. Lift heavy, hit PRs, watch your rank climb.',
                            style: AppType.bodyMD(
                              color: AppPalette.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpace.s5),
                          const _TierRow(),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpace.s4),
                    PrimaryButton(
                      label: 'CONTINUE',
                      onTap: () => context.go('/hype/progression'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TierRow extends StatelessWidget {
  const _TierRow();

  @override
  Widget build(BuildContext context) {
    const ranks = [
      (Rank.bronze, 'III'),
      (Rank.silver, 'II'),
      (Rank.gold, 'I'),
      (Rank.platinum, 'I'),
      (Rank.diamond, 'I'),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final r in ranks)
          RankBadge(rank: r.$1, subRank: r.$2, size: 36),
      ],
    );
  }
}
