import 'package:flutter/material.dart';

import '../data/models/quest.dart';
import '../data/models/workout.dart';
import '../data/services/quest_service.dart';

/// PRD §9.4 — quest rotation + progress tracking.
///
/// Daily / weekly / boss quests all flow through this engine: templates
/// are stored as `kindKey` in the quest row's `description` field;
/// `onWorkoutFinished` looks up an increment per kindKey and progresses
/// every active quest. The Quests screen reads from the `quests` table
/// directly — no static placeholders.
class QuestEngine {
  QuestEngine._();

  // ─── Daily ──────────────────────────────────────────────
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

  // ─── Weekly ─────────────────────────────────────────────
  static const List<WeeklyQuestTemplate> weeklyPool = [
    WeeklyQuestTemplate(
      kindKey: 'weekly_train_n_days',
      title: 'Train 4 days this week',
      desc: 'Stay on schedule',
      target: 4,
      xp: 300,
    ),
    WeeklyQuestTemplate(
      kindKey: 'weekly_pr',
      title: 'Beat a personal record',
      desc: 'More weight for reps on any lift',
      target: 1,
      xp: 200,
    ),
    WeeklyQuestTemplate(
      kindKey: 'weekly_volume',
      title: 'Total volume: 8,000 kg',
      desc: 'Sum of weight × reps across the week',
      target: 8000,
      xp: 350,
    ),
    WeeklyQuestTemplate(
      kindKey: 'weekly_rpe_logged',
      title: 'Log RPE on every set',
      desc: 'All 7 sessions tracked',
      target: 21,
      xp: 250,
    ),
  ];

  // ─── Boss ───────────────────────────────────────────────
  //
  // Boss quests are curated multi-week objectives (PRD §3.2). They don't
  // rotate on a schedule — they're seeded once and run until completed.
  // `cycleSeconds` is the duration of one boss "cycle" used to compute
  // the WEEK X / Y phase label shown on the card.
  static const List<BossQuestTemplate> bossPool = [
    BossQuestTemplate(
      kindKey: 'boss_deadlift_2bw',
      title: 'Deadlift Bodyweight × 2',
      desc: 'Pull 160kg for a single rep',
      target: 160,
      xp: 2500,
      totalWeeks: 6,
      buff: BossBuff(
        key: 'iron_heart',
        name: 'IRON HEART',
        desc: '+10% XP on compound lifts for 7 days',
        durationDays: 7,
      ),
    ),
    BossQuestTemplate(
      kindKey: 'boss_bench_e1rm',
      title: 'Add 10% to Bench e1RM',
      desc: 'Estimated one-rep max: 90 → 99kg',
      target: 99,
      xp: 2000,
      totalWeeks: 6,
      buff: BossBuff(
        key: 'press_titan',
        name: 'PRESS TITAN',
        desc: '+10% XP on bench + overhead press for 7 days',
        durationDays: 7,
      ),
    ),
  ];

  /// Looks up the buff that ships with a completed boss kind. Returns
  /// `null` when the kind isn't in `bossPool` (defensive — e.g. legacy
  /// rows from a removed template).
  static BossBuff? buffFor(String? kindKey) {
    if (kindKey == null) return null;
    for (final t in bossPool) {
      if (t.kindKey == kindKey) return t.buff;
    }
    return null;
  }

  // ─── Display metadata ───────────────────────────────────
  //
  // Per-kindKey rendering hints (icon, unit, etc.). Lives outside the DB
  // so we can iterate copy/icons without a schema migration.
  static const Map<String, QuestMeta> meta = {
    'complete_workout': QuestMeta(icon: Icons.gps_fixed),
    'sets_logged': QuestMeta(icon: Icons.bar_chart),
    'volume_goal': QuestMeta(icon: Icons.fitness_center, unit: 'kg'),
    'compound_lift': QuestMeta(icon: Icons.bolt),
    'weekly_train_n_days': QuestMeta(icon: Icons.calendar_month),
    'weekly_pr': QuestMeta(icon: Icons.emoji_events_outlined),
    'weekly_volume':
        QuestMeta(icon: Icons.fitness_center, unit: 'kg'),
    'weekly_rpe_logged': QuestMeta(icon: Icons.gps_fixed),
    'boss_deadlift_2bw': QuestMeta(
      icon: Icons.shield_outlined,
      unit: 'kg',
      isBoss: true,
    ),
    'boss_bench_e1rm': QuestMeta(
      icon: Icons.shield_outlined,
      unit: 'kg',
      isBoss: true,
    ),
  };

