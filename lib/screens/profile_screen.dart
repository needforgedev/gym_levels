import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/muscle_rank.dart';
import '../data/models/streak.dart';
import '../data/services/muscle_rank_service.dart';
import '../data/services/streak_service.dart';
import '../data/services/workout_service.dart';
import '../game/rank_engine.dart';
import '../state/player_state.dart';
import '../theme/tokens.dart';
import '../widgets/in_app_shell.dart';
import '../widgets/neon_card.dart';
import '../widgets/pills.dart';
import '../widgets/placeholder_block.dart';
import '../widgets/progress_bar.dart';
import '../widgets/rank_badge.dart';
import '../widgets/tab_bar.dart';

/// Row data for the Muscle Ranks list — derived from `muscle_ranks` at
/// build time. Muscles the user hasn't trained yet default to Bronze I / 0%.
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

class _ProfileBundle {
  const _ProfileBundle({
    required this.workoutCount,
    required this.streak,
    required this.muscles,
  });
  final int workoutCount;
  final Streak? streak;
  final List<_MuscleRow> muscles;
}

String _titleCase(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<_ProfileBundle> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ProfileBundle> _load() async {
    final results = await Future.wait([
      WorkoutService.totalFinished(),
      StreakService.get(),
      MuscleRankService.getAll(),
    ]);
    final workoutCount = results[0] as int;
    final streak = results[1] as Streak?;
    final ranks = results[2] as List<MuscleRank>;

    final byMuscle = {for (final r in ranks) r.muscle: r};
    final rows = <_MuscleRow>[
      for (final m in RankEngine.trackedMuscles)
        _buildRow(m, byMuscle[m]),
    ];
    return _ProfileBundle(
      workoutCount: workoutCount,
      streak: streak,
      muscles: rows,
    );
  }

  _MuscleRow _buildRow(String key, MuscleRank? mr) {
    if (mr == null) {
      return _MuscleRow(
        key: key,
        name: key.toUpperCase(),
        rank: Rank.bronze,
        sub: 'I',
        pct: 0,
      );
    }
    final assignment = RankEngine.assign(mr.rankXp);
    return _MuscleRow(
      key: key,
      name: key.toUpperCase(),
      rank: rankFromString(assignment.rank),
      sub: assignment.subRank ?? '',
      pct: RankEngine.progressInTier(mr.rankXp),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<PlayerState>();
    return InAppShell(
      active: AppTab.profile,
      title: 'PROFILE',
      child: FutureBuilder<_ProfileBundle>(
        future: _future,
        builder: (ctx, snap) {
          final bundle = snap.data;
          return ListView(
            padding: const EdgeInsets.all(AppSpace.s5),
            children: [
              _PlayerClassCard(
                level: s.level,
                xpCurrent: s.xpCurrent,
                xpMax: s.xpMax,
                playerName: s.playerName,
              ),
              const SizedBox(height: AppSpace.s4),

              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      label: 'TOTAL XP',
                      value: _formatInt(s.totalXp),
                      color: AppPalette.xpGold,
                    ),
                  ),
                  const SizedBox(width: AppSpace.s3),
                  Expanded(
                    child: _StatTile(
                      label: 'WORKOUTS',
                      value: '${bundle?.workoutCount ?? 0}',
                      color: AppPalette.purple,
                    ),
                  ),
                  const SizedBox(width: AppSpace.s3),
                  Expanded(
                    child: _StatTile(
                      label: 'BEST STREAK',
                      value: '${bundle?.streak?.longest ?? 0}',
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
              _MuscleRanksCard(rows: bundle?.muscles ?? const []),
            ],
          );
        },
      ),
    );
  }

  static String _formatInt(int n) {
    // Thousands separator without bringing in intl — the profile screen is
    // the only place we show large numbers.
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final fromEnd = s.length - i;
      buf.write(s[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }
}

class _PlayerClassCard extends StatelessWidget {
  const _PlayerClassCard({
    required this.level,
    required this.xpCurrent,
    required this.xpMax,
    required this.playerName,
  });

  final int level;
  final int xpCurrent;
  final int xpMax;
  final String playerName;

  @override
  Widget build(BuildContext context) {
    return NeonCard(
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
                  LevelPill(level: level),
                  const SizedBox(width: AppSpace.s3),
                  XPPill(xp: xpCurrent, max: xpMax),
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
                          'PLAYER',
                          style:
                              AppType.label(color: AppPalette.xpGold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _titleCase(playerName),
                          style: AppType.displayLG(
                            color: AppPalette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Level $level · $xpCurrent / $xpMax XP',
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
    );
  }
}

class _MuscleRanksCard extends StatelessWidget {
  const _MuscleRanksCard({required this.rows});
  final List<_MuscleRow> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      // Still loading — render a spaced empty card to avoid layout jump.
      return NeonCard(
        glow: GlowColor.none,
        padding: const EdgeInsets.all(AppSpace.s5),
        pulse: false,
        child: Text(
          'No muscle data yet — log your first workout.',
          style: AppType.bodySM(color: AppPalette.textMuted),
        ),
      );
    }
    return NeonCard(
      glow: GlowColor.none,
      padding: EdgeInsets.zero,
      pulse: false,
      child: Column(
        children: List.generate(rows.length, (i) {
          final m = rows[i];
          final last = i == rows.length - 1;
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
                RankBadge(
                  rank: m.rank,
                  subRank: m.sub.isEmpty ? 'I' : m.sub,
                  size: 36,
                ),
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
                            m.sub.isEmpty
                                ? m.rank.name.toUpperCase()
                                : '${m.rank.name.toUpperCase()} ${m.sub}',
                            style: AppType.monoMD(
                              color: AppPalette.textMuted,
                            ).copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Bar(
                        percent: (m.pct * 100).clamp(0, 100).toDouble(),
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
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppType.monoLG(color: color).copyWith(fontSize: 20),
              maxLines: 1,
              softWrap: false,
            ),
          ),
        ],
      ),
    );
  }
}
