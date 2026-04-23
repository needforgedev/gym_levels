import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/tokens.dart';
import '../widgets/buttons.dart';
import '../widgets/neon_card.dart';
import '../widgets/placeholder_block.dart';
import '../widgets/screen_base.dart';
import '../widgets/system_header.dart';

/// PRD §8 Pre-quiz Slide 2 — "LEVEL UP IRL" / progression system hype.
class ProgressionHypeScreen extends StatelessWidget {
  const ProgressionHypeScreen({super.key});

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
                      label: 'EXPLOSION / RANK COINS',
                      height: 260,
                      color: AppPalette.xpGold,
                    ),
                    const Spacer(),
                    const SizedBox(height: AppSpace.s6),
                    NeonCard(
                      glow: GlowColor.xp,
                      padding: const EdgeInsets.all(AppSpace.s6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SystemHeader(
                            kicker: 'PROGRESSION SYSTEM',
                            color: AppPalette.xpGold,
                          ),
                          const SizedBox(height: AppSpace.s4),
                          Text(
                            'LEVEL\nUP IRL.',
                            style: AppType.displayXL(
                              color: AppPalette.textPrimary,
                            ).copyWith(height: 44 / 40),
                          ),
                          const SizedBox(height: AppSpace.s4),
                          const _XpRow(label: 'STRENGTH', amount: '+25 XP'),
                          const SizedBox(height: AppSpace.s3),
                          const _XpRow(label: 'ENDURANCE', amount: '+18 XP'),
                          const SizedBox(height: AppSpace.s3),
                          const _XpRow(label: 'POWER', amount: '+32 XP'),
                          const SizedBox(height: AppSpace.s4),
                          Text(
                            'Every rep earns XP. Every level unlocks new quests.',
                            style: AppType.bodyMD(
                              color: AppPalette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpace.s4),
                    PrimaryButton(
                      label: 'CONTINUE',
                      onTap: () => context.go('/register'),
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

class _XpRow extends StatelessWidget {
  const _XpRow({required this.label, required this.amount});
  final String label;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppType.label(color: AppPalette.textSecondary),
          ),
        ),
        Text(
          amount,
          style: AppType.monoMD(color: AppPalette.xpGold),
        ),
      ],
    );
  }
}
