import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/app_db.dart';
import '../data/models/exercise.dart';
import '../data/models/workout_set.dart';
import '../data/schema.dart';
import '../data/services/muscle_rank_service.dart';
import '../game/rank_engine.dart';
import '../theme/tokens.dart';
import '../widgets/screen_base.dart';

/// Per-muscle drill-down — opened from `RanksScreen` row taps. Surfaces
/// the muscle's current tier + sub-rank, XP-to-next-tier delta,
/// 4-week volume by week, and recent PR sets.
class MuscleDetailScreen extends StatefulWidget {
  const MuscleDetailScreen({super.key, required this.muscle});

  final String muscle;

  @override
  State<MuscleDetailScreen> createState() => _MuscleDetailScreenState();
}

class _Bundle {
  const _Bundle({
    required this.rankXp,
    required this.weeklyVolume,
    required this.prs,
  });
  final int rankXp;
  final List<({DateTime weekStart, double volumeKg})> weeklyVolume;
  final List<({WorkoutSet set, Exercise exercise})> prs;
}

class _MuscleDetailScreenState extends State<MuscleDetailScreen> {
  late Future<_Bundle> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_Bundle> _load() async {
    final db = await AppDb.instance;

    // Current rank XP for this muscle.
    final rankRow = await MuscleRankService.forMuscle(widget.muscle);
    final rankXp = rankRow?.rankXp ?? 0;

    // 4-week volume buckets (this week + previous 3). Bucket boundary
    // is local-Monday-00:00 to match the rest of the app.
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final mondayOffset = (today.weekday - 1) % 7;
    final thisMonday = today.subtract(Duration(days: mondayOffset));
    final weekStarts = <DateTime>[
      for (var i = 3; i >= 0; i--)
        thisMonday.subtract(Duration(days: 7 * i)),
    ];
    final fourWeeksAgoEpoch =
        weekStarts.first.millisecondsSinceEpoch ~/ 1000;

    final volumeRows = await db.rawQuery(
      '''
      SELECT s.${CSet.completedAt}                AS completed_at,
             s.${CSet.weightKg} * s.${CSet.reps}  AS vol
      FROM ${T.sets} s
      JOIN ${T.exercises} e ON e.${CExercise.id} = s.${CSet.exerciseId}
      JOIN ${T.workouts}  w ON w.${CWorkout.id} = s.${CSet.workoutId}
      WHERE e.${CExercise.primaryMuscle} = ?
        AND s.${CSet.completedAt} >= ?
        AND s.${CSet.weightKg} IS NOT NULL
        AND w.${CWorkout.userId} = ?
      ''',
      [widget.muscle, fourWeeksAgoEpoch, 1],
    );
    final weekly = <DateTime, double>{
      for (final ws in weekStarts) ws: 0.0,
    };
    for (final r in volumeRows) {
      final ts = (r['completed_at'] as int) * 1000;
      final d = DateTime.fromMillisecondsSinceEpoch(ts);
      // Bucket by Monday of that ISO week.
      final dDay = DateTime(d.year, d.month, d.day);
      final off = (dDay.weekday - 1) % 7;
      final wm = dDay.subtract(Duration(days: off));
      final key = weekStarts.firstWhere(
        (w) => w == wm,
        orElse: () => weekStarts.first,
      );
      weekly[key] = (weekly[key] ?? 0) + ((r['vol'] as num?)?.toDouble() ?? 0);
    }
    final volumeBuckets = [
      for (final ws in weekStarts)
        (weekStart: ws, volumeKg: weekly[ws] ?? 0.0),
    ];

    // Recent PRs that targeted this muscle (last 12 weeks, max 5).
    final prCutoff = (DateTime.now().millisecondsSinceEpoch ~/ 1000) -
        Duration(days: 84).inSeconds;
    final prRows = await db.rawQuery(
      '''
      SELECT s.*,
             e.${CExercise.id}            AS ex_id,
             e.${CExercise.name}          AS ex_name,
             e.${CExercise.primaryMuscle} AS ex_primary,
             e.${CExercise.secondaryMuscles} AS ex_secondary,
             e.${CExercise.equipment}     AS ex_equipment,
             e.${CExercise.baseXp}        AS ex_baseXp
      FROM ${T.sets} s
      JOIN ${T.exercises} e ON e.${CExercise.id} = s.${CSet.exerciseId}
      JOIN ${T.workouts}  w ON w.${CWorkout.id} = s.${CSet.workoutId}
      WHERE e.${CExercise.primaryMuscle} = ?
        AND s.${CSet.isPr} = 1
        AND s.${CSet.completedAt} >= ?
        AND w.${CWorkout.userId} = ?
      ORDER BY s.${CSet.completedAt} DESC
      LIMIT 5
      ''',
      [widget.muscle, prCutoff, 1],
    );
    final prs = <({WorkoutSet set, Exercise exercise})>[];
    for (final r in prRows) {
      final set = WorkoutSet.fromRow(r);
      final ex = Exercise.fromRow({
        CExercise.id: r['ex_id'],
        CExercise.name: r['ex_name'],
        CExercise.primaryMuscle: r['ex_primary'],
        CExercise.secondaryMuscles: r['ex_secondary'],
        CExercise.equipment: r['ex_equipment'],
        CExercise.baseXp: r['ex_baseXp'],
      });
      prs.add((set: set, exercise: ex));
    }

    return _Bundle(
      rankXp: rankXp,
      weeklyVolume: volumeBuckets,
      prs: prs,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScreenBase(
      background: AppPalette.voidBg,
      child: SafeArea(
        bottom: false,
        child: FutureBuilder<_Bundle>(
          future: _future,
          builder: (ctx, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppPalette.purpleSoft,
                ),
              );
            }
            final bundle = snap.data;
            if (bundle == null) return const SizedBox.shrink();
            return Column(
              children: [
                _Header(
                  muscle: widget.muscle,
                  onBack: () => context.go('/ranks'),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    children: [
                      _RankHeroCard(
                        muscle: widget.muscle,
                        rankXp: bundle.rankXp,
                      ),
                      const SizedBox(height: 14),
                      _SectionLabel(text: 'VOLUME · LAST 4 WEEKS'),
                      const SizedBox(height: 8),
                      _VolumeChartCard(buckets: bundle.weeklyVolume),
                      const SizedBox(height: 14),
                      _SectionLabel(text: 'RECENT PRS'),
                      const SizedBox(height: 8),
                      if (bundle.prs.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppPalette.bgCard.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppPalette.purple.withValues(alpha: 0.15),
                              width: 1,
                            ),
                          ),
                          child: const Text(
                            'No PRs yet for this muscle. Keep training.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppPalette.textMuted,
                            ),
                          ),
                        )
                      else
                        for (final pr in bundle.prs) ...[
                          _PrRow(set: pr.set, exercise: pr.exercise),
                          const SizedBox(height: 8),
                        ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─── Header ────────────────────────────────────────────────
class _Header extends StatelessWidget {
  const _Header({required this.muscle, required this.onBack});
  final String muscle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppPalette.purple.withValues(alpha: 0.12),
                  border: Border.all(
                    color: AppPalette.purple.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.chevron_left,
                  size: 20,
                  color: AppPalette.textPrimary,
                ),
              ),
            ),
          ),
          const Spacer(),
          Text(
            _titleCase(muscle),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppPalette.textPrimary,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 38), // balance back-button width
        ],
      ),
    );
  }

  static String _titleCase(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
        color: AppPalette.textMuted,
      ),
    );
  }
}

