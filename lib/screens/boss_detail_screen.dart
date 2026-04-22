import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/tokens.dart';
import '../widgets/buttons.dart';
import '../widgets/neon_card.dart';
import '../widgets/placeholder_block.dart';
import '../widgets/progress_bar.dart';
import '../widgets/screen_base.dart';
import '../widgets/system_header.dart';

class BossDetailScreen extends StatelessWidget {
  const BossDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenBase(
      child: Column(
        children: [
          SizedBox(
            height: 260,
            child: Stack(
              children: [
                const PlaceholderBlock(
                  label: 'BOSS FULL-BLEED ART',
                  height: 260,
                  color: AppPalette.flame,
                  border: false,
                  borderRadius: BorderRadius.zero,
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppPalette.voidBg.withValues(alpha: 0.0),
                          AppPalette.voidBg,
                        ],
                        stops: const [0.0, 0.4, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: InkWell(
                    onTap: () => context.go('/quests'),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppPalette.carbon,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppPalette.strokeHairline),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: AppPalette.textPrimary,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.s5,
                0,
                AppSpace.s5,
                AppSpace.s5,
              ),
              children: [
                Transform.translate(
                  offset: const Offset(0, -40),
                  child: NeonCard(
                    glow: GlowColor.flame,
                    padding: const EdgeInsets.all(AppSpace.s6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SystemHeader(
                          kicker: 'BOSS ENGAGEMENT · 3 DAYS LEFT',
                          color: AppPalette.flame,
                        ),
                        const SizedBox(height: AppSpace.s4),
                        Text(
                          'THE IRON\nGAUNTLET',
                          style: AppType.displayXL(
                            color: AppPalette.textPrimary,
                          ).copyWith(height: 44 / 40),
                        ),
                        const SizedBox(height: AppSpace.s4),
                        Text(
                          'A weekly boss quest. Complete the prescribed volume to break the gauntlet and earn a legendary permanent buff.',
                          style: AppType.bodyMD(
                            color: AppPalette.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpace.s5),
                        const Bar(
                          percent: 60,
                          color: AppPalette.flame,
                          height: 6,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '60% COMPLETE',
                              style: AppType.monoMD(
                                color: AppPalette.textSecondary,
                              ).copyWith(fontSize: 12),
                            ),
                            Text(
                              '+500 XP',
                              style: AppType.monoMD(color: AppPalette.xpGold)
                                  .copyWith(fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpace.s5),
                        Text(
                          'OBJECTIVES',
                          style: AppType.label(color: AppPalette.textMuted),
                        ),
                        const SizedBox(height: AppSpace.s3),
                        const _BossObjective(
                          label: '5 PUSH WORKOUTS',
                          progress: '3 / 5',
                        ),
                        const SizedBox(height: AppSpace.s3),
                        const _BossObjective(
                          label: '10KM TOTAL RUN',
                          progress: '7.2 / 10KM',
                        ),
                        const SizedBox(height: AppSpace.s3),
                        const _BossObjective(
                          label: 'PROTEIN GOAL × 5 DAYS',
                          progress: '5 / 5',
                          done: true,
                        ),
                      ],
                    ),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -28),
                  child: NeonCard(
                    glow: GlowColor.xp,
                    padding: const EdgeInsets.all(AppSpace.s4),
                    pulse: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'REWARD ON COMPLETION',
                          style: AppType.label(color: AppPalette.xpGold),
                        ),
                        const SizedBox(height: AppSpace.s3),
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppPalette.xpGold.withValues(alpha: 0.13),
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                border: Border.all(color: AppPalette.xpGold),
                              ),
                              child: const Icon(
                                Icons.star,
                                color: AppPalette.xpGold,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: AppSpace.s4),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'IRON HEART BUFF',
                                    style: AppType.bodyLG(
                                      color: AppPalette.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '+10% XP on compound lifts for 7 days',
                                    style: AppType.bodySM(
                                      color: AppPalette.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                PrimaryButton(
                  label: 'START PUSH WORKOUT',
                  onTap: () => context.go('/workout'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BossObjective extends StatelessWidget {
  const _BossObjective({
    required this.label,
    required this.progress,
    this.done = false,
  });

  final String label;
  final String progress;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.s3),
      decoration: BoxDecoration(
        color: done ? AppPalette.green.withValues(alpha: 0.08) : AppPalette.slate,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: done ? AppPalette.green : AppPalette.strokeSubtle,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: done ? AppPalette.green : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: done ? AppPalette.green : AppPalette.strokeSubtle,
              ),
            ),
            child: done
                ? const Icon(Icons.check, color: AppPalette.obsidian, size: 12)
                : null,
          ),
          const SizedBox(width: AppSpace.s3),
          Expanded(
            child: Text(
              label,
              style: AppType.bodyMD(color: AppPalette.textPrimary).copyWith(
                decoration: done ? TextDecoration.lineThrough : null,
                color: done
                    ? AppPalette.textPrimary.withValues(alpha: 0.6)
                    : AppPalette.textPrimary,
              ),
            ),
          ),
          Text(
            progress,
            style: AppType.monoMD(
              color: done ? AppPalette.green : AppPalette.textMuted,
            ).copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