  static QuestMeta metaFor(String? kindKey) {
    return meta[kindKey] ?? const QuestMeta(icon: Icons.gps_fixed);
  }

  // ─── Time helpers ───────────────────────────────────────
  static int todayEpoch() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day)
            .millisecondsSinceEpoch ~/
        1000;
  }

  /// Epoch seconds for the local Monday-00:00 of the current week. Anything
  /// issued on or after this is "this week".
  static int weekStartEpoch() {
    final now = DateTime.now();
    final mondayOffset = (now.weekday - 1) % 7; // Mon=1..Sun=7 → 0..6
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: mondayOffset));
    return monday.millisecondsSinceEpoch ~/ 1000;
  }

  /// Returns the WEEK X / Y phase label for a boss quest based on its
  /// `issuedAt` timestamp.
  static String? bossPhase(Quest q) {
    final tpl = bossPool.firstWhere(
      (t) => t.kindKey == q.description,
      orElse: () => const BossQuestTemplate(
        kindKey: '',
        title: '',
        desc: '',
        target: 0,
        xp: 0,
        totalWeeks: 6,
      ),
    );
    if (tpl.totalWeeks == 0) return null;
    final issuedDate =
        DateTime.fromMillisecondsSinceEpoch(q.issuedAt * 1000);
    final weeksElapsed =
        DateTime.now().difference(issuedDate).inDays ~/ 7;
    final week = (weeksElapsed + 1).clamp(1, tpl.totalWeeks);
    return 'WEEK $week / ${tpl.totalWeeks}';
  }

  // ─── Daily rotation ─────────────────────────────────────
  static Future<void> rotateDailyIfNeeded() async {
    final today = todayEpoch();
    final issuedToday = await QuestService.issuedSince('daily', today);
    if (issuedToday.isNotEmpty) return;

    final stillActive = await QuestService.active('daily');
    for (final q in stillActive) {
      if (q.id != null) await QuestService.complete(q.id!);
    }

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

  // ─── Weekly rotation ────────────────────────────────────
  /// If no weekly quest has been issued since this Monday 00:00, retire
  /// last week's leftovers and seed fresh ones. Idempotent.
  static Future<void> rotateWeeklyIfNeeded() async {
    final start = weekStartEpoch();
    final issuedThisWeek = await QuestService.issuedSince('weekly', start);
    if (issuedThisWeek.isNotEmpty) return;

    final stillActive = await QuestService.active('weekly');
    for (final q in stillActive) {
      if (q.id != null) await QuestService.complete(q.id!);
    }

    for (final tpl in weeklyPool) {
      await QuestService.insert(Quest(
        type: 'weekly',
        title: tpl.title,
        description: tpl.kindKey,
        target: tpl.target,
        xpReward: tpl.xp,
        issuedAt: start,
        expiresAt: start + (Duration.secondsPerDay * 7),
      ));
    }
  }

  // ─── Boss seeding ───────────────────────────────────────
  /// Inserts the boss quest pool on first run. Boss quests are curated
  /// (PRD §3.2) — they don't rotate; they live until completed or
  /// cancelled. We only seed if there are *no* boss rows at all so a
  /// completed boss isn't re-seeded.
  static Future<void> seedBossesIfNeeded() async {
    final all = await QuestService.all();
    final hasAnyBoss = all.any((q) => q.type == 'boss');
    if (hasAnyBoss) return;

    final now = todayEpoch();
    for (final tpl in bossPool) {
      await QuestService.insert(Quest(
        type: 'boss',
        title: tpl.title,
        description: tpl.kindKey,
        target: tpl.target,
        xpReward: tpl.xp,
        issuedAt: now,
        expiresAt: now + (Duration.secondsPerDay * 7 * tpl.totalWeeks),
      ));
    }
  }

  // ─── Workout-finished progress fan-out ──────────────────
  /// Bumps progress on every active daily/weekly/boss quest. Returns the
  /// list of quests that just crossed `target`.
  static Future<List<Quest>> onWorkoutFinished({
    required Workout workout,
    required int setsInWorkout,
    required int maxBaseXpInWorkout,
    int prsThisWorkout = 0,
    double? maxSetWeightKg,
  }) async {
    final newlyCompleted = <Quest>[];
    for (final type in const ['daily', 'weekly', 'boss']) {
      final active = await QuestService.active(type);
      for (final q in active) {
        if (q.id == null || q.isCompleted) continue;
        final inc = _incrementFor(
          kindKey: q.description ?? '',
          workout: workout,
          setsInWorkout: setsInWorkout,
          maxBaseXpInWorkout: maxBaseXpInWorkout,
          prsThisWorkout: prsThisWorkout,
          maxSetWeightKg: maxSetWeightKg,
          currentProgress: q.progress,
        );
        if (inc == 0) continue;
        // Boss quests track absolute progress (e.g. heaviest single rep
        // pulled), not cumulative — we replace if it's a new max instead
        // of summing. _incrementFor returns the new absolute value when
        // `_isAbsoluteKind` is true.
        final next = _isAbsoluteKind(q.description ?? '')
            ? inc
            : q.progress + inc;
        await QuestService.updateProgress(q.id!, next);
        if (next >= q.target) {
          await QuestService.complete(q.id!);
          newlyCompleted.add(q);
        }
      }
    }
    return newlyCompleted;
  }

  static bool _isAbsoluteKind(String kindKey) {
    // Boss kinds track an absolute max rather than a running tally —
    // `inc` is the new candidate value, replacing only if higher.
    return kindKey == 'boss_deadlift_2bw' ||
        kindKey == 'boss_bench_e1rm';
  }

  static int _incrementFor({
    required String kindKey,
    required Workout workout,
    required int setsInWorkout,
    required int maxBaseXpInWorkout,
    required int prsThisWorkout,
    required double? maxSetWeightKg,
    required int currentProgress,
  }) {
    switch (kindKey) {
      // Daily.
      case 'complete_workout':
        return 1;
      case 'sets_logged':
        return setsInWorkout;
      case 'volume_goal':
        return workout.volumeKg.round();
      case 'compound_lift':
        return maxBaseXpInWorkout >= 5 ? 1 : 0;

      // Weekly.
      case 'weekly_train_n_days':
        return 1;
      case 'weekly_pr':
        return prsThisWorkout > 0 ? 1 : 0;
      case 'weekly_volume':
        return workout.volumeKg.round();
      case 'weekly_rpe_logged':
        // Until RPE capture lands (deferred Phase 2 polish), every logged
        // set counts as "RPE-logged" so the weekly quest still ticks.
        return setsInWorkout;

      // Boss — absolute (replace if new max).
      case 'boss_deadlift_2bw':
      case 'boss_bench_e1rm':
        final m = maxSetWeightKg?.round() ?? 0;
        return m > currentProgress ? m : 0;

      default:
        return 0;
    }
  }
}

