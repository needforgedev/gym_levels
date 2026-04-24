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

  /// Label for each milestone band. Shown as the headline on the
  /// celebration screen so 7 and 30 don't feel identical.
  static String _titleFor(int streak) {
    if (streak >= 365) return 'IMMORTAL YEAR';
    if (streak >= 180) return 'HALF-YEAR LEGEND';
    if (streak >= 90) return 'SEASON SEALED';
    if (streak >= 60) return 'IRON RESOLVE';
    if (streak >= 30) return 'IRON MONTH';
    if (streak >= 14) return 'FORTNIGHT FORGED';
    if (streak >= 7) return 'WEEK-STRONG';
    return 'MILESTONE';
  }

  static String _subtitleFor(int streak) {
    if (streak >= 365) return 'A full year of the grind — permanent buff unlocked.';
    if (streak >= 180) return 'Six months in. The system recognises you now.';
    if (streak >= 90) return 'Ninety days — a full training season on lock.';
    if (streak >= 60) return 'Sixty days. The habit is no longer a choice.';
    if (streak >= 30) return 'Thirty days clean. Iron Heart buff active.';
    if (streak >= 14) return 'Two full weeks without breaking rhythm.';
    if (streak >= 7) return 'Seven days in a row. The fire is real.';
    return 'Streak integrity: holding.';
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<PlayerState>();
    final title = _titleFor(s.streak);
    final subtitle = _subtitleFor(s.streak);
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
                  title,
                  textAlign: TextAlign.center,
                  style: AppType.displayLG(color: AppPalette.textPrimary),
                ),
                const SizedBox(height: AppSpace.s3),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: AppType.bodyMD(color: AppPalette.textSecondary),
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
