import '../data/models/quest.dart';
import '../data/models/workout.dart';
import '../data/services/analytics_service.dart';
import '../data/services/exercise_service.dart';
import '../data/services/sets_service.dart';
import '../data/services/workout_service.dart';
import 'quest_engine.dart';
import 'rank_engine.dart';
import 'streak_engine.dart';
import 'xp_engine.dart';

/// Fan-out point invoked from the workout logger's Finish flow. Runs every
/// engine in the right order and returns a compact [SessionSummary] that the
/// UI can use to decide celebrations (level-up, streak milestone) and to
/// show post-session stats.
///
/// Call site: `workout_screen._finishAndGo` after `WorkoutService.finish`.
class GameHandlers {
  GameHandlers._();

  /// Runs after a workout is committed. Idempotent — calling it again on the
  /// same `workoutId` is safe but will double-increment streaks / quest
  /// progress, so callers should only invoke on the first completion.
  static Future<SessionSummary> onWorkoutFinished(int workoutId) async {
    final before = await _snapshot();
    final workout = await WorkoutService.byId(workoutId);
    if (workout == null) {
      return SessionSummary.empty();
    }
    final sets = await SetsService.forWorkout(workoutId);

    // Max baseXp across the workout — used by QuestEngine to tell if the
    // session included a compound lift (baseXp >= 5 per PRD §12). Also
    // surface PR count + heaviest single set so weekly/boss kinds can
    // make their progress decisions.
    var maxBaseXp = 0;
    var prCount = 0;
    var maxSetWeight = 0.0;
    for (final s in sets) {
      final ex = await ExerciseService.byId(s.exerciseId);
      if (ex != null && ex.baseXp > maxBaseXp) maxBaseXp = ex.baseXp;
      if (s.isPr) prCount += 1;
      final w = s.weightKg ?? 0;
      if (w > maxSetWeight) maxSetWeight = w;
    }

    // Engines fire in dependency order: rank uses the just-committed sets;
    // streak is independent; quests read workout totals.
    await RankEngine.recomputeAll();
    final streak = await StreakEngine.onWorkoutFinished();
    final completedQuests = await QuestEngine.onWorkoutFinished(
      workout: workout,
      setsInWorkout: sets.length,
      maxBaseXpInWorkout: maxBaseXp,
      prsThisWorkout: prCount,
      maxSetWeightKg: maxSetWeight,
    );

    // Fold quest XP into the current workout row so `WorkoutService.totalXp`
    // (and therefore PlayerState level + XP bar) picks it up. Crucially,
    // this happens BEFORE the `after` snapshot so a quest-triggered
    // level-up fires the celebration via `summary.leveledUp`.
    final questXp = completedQuests.fold<int>(
      0,
      (sum, q) => sum + q.xpReward,
    );
    if (questXp > 0) {
      await WorkoutService.addXp(workoutId, questXp);
    }

    final after = await _snapshot();

    // Telemetry matches PRD §15 event schema.
    await AnalyticsService.log('workout_finished', {
      'duration_min': workout.duration.inMinutes,
      'xp_total': workout.xpEarned,
      'volume_kg': workout.volumeKg.round(),
      'sets': sets.length,
    });
    for (final q in completedQuests) {
      await AnalyticsService.log('quest_completed', {
        'quest_id': q.id,
        'type': q.type,
        'xp': q.xpReward,
      });
    }

    return SessionSummary(
      workout: workout,
      setCount: sets.length,
      levelBefore: before.level,
      levelAfter: after.level,
      streakBefore: before.streak,
      streakAfter: streak.current,
      streakMilestoneReached: streak.milestoneReached,
      completedQuests: completedQuests,
      questXpAwarded: questXp,
    );
  }

  /// Convenience wrapper for the workout logger — computes per-set XP via
  /// XpEngine using the current catalog baseXp + optional RPE + PR flag.
  static Future<int> xpForSet({
    required int exerciseId,
    int? rpe,
    required bool isPr,
  }) async {
    final ex = await ExerciseService.byId(exerciseId);
    final baseXp = ex?.baseXp ?? 3;
    return XpEngine.xpForSet(baseXp: baseXp, rpe: rpe, isPr: isPr);
  }

  static Future<_Snapshot> _snapshot() async {
    final totalXp = await WorkoutService.totalXp();
    final lvl = XpEngine.resolve(totalXp).level;
    return _Snapshot(level: lvl, streak: 0); // streak handled separately
  }
}

class _Snapshot {
  const _Snapshot({required this.level, required this.streak});
  final int level;
  final int streak;
}

class SessionSummary {
  const SessionSummary({
    required this.workout,
    required this.setCount,
    required this.levelBefore,
    required this.levelAfter,
    required this.streakBefore,
    required this.streakAfter,
    required this.streakMilestoneReached,
    required this.completedQuests,
    this.questXpAwarded = 0,
  });

  final Workout? workout;
  final int setCount;
  final int levelBefore;
  final int levelAfter;
  final int streakBefore;
  final int streakAfter;
  final bool streakMilestoneReached;
  final List<Quest> completedQuests;

  /// Total XP folded into the workout row from quests completed during this
  /// session. Surfaced on the post-session UI as a separate toast.
  final int questXpAwarded;

  bool get leveledUp => levelAfter > levelBefore;

  factory SessionSummary.empty() => const SessionSummary(
        workout: null,
        setCount: 0,
        levelBefore: 1,
        levelAfter: 1,
        streakBefore: 0,
        streakAfter: 0,
        streakMilestoneReached: false,
        completedQuests: [],
      );
}
