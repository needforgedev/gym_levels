import '../data/models/quest.dart';
import '../data/models/workout.dart';
import '../data/services/quest_service.dart';

/// PRD §9.4 — quest rotation + progress tracking.
///
/// Scope (v1 MVP):
/// - Daily pool: 3 rotating quests per local day.
/// - On Home mount we rotate if no daily quest was issued today.
/// - On workout finish, progress updates for every active daily quest; any
///   whose `progress ≥ target` is stamped `completedAt`.
/// - Weekly + Boss quests: structural hooks only (the PRD has those behind
///   §3.1 / §3.2). Daily is enough to prove the loop.
class QuestEngine {
  QuestEngine._();

  /// Template for a generated daily quest. `kindKey` is stored in the
  /// `description` column so the progress tracker knows which workout-derived
  /// number to increment.
  static const List<DailyQuestTemplate> dailyPool = [
    DailyQuestTemplate(
      kindKey: 'complete_workout',
      title: 'COMPLETE A WORKOUT',
      target: 1,
      xp: 40,
    ),
    DailyQuestTemplate(
      kindKey: 'sets_logged',
      title: 'LOG 5+ SETS TODAY',
      target: 5,
      xp: 30,
    ),
    DailyQuestTemplate(
      kindKey: 'volume_goal',
      title: 'HIT 500 KG OF VOLUME',
      target: 500,
      xp: 50,
    ),
    DailyQuestTemplate(
      kindKey: 'compound_lift',
      title: 'LOG A COMPOUND LIFT',
      target: 1,
      xp: 35,
    ),
  ];

  /// Epoch seconds for today's local midnight. Used to decide whether the
  /// current daily batch was issued "today" — both by the rotation logic
  /// here and by the UI layer (Home + Quests screen) so completed dailies
  /// keep rendering with a DONE state until the next local day rolls over.
  static int todayEpoch() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day)
            .millisecondsSinceEpoch ~/
        1000;
  }

  /// If no daily quest has been issued since today's midnight, insert three
  /// fresh quests from the pool. Safe to call every Home mount.
  ///
  /// Critically, we check the *full* quest history for today — not just
  /// the active (non-completed) quests. If a user has already finished all
  /// three of today's dailies, `QuestService.active` would return empty
  /// and this method would wrongly insert a fresh batch, resetting the
  /// completed state the user just earned.
  static Future<void> rotateDailyIfNeeded() async {
    final today = todayEpoch();
    final issuedToday = await QuestService.issuedSince('daily', today);
    if (issuedToday.isNotEmpty) return;

    // Nothing from today yet — retire any still-active dailies from
    // previous days by stamping them complete, then issue a fresh batch.
    // Keeps the active() query clean without needing a separate
    // expires_at sweep (PRD §14 will handle weekly/boss that way later).
    final stillActive = await QuestService.active('daily');
    for (final q in stillActive) {
      if (q.id != null) await QuestService.complete(q.id!);
    }

    // Day-seeded rotation across the daily pool — stable within a calendar
    // day, varied across days. Rotates by `dayOrdinal % pool.length` so
    // every template surfaces equally often without RNG state to persist.
    final dayOrdinal = today ~/ Duration.secondsPerDay;
    final rotated = <DailyQuestTemplate>[
      ...dailyPool.skip(dayOrdinal % dailyPool.length),
      ...dailyPool.take(dayOrdinal % dailyPool.length),
    ];
    final picks = rotated.take(3).toList();
    for (final tpl in picks) {
      await QuestService.insert(Quest(
        type: 'daily',
        title: tpl.title,
        description: tpl.kindKey,
        target: tpl.target,
        xpReward: tpl.xp,
        issuedAt: today,
        expiresAt: today + Duration.secondsPerDay,
      ));
    }
  }

  /// Bumps progress on every active daily quest using the stats we already
  /// have in-hand from the finished workout. Called by `GameHandlers`.
  ///
  /// Returns the list of quests whose progress just crossed `target` on this
  /// update — callers can surface celebrations / analytics for them.
  static Future<List<Quest>> onWorkoutFinished({
    required Workout workout,
    required int setsInWorkout,
    required int maxBaseXpInWorkout,
  }) async {
    final active = await QuestService.active('daily');
    final newlyCompleted = <Quest>[];

    for (final q in active) {
      if (q.id == null || q.isCompleted) continue;
      final inc = _incrementFor(
        kindKey: q.description ?? '',
        workout: workout,
        setsInWorkout: setsInWorkout,
        maxBaseXpInWorkout: maxBaseXpInWorkout,
      );
      if (inc == 0) continue;
      final next = q.progress + inc;
      await QuestService.updateProgress(q.id!, next);
      if (next >= q.target) {
        await QuestService.complete(q.id!);
        newlyCompleted.add(q);
      }
    }
    return newlyCompleted;
  }

  static int _incrementFor({
    required String kindKey,
    required Workout workout,
    required int setsInWorkout,
    required int maxBaseXpInWorkout,
  }) {
    switch (kindKey) {
      case 'complete_workout':
        return 1;
      case 'sets_logged':
        return setsInWorkout;
      case 'volume_goal':
        return workout.volumeKg.round();
      case 'compound_lift':
        // Compound lifts in the catalog carry baseXp >= 5 (PRD §12).
        return maxBaseXpInWorkout >= 5 ? 1 : 0;
      default:
        return 0;
    }
  }
}

class DailyQuestTemplate {
  const DailyQuestTemplate({

    required this.kindKey,
    required this.title,
    required this.target,
    required this.xp,
  });
  final String kindKey;
  final String title;
  final int target;
  final int xp;
}
