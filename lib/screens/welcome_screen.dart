import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/tokens.dart';
import '../widgets/buttons.dart';
import '../widgets/neon_card.dart';
import '../widgets/placeholder_block.dart';
import '../widgets/screen_base.dart';
import '../widgets/system_header.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

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
                    const SizedBox(height: AppSpace.s9),
                    const SystemHeader(
                      kicker: 'SYSTEM v1.0',
                      color: AppPalette.teal,
                    ),
                    const SizedBox(height: AppSpace.s6),
                    Text.rich(
                      TextSpan(
                        style: AppType.displayXL(
                          color: AppPalette.textPrimary,
                        ).copyWith(height: 42 / 40),
                        children: [
                          const TextSpan(text: 'LEVEL\nUP\n'),
                          TextSpan(
                            text: 'IRL.',
                            style: AppType.displayXL(color: AppPalette.teal)
                                .copyWith(
                              shadows: [
                                Shadow(
                                  color:
                                      AppPalette.teal.withValues(alpha: 0.66),
                                  blurRadius: 16,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpace.s5),
                    Text(
                      '…scanning biological data.',
                      style: AppType.system(color: AppPalette.textSecondary),
                    ),
                    const SizedBox(height: AppSpace.s7),
                    const PlaceholderBlock(
                      label: 'HERO KEY ART',
                      height: 220,
                      color: AppPalette.teal,
                    ),
                    const Spacer(),
                    const SizedBox(height: AppSpace.s6),
                    NeonCard(
                      glow: GlowColor.teal,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'A gamified fitness protocol. Log sets, earn XP, rank up muscles, maintain streaks, complete quests.',
                            style: AppType.bodyMD(
                              color: AppPalette.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpace.s3),
                          Text(
                            'PROTOCOL STATUS: READY',
                            style: AppType.label(color: AppPalette.teal),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpace.s4),
                    PrimaryButton(
                      label: 'BEGIN REGISTRATION',
                      onTap: () => context.go('/hype/ranks'),
                    ),
                    const SizedBox(height: AppSpace.s3),
                    GhostButton(
                      label: 'ALREADY A PLAYER? SIGN IN',
                      onTap: () => context.go('/home'),
                      fullWidth: true,
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
