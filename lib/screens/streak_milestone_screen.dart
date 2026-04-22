import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../state/player_state.dart';
import '../theme/tokens.dart';
import '../widgets/big_flame.dart';
import '../widgets/buttons.dart';
import '../widgets/screen_base.dart';
import '../widgets/system_header.dart';

class StreakMilestoneScreen extends StatelessWidget {
  const StreakMilestoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<PlayerState>();
    return ScreenBase(
      background: AppPalette.obsidian,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppPalette.flame.withValues(alpha: 0.13),
                    Colors.transparent,
                  ],
                  radius: 0.6,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpace.s8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SystemHeader(
                  kicker: 'MILESTONE ACHIEVED',
                  color: AppPalette.flame,
                ),
                const SizedBox(height: AppSpace.s7),
                const SizedBox(
                  width: 160,
                  height: 160,
                  child: BigFlame(size: 160),
                ),
                const SizedBox(height: AppSpace.s4),
                Text(
                  '${s.streak}',
                  style: AppType.monoXL(color: AppPalette.flame).copyWith(
                    fontSize: 72,
                    shadows: [
                      Shadow(color: AppPalette.flame, blurRadius: 24),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.s1),
                Text(
                  'DAY STREAK',
                  style: AppType.displayLG(color: AppPalette.textPrimary),
                ),
                const SizedBox(height: AppSpace.s3),
                Text(
                  '…signal lock holding. system integrity: stable.',
                  textAlign: TextAlign.center,
                  style: AppType.system(color: AppPalette.textSecondary),
                ),
                const SizedBox(height: AppSpace.s8),
                PrimaryButton(
                  label: 'CONTINUE GRIND',
                  onTap: () => context.go('/home'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
