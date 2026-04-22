import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/player_state.dart';
import '../theme/tokens.dart';
import '../widgets/in_app_shell.dart';
import '../widgets/neon_card.dart';
import '../widgets/pills.dart';
import '../widgets/placeholder_block.dart';
import '../widgets/progress_bar.dart';
import '../widgets/rank_badge.dart';
import '../widgets/tab_bar.dart';

class _MuscleRow {
  const _MuscleRow({
    required this.key,
    required this.name,
    required this.rank,
    required this.sub,
    required this.pct,
  });
  final String key;
  final String name;
  final Rank rank;
  final String sub;
  final double pct;
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _muscles = <_MuscleRow>[
    _MuscleRow(key: 'chest', name: 'CHEST', rank: Rank.gold, sub: 'II', pct: 0.6),
    _MuscleRow(key: 'back', name: 'BACK', rank: Rank.silver, sub: 'III', pct: 0.8),
    _MuscleRow(key: 'shoulders', name: 'SHOULDERS', rank: Rank.gold, sub: 'I', pct: 0.3),
    _MuscleRow(key: 'biceps', name: 'BICEPS', rank: Rank.silver, sub: 'II', pct: 0.55),
    _MuscleRow(key: 'triceps', name: 'TRICEPS', rank: Rank.silver, sub: 'II', pct: 0.4),
    _MuscleRow(key: 'core', name: 'CORE', rank: Rank.bronze, sub: 'III', pct: 0.9),
    _MuscleRow(key: 'quads', name: 'QUADS', rank: Rank.platinum, sub: 'I', pct: 0.2),
    _MuscleRow(key: 'hamstrings', name: 'HAMSTRINGS', rank: Rank.gold, sub: 'III', pct: 0.7),
    _MuscleRow(key: 'glutes', name: 'GLUTES', rank: Rank.gold, sub: 'II', pct: 0.5),
    _MuscleRow(key: 'calves', name: 'CALVES', rank: Rank.bronze, sub: 'I', pct: 0.1),
  ];

  @override
  Widget build(BuildContext context) {
    final s = context.watch<PlayerState>();
    return InAppShell(
      active: AppTab.profile,
      title: 'PROFILE',
      child: ListView(
        padding: const EdgeInsets.all(AppSpace.s5),
        children: [
          // Player Class card
          NeonCard(
            glow: GlowColor.xp,
            padding: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment(0, -0.4),
                          radius: 1.4,
                          colors: [
                            Color(0x33F5A623),
                            AppPalette.carbon,
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Positioned.fill(
                    child: PlaceholderBlock(
                      label: 'IRON WARRIOR ART',
                      height: 999,
                      color: AppPalette.xpGold,
                      border: false,
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppPalette.carbon.withValues(alpha: 0.95),
                          ],
                          stops: const [0.4, 1.0],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Row(
                      children: [
                        LevelPill(level: s.level),
                        const SizedBox(width: AppSpace.s3),
                        XPPill(xp: s.xpCurrent, max: s.xpMax),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppPalette.carbon,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(color: AppPalette.xpGold),
                            boxShadow: [
                              BoxShadow(
                                color: AppPalette.xpGold.withValues(alpha: 0.53),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.shield_moon_outlined,
                            color: AppPalette.xpGold,
                            size: 36,
                          ),
                        ),
                        const SizedBox(width: AppSpace.s4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PLAYER CLASS',
                                style:
                                    AppType.label(color: AppPalette.xpGold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'IRON WARRIOR',
                                style: AppType.displayLG(
                                  color: AppPalette.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Heavy compound specialist · +15% strength XP',
                                style: AppType.bodySM(
                                  color: AppPalette.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpace.s4),

          // Stats row
          Row(
            children: const [
              Expanded(
                child: _StatTile(
                  label: 'TOTAL XP',
                  value: '12,430',
                  color: AppPalette.xpGold,
                ),
              ),
              SizedBox(width: AppSpace.s3),
              Expanded(
                child: _StatTile(
                  label: 'WORKOUTS',
                  value: '87',
                  color: AppPalette.purple,
                ),
              ),
              SizedBox(width: AppSpace.s3),
              Expanded(
                child: _StatTile(
                  label: 'BEST STREAK',
                  value: '42',
                  color: AppPalette.flame,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s4),

          Text(
            'MUSCLE RANKS',
            style: AppType.label(color: AppPalette.textMuted),
          ),
          const SizedBox(height: AppSpace.s3),
          NeonCard(
            glow: GlowColor.none,
            padding: EdgeInsets.zero,
            pulse: false,
            child: Column(
              children: List.generate(_muscles.length, (i) {
                final m = _muscles[i];
                final last = i == _muscles.length - 1;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: last
                            ? Colors.transparent
                            : AppPalette.strokeHairline,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      RankBadge(rank: m.rank, subRank: m.sub, size: 36),
                      const SizedBox(width: AppSpace.s4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  m.name,
                                  style: AppType.label(
                                    color: AppPalette.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${m.rank.name.toUpperCase()} ${m.sub}',
                                  style: AppType.monoMD(
                                    color: AppPalette.textMuted,
                                  ).copyWith(fontSize: 11),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Bar(
                              percent: m.pct * 100,
                              color: rankBarColor(m.rank),
                              height: 4,
                              glowOn: false,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
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
      padding: const EdgeInsets.all(AppSpace.s4),
      decoration: BoxDecoration(
        color: AppPalette.carbon,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppPalette.strokeHairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppType.label(color: AppPalette.textMuted).copyWith(
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppType.monoLG(color: color).copyWith(fontSize: 20),
          ),
        ],
      ),
    );
  }
}