// ─── Templates ──────────────────────────────────────────────
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

class WeeklyQuestTemplate {
  const WeeklyQuestTemplate({
    required this.kindKey,
    required this.title,
    required this.desc,
    required this.target,
    required this.xp,
  });
  final String kindKey;
  final String title;
  final String desc;
  final int target;
  final int xp;
}

class BossQuestTemplate {
  const BossQuestTemplate({
    required this.kindKey,
    required this.title,
    required this.desc,
    required this.target,
    required this.xp,
    required this.totalWeeks,
    this.buff,
  });
  final String kindKey;
  final String title;
  final String desc;
  final int target;
  final int xp;
  final int totalWeeks;

  /// Permanent buff awarded on completion (PRD §3.2). Display-only for now;
  /// the XP-modifier side effect will land alongside the active-buffs
  /// service. `null` for the empty-template fallbacks used by lookups.
  final BossBuff? buff;
}

class BossBuff {
  const BossBuff({
    required this.key,
    required this.name,
    required this.desc,
    required this.durationDays,
  });
  final String key;
  final String name;
  final String desc;
  final int durationDays;
}

class QuestMeta {
  const QuestMeta({
    required this.icon,
    this.unit,
    this.isBoss = false,
  });
  final IconData icon;
  final String? unit;
  final bool isBoss;
}
