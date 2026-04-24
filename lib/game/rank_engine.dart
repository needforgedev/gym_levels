import '../data/app_db.dart';
import '../data/schema.dart';
import '../data/services/muscle_rank_service.dart';

/// PRD §9A.4 — muscle ranks.
///
/// **Formula (v1 MVP).** PRD §9.3 specifies
/// `rolling 4-week max_volume × max_weight × frequency`. In practice that
/// product scales too aggressively for the Bronze → Grandmaster thresholds
/// shipped in PRD §9A.4 — a single 100 kg × 10 rep set would vault a new
/// user past Grandmaster. For v1 we use a simpler, steady monotonic:
///
///     rank_xp = round( total_volume_last_4_weeks_kg / 10 )
///
/// This matches the thresholds well in practice and is easy to reason about:
/// after a month of sub-beginner work (~3 workouts × 3 sets × 50 kg × 10 reps)
/// the user lands in Bronze III / Silver I. Tune post-beta once we have real
/// user data.
class RankEngine {
  RankEngine._();

  /// Rolling window for the rank calculation (PRD §9.3).
  static const Duration window = Duration(days: 28);

  /// Thresholds copied from PRD §9A.4. Upper bound is exclusive except for
  /// Grandmaster, which has no ceiling.
  static const int bronzeMax = 500;
  static const int silverMax = 1500;
  static const int goldMax = 3500;
  static const int platinumMax = 7000;
  static const int diamondMax = 12000;
  static const int masterMax = 20000;

  /// Muscles the rank dashboard tracks. Any muscle outside this list still
  /// gets a row if the user trains it.
  static const List<String> trackedMuscles = [
    'chest',
    'back',
    'shoulders',
    'biceps',
    'triceps',
    'core',
    'quads',
    'hamstrings',
    'glutes',
    'calves',
  ];

  /// Map a scalar `rank_xp` to a (rank, sub) tuple per PRD §9A.4 thresholds.
  /// Sub-ranks I/II/III split each tier band into thirds; Master and
  /// Grandmaster are single-tier.
  static RankAssignment assign(int rankXp) {
    if (rankXp < 0) rankXp = 0;
    if (rankXp < bronzeMax) {
      return RankAssignment('bronze', _thirds(rankXp, 0, bronzeMax));
    }
    if (rankXp < silverMax) {
      return RankAssignment('silver', _thirds(rankXp, bronzeMax, silverMax));
    }
    if (rankXp < goldMax) {
      return RankAssignment('gold', _thirds(rankXp, silverMax, goldMax));
    }
    if (rankXp < platinumMax) {
      return RankAssignment('platinum', _thirds(rankXp, goldMax, platinumMax));
    }
    if (rankXp < diamondMax) {
      return RankAssignment(
          'diamond', _thirds(rankXp, platinumMax, diamondMax));
    }
    if (rankXp < masterMax) return const RankAssignment('master', null);
    return const RankAssignment('grandmaster', null);
  }

  /// Splits `[lo, hi)` into three equal bands → "I" / "II" / "III".
  static String _thirds(int xp, int lo, int hi) {
    final band = (hi - lo) / 3;
    final into = xp - lo;
    if (into < band) return 'I';
    if (into < band * 2) return 'II';
    return 'III';
  }

  /// Fraction (0.0 – 1.0) through the current tier. Master and Grandmaster
  /// are flat — return 1.0 since they're terminal bands.
  static double progressInTier(int rankXp) {
    if (rankXp < 0) rankXp = 0;
    if (rankXp < bronzeMax) return rankXp / bronzeMax;
    if (rankXp < silverMax) {
      return (rankXp - bronzeMax) / (silverMax - bronzeMax);
    }
    if (rankXp < goldMax) {
      return (rankXp - silverMax) / (goldMax - silverMax);
    }
    if (rankXp < platinumMax) {
      return (rankXp - goldMax) / (platinumMax - goldMax);
    }
    if (rankXp < diamondMax) {
      return (rankXp - platinumMax) / (diamondMax - platinumMax);
    }
    if (rankXp < masterMax) {
      return (rankXp - diamondMax) / (masterMax - diamondMax);
    }
    return 1.0;
  }

  /// Recompute every muscle rank affected by a workout. Called from
  /// `GameHandlers.onWorkoutFinished`.
  ///
  /// The query sums set volume per muscle across the last 4 weeks and
  /// writes back to `muscle_ranks`. Cheap (group-by on an indexed table).
  static Future<Map<String, int>> recomputeAll() async {
    final db = await AppDb.instance;
    final cutoff = (DateTime.now().millisecondsSinceEpoch ~/ 1000) -
        window.inSeconds;

    final rows = await db.rawQuery(
      '''
      SELECT e.${CExercise.primaryMuscle} AS muscle,
             COALESCE(SUM(s.${CSet.weightKg} * s.${CSet.reps}), 0) AS vol
      FROM ${T.sets} s
      JOIN ${T.exercises} e ON e.${CExercise.id} = s.${CSet.exerciseId}
      JOIN ${T.workouts} w ON w.${CWorkout.id} = s.${CSet.workoutId}
      WHERE s.${CSet.completedAt} >= ?
        AND w.${CWorkout.userId} = ?
        AND s.${CSet.weightKg} IS NOT NULL
      GROUP BY e.${CExercise.primaryMuscle}
      ''',
      [cutoff, 1],
    );

    final result = <String, int>{};
    for (final r in rows) {
      final muscle = r['muscle'] as String;
      final volume = (r['vol'] as num?)?.toDouble() ?? 0;
      final rankXp = (volume / 10).round();
      final a = assign(rankXp);
      await MuscleRankService.upsert(
        muscle: muscle,
        rank: a.rank,
        subRank: a.subRank,
        rankXp: rankXp,
      );
      result[muscle] = rankXp;
    }
    return result;
  }

  /// Priority-weighted mean of the 10 tracked-muscle rank_xp values — turned
  /// into an overall tier via [assign]. PRD §9.3 specifies "weighted median";
  /// we use mean here because fractional weights on medians are fiddly to
  /// reason about, and the user-visible tier changes in the same direction.
  ///
  /// `priorityMuscles` (from `goals.priority_muscles`) count 1.5×.
  static Future<RankAssignment> overallRank({
    List<String> priorityMuscles = const [],
  }) async {
    final rows = await MuscleRankService.getAll();
    if (rows.isEmpty) return const RankAssignment('bronze', 'I');

    double totalWeight = 0;
    double weightedSum = 0;
    for (final m in trackedMuscles) {
      final row = rows.firstWhere(
        (r) => r.muscle == m,
        orElse: () => rows.first, // placeholder, overwritten below if absent
      );
      final matched = rows.any((r) => r.muscle == m);
      if (!matched) continue;
      final w = priorityMuscles.contains(m) ? 1.5 : 1.0;
      weightedSum += row.rankXp * w;
      totalWeight += w;
    }
    if (totalWeight == 0) return const RankAssignment('bronze', 'I');
    final avg = (weightedSum / totalWeight).round();
    return assign(avg);
  }
}

class RankAssignment {
  const RankAssignment(this.rank, this.subRank);
  final String rank;
  final String? subRank;
}