// ─── Rank hero card ────────────────────────────────────────
class _RankHeroCard extends StatelessWidget {
  const _RankHeroCard({required this.muscle, required this.rankXp});
  final String muscle;
  final int rankXp;

  @override
  Widget build(BuildContext context) {
    final assignment = RankEngine.assign(rankXp);
    final color = _colorFor(assignment.rank);
    final tierLabel = assignment.subRank == null
        ? assignment.rank.toUpperCase()
        : '${assignment.rank.toUpperCase()} ${assignment.subRank}';
    final pct = RankEngine.progressInTier(rankXp);
    final nextThreshold = _nextTierMin(rankXp);
    final xpToNext = nextThreshold == null ? null : (nextThreshold - rankXp);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.20),
            AppPalette.purple.withValues(alpha: 0.12),
          ],
        ),
        border: Border.all(
          color: color.withValues(alpha: 0.50),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.30),
            blurRadius: 24,
            spreadRadius: -6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withValues(alpha: 0.30),
                      color.withValues(alpha: 0.10),
                    ],
                  ),
                  border: Border.all(
                    color: color.withValues(alpha: 0.65),
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  muscle[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 26,
                    fontFamily: 'BebasNeue',
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CURRENT RANK',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: AppPalette.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tierLabel,
                      style: TextStyle(
                        fontSize: 28,
                        fontFamily: 'BebasNeue',
                        height: 1,
                        letterSpacing: 1,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'RANK XP',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: AppPalette.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _format(rankXp),
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'BebasNeue',
                      letterSpacing: 0.5,
                      color: AppPalette.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              child: Stack(
                children: [
                  Container(
                    color: AppPalette.purple.withValues(alpha: 0.15),
                  ),
                  FractionallySizedBox(
                    widthFactor: pct.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.55),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(pct * 100).round()}% THROUGH ${assignment.rank.toUpperCase()}',
                style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'JetBrainsMono',
                  fontWeight: FontWeight.w700,
                  color: AppPalette.textMuted,
                ),
              ),
              Text(
                xpToNext == null
                    ? 'GRANDMASTER'
                    : '${_format(xpToNext)} XP TO NEXT',
                style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'JetBrainsMono',
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static int? _nextTierMin(int rankXp) {
    if (rankXp < RankEngine.bronzeMax) return RankEngine.bronzeMax;
    if (rankXp < RankEngine.silverMax) return RankEngine.silverMax;
    if (rankXp < RankEngine.goldMax) return RankEngine.goldMax;
    if (rankXp < RankEngine.platinumMax) return RankEngine.platinumMax;
    if (rankXp < RankEngine.diamondMax) return RankEngine.diamondMax;
    if (rankXp < RankEngine.masterMax) return RankEngine.masterMax;
    return null; // grandmaster terminal
  }

  static String _format(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final fromEnd = s.length - i;
      buf.write(s[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }

  static Color _colorFor(String tier) {
    switch (tier) {
      case 'bronze':
        return const Color(0xFFCD7F32);
      case 'silver':
        return const Color(0xFFC9D3E0);
      case 'gold':
        return AppPalette.amber;
      case 'platinum':
        return const Color(0xFF6FC9FF);
      case 'diamond':
        return AppPalette.teal;
      case 'master':
        return AppPalette.purpleSoft;
      case 'grandmaster':
        return AppPalette.flame;
      default:
        return AppPalette.purpleSoft;
    }
  }
}

// ─── Volume chart (4 weekly bars) ──────────────────────────
class _VolumeChartCard extends StatelessWidget {
  const _VolumeChartCard({required this.buckets});
  final List<({DateTime weekStart, double volumeKg})> buckets;

  @override
  Widget build(BuildContext context) {
    final maxVol = buckets.fold<double>(
      0,
      (m, b) => b.volumeKg > m ? b.volumeKg : m,
    );
    final hasAny = maxVol > 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xE61A0F2B), Color(0xE6120A1F)],
        ),
        border: Border.all(
          color: AppPalette.borderViolet,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 130,
            child: !hasAny
                ? Center(
                    child: Text(
                      'No volume in the last 4 weeks.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppPalette.textMuted,
                      ),
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < buckets.length; i++) ...[
                        Expanded(
                          child: _VolumeBar(
                            volumeKg: buckets[i].volumeKg,
                            maxVolume: maxVol,
                            isCurrent: i == buckets.length - 1,
                          ),
                        ),
                        if (i < buckets.length - 1)
                          const SizedBox(width: 10),
                      ],
                    ],
                  ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < buckets.length; i++) ...[
                Expanded(
                  child: Text(
                    _shortLabel(buckets[i].weekStart),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: i == buckets.length - 1
                          ? AppPalette.purpleSoft
                          : AppPalette.textDim,
                    ),
                  ),
                ),
                if (i < buckets.length - 1) const SizedBox(width: 10),
              ],
            ],
          ),
        ],
      ),
    );
  }

  static String _shortLabel(DateTime weekStart) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[(weekStart.month - 1).clamp(0, 11)]} ${weekStart.day}';
  }
}

