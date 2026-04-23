import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/tokens.dart';
import '../widgets/buttons.dart';
import '../widgets/neon_card.dart';
import '../widgets/placeholder_block.dart';
import '../widgets/screen_base.dart';
import '../widgets/system_header.dart';

/// PRD §8 Screen 20 — Challenge System hype.
class ChallengeSystemScreen extends StatelessWidget {
  const ChallengeSystemScreen({super.key});

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
                    const SizedBox(height: AppSpace.s6),
                    const PlaceholderBlock(
                      label: 'CHALLENGE SYSTEM ART',
                      height: 220,
                      color: AppPalette.flame,
                    ),
                    const Spacer(),
                    const SizedBox(height: AppSpace.s5),
                    NeonCard(
                      glow: GlowColor.flame,
                      padding: const EdgeInsets.all(AppSpace.s6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SystemHeader(
                            kicker: 'CHALLENGE SYSTEM',
                            color: AppPalette.flame,
                          ),
                          const SizedBox(height: AppSpace.s4),
                          Text(
                            'QUESTS FUEL\nTHE GRIND',
                            style: AppType.displayXL(
                              color: AppPalette.textPrimary,
                            ).copyWith(height: 44 / 40),
                          ),
                          const SizedBox(height: AppSpace.s4),
                          const _QuestTier(
                            label: 'DAILY',
                            range: '40 – 100 XP',
                            color: AppPalette.green,
                          ),
                          const SizedBox(height: AppSpace.s3),
                          const _QuestTier(
                            label: 'WEEKLY',
                            range: '200 – 500 XP',
                            color: AppPalette.purple,
                          ),
                          const SizedBox(height: AppSpace.s3),
                          const _QuestTier(
                            label: 'BOSS',
                            range: '2 000+ XP',
                            color: AppPalette.flame,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpace.s4),
                    PrimaryButton(
                      label: 'BRING ON THE CHALLENGES',
                      onTap: () => context.go('/paywall'),
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

class _QuestTier extends StatelessWidget {
  const _QuestTier({
    required this.label,
    required this.range,
    required this.color,
  });

  final String label;
  final String range;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppType.label(color: color))),
          Text(
            range,
            style: AppType.monoMD(color: color),
          ),
        ],
      ),
    );
  }
}
