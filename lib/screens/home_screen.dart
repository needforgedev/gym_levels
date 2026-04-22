import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../state/player_state.dart';
import '../theme/tokens.dart';
import '../widgets/buttons.dart';
import '../widgets/in_app_shell.dart';
import '../widgets/muscle_figure.dart';
import '../widgets/neon_card.dart';
import '../widgets/pills.dart';
import '../widgets/quest_row.dart';
import '../widgets/rank_badge.dart';
import '../widgets/tab_bar.dart';
import '../widgets/xp_ring.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<PlayerState>();
    return InAppShell(
      active: AppTab.home,
      title: 'HOME',
      child: ListView(
        padding: const EdgeInsets.all(AppSpace.s5),
        children: [
          Text(
            '…welcome back, player.',
            style: AppType.system(color: AppPalette.textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            s.playerName.toUpperCase(),
            style: AppType.displayLG(color: AppPalette.textPrimary),
          ),
          const SizedBox(height: AppSpace.s3),
          Row(
            children: [
              LevelPill(level: s.level),
              const SizedBox(width: AppSpace.s3),
              StreakPill(count: s.streak),
            ],
          ),
          const SizedBox(height: AppSpace.s4),

          // XP ring card
          NeonCard(
            glow: GlowColor.xp,
            padding: const EdgeInsets.all(AppSpace.s6),
            onTap: () => context.go('/profile'),
            child: Row(
              children: [
                XPRing(level: s.level, percent: s.xpPercent, size: 92),
                const SizedBox(width: AppSpace.s5),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NEXT LEVEL',
                        style: AppType.label(color: AppPalette.textMuted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${s.xpCurrent} / ${s.xpMax}',
                        style: AppType.monoLG(color: AppPalette.xpGold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${s.xpMax - s.xpCurrent} XP to LVL ${s.level + 1}',
                        style: AppType.bodySM(color: AppPalette.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.s4),

          // Today's protocol
          NeonCard(
            glow: GlowColor.purple,
            padding: const EdgeInsets.all(AppSpace.s5),
            onTap: () => context.go('/workout'),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "TODAY'S PROTOCOL",
                        style: AppType.label(color: AppPalette.purple),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'PUSH — CHEST & SHOULDERS',
                        style: AppType.displayMD(color: AppPalette.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '6 exercises · ~52 min',
                        style:
                            AppType.bodySM(color: AppPalette.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppPalette.purple,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: AppPalette.purple, blurRadius: 16),
                    ],
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: AppPalette.obsidian,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.s4),

          // Active quests
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'ACTIVE QUESTS',
                style: AppType.label(color: AppPalette.textMuted),
              ),
              GhostButton(
                label: 'VIEW ALL →',
                onTap: () => context.go('/quests'),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s3),
          const QuestRow(
            title: 'HIT 10,000 STEPS',
            type: QuestType.daily,
            progress: 0.72,
            xp: 25,
          ),
          const SizedBox(height: AppSpace.s3),
          const QuestRow(
            title: 'COMPLETE PUSH DAY',
            type: QuestType.daily,
            progress: 0,
            xp: 40,
          ),
          const SizedBox(height: AppSpace.s4),

          // Muscle ranks
          NeonCard(
            glow: GlowColor.none,
            padding: const EdgeInsets.all(AppSpace.s5),
            pulse: false,
            onTap: () => context.go('/profile'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MUSCLE RANKS',
                            style: AppType.label(color: AppPalette.textMuted),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'AVG: GOLD II',
                            style: AppType.displayMD(
                              color: AppPalette.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const MuscleFigure(
                      highlight: MuscleHighlight.chest,
                      color: AppPalette.xpGold,
                      size: 80,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.s4),
                Row(
                  children: const [
                    _MuscleMini(name: 'CHEST', rank: Rank.gold, sub: 'II'),
                    _MuscleMini(name: 'BACK', rank: Rank.silver, sub: 'III'),
                    _MuscleMini(name: 'LEGS', rank: Rank.gold, sub: 'I'),
                    _MuscleMini(name: 'ARMS', rank: Rank.platinum, sub: 'I'),
                    _MuscleMini(name: 'CORE', rank: Rank.silver, sub: 'II'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MuscleMini extends StatelessWidget {
  const _MuscleMini({
    required this.name,
    required this.rank,
    required this.sub,
  });

  final String name;
  final Rank rank;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          RankBadge(rank: rank, subRank: sub, size: 32),
          const SizedBox(height: 4),
          Text(
            name,
            style: AppType.label(color: AppPalette.textMuted).copyWith(
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}