class _VolumeBar extends StatelessWidget {
  const _VolumeBar({
    required this.volumeKg,
    required this.maxVolume,
    required this.isCurrent,
  });
  final double volumeKg;
  final double maxVolume;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final ratio = maxVolume == 0 ? 0.0 : volumeKg / maxVolume;
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final barHeight = (constraints.maxHeight * ratio).clamp(2.0, constraints.maxHeight);
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              volumeKg == 0
                  ? '—'
                  : '${(volumeKg / 1).round()}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                fontFamily: 'JetBrainsMono',
                color: isCurrent ? AppPalette.purpleSoft : AppPalette.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Container(
                height: barHeight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isCurrent
                        ? const [AppPalette.purple, AppPalette.purpleSoft]
                        : [
                            AppPalette.purple.withValues(alpha: 0.40),
                            AppPalette.purple.withValues(alpha: 0.20),
                          ],
                  ),
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: AppPalette.purple.withValues(alpha: 0.45),
                            blurRadius: 10,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── PR row ────────────────────────────────────────────────
class _PrRow extends StatelessWidget {
  const _PrRow({required this.set, required this.exercise});
  final WorkoutSet set;
  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final w = set.weightKg ?? 0;
    final wText = w % 1 == 0 ? w.round().toString() : w.toStringAsFixed(1);
    final date =
        DateTime.fromMillisecondsSinceEpoch(set.completedAt * 1000);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppPalette.amber.withValues(alpha: 0.08),
        border: Border.all(
          color: AppPalette.amber.withValues(alpha: 0.40),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: AppPalette.amber.withValues(alpha: 0.20),
              border: Border.all(
                color: AppPalette.amber.withValues(alpha: 0.50),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.emoji_events,
              size: 18,
              color: AppPalette.amber,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _shortDate(date),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppPalette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$wText kg × ${set.reps}',
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'JetBrainsMono',
              fontWeight: FontWeight.w700,
              color: AppPalette.amber,
            ),
          ),
        ],
      ),
    );
  }

  static String _shortDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[(d.month - 1).clamp(0, 11)]} ${d.day}, ${d.year}';
  }
}
