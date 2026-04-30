import 'package:sqflite/sqflite.dart';

import '../app_db.dart';
import '../schema.dart';
import '../supabase/supabase_client.dart';
import 'cloud_payload.dart';
import 'pull_handler.dart';

/// Concrete [PullHandler] implementations — one per cloud-mirrored
/// table. Mirrors [cloud_push_handlers.dart] in reverse: cloud rows
/// flow back into local sqflite during initial-sync hydration.
///
/// All handlers honour two invariants:
///   1. `user_id` is always `1` locally (single-user-per-device in
///      v1.0). The cloud's UUID `user_id` is dropped.
///   2. Re-running a page is a no-op via lookup-by-cloud_id — idempotent
///      pulls let the orchestrator resume mid-table after a kill.

const int _defaultPageSize = 200;

abstract class _CloudPullHandler extends PullHandler {
  const _CloudPullHandler();

  @override
  String get tableName;

  /// Cloud table name (e.g. `cloud_workouts`).
  String get cloudTable;

  /// Convert one cloud row to its local-row shape. Implementations do
  /// NOT need to set `cloud_id` / `cloud_updated_at` / `cloud_deleted_at`
  /// — the base class injects those.
  Future<Map<String, Object?>> toLocalRow(Map<String, Object?> cloud);

  @override
  Future<int> pullPage({
    required int offset,
    required int pageSize,
  }) async {
    final client = SupabaseConfig.client;
    final response = await client
        .from(cloudTable)
        .select()
        // Only un-deleted rows. Soft-deleted ones hydrate as no-ops
        // since the local table doesn't keep a tombstone.
        .filter('deleted_at', 'is', null)
        .order('created_at', ascending: true)
        .range(offset, offset + pageSize - 1);

    if (response.isEmpty) return 0;

    final db = await AppDb.instance;
    for (final cloud in response) {
      await _writeOne(db, cloud);
    }
    return response.length;
  }

  @override
  Future<int> pullSince(DateTime? since) async {
    final client = SupabaseConfig.client;
    var query = client.from(cloudTable).select();
    if (since != null) {
      query = query.gt('updated_at', since.toIso8601String());
    }
    // updated_at-ascending so a row that was edited then deleted
    // applies in the right order (we always want the latest state).
    final response =
        await query.order('updated_at', ascending: true).limit(500);

    if (response.isEmpty) return 0;

    final db = await AppDb.instance;
    int applied = 0;
    for (final cloud in response) {
      final cloudId = cloud['cloud_id'] as String?;
      if (cloudId == null || cloudId.isEmpty) continue;
      final softDeletedIso = cloud['deleted_at'];
      if (softDeletedIso != null) {
        await _deleteByCloudId(db, cloudId);
      } else {
        await _writeOne(db, cloud);
      }
      applied++;
    }
    return applied;
  }

  /// Default soft-delete handler — physically remove the local row
  /// matching the cloud_id. Singletons override since the local PK
  /// is `user_id = 1`, not row-keyed.
  Future<void> _deleteByCloudId(Database db, String cloudId) async {
    await db.delete(
      tableName,
      where: '${CSync.cloudId} = ?',
      whereArgs: [cloudId],
    );
  }

  Future<void> _writeOne(Database db, Map<String, dynamic> cloud) async {
    final cloudId = cloud['cloud_id'] as String?;
    if (cloudId == null || cloudId.isEmpty) return;

    final localRow = await toLocalRow(cloud.cast<String, Object?>());

    // Inject sync-meta columns. `cloud_updated_at` mirrors the cloud
    // row's `updated_at` so future pushes can do conflict resolution.
    localRow[CSync.cloudId] = cloudId;
    localRow[CSync.cloudUpdatedAt] = isoToUnixSeconds(cloud['updated_at']);
    localRow[CSync.cloudDeletedAt] = isoToUnixSeconds(cloud['deleted_at']);

    await _upsertByCloudId(db, localRow, cloudId);
  }

  /// Insert the row, or update the existing one matched by `cloud_id`.
  /// Subclasses with PK constraints that need different handling
  /// (singletons keyed on `user_id`) override this.
  Future<void> _upsertByCloudId(
    Database db,
    Map<String, Object?> row,
    String cloudId,
  ) async {
    final existing = await db.query(
      tableName,
      columns: ['id'],
      where: '${CSync.cloudId} = ?',
      whereArgs: [cloudId],
      limit: 1,
    );
    if (existing.isEmpty) {
      // INSERT — let SQLite assign the auto-inc PK.
      row.remove('id');
      await db.insert(tableName, row,
          conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      final localId = existing.first['id'];
      row.remove('id');
      await db.update(
        tableName,
        row,
        where: 'id = ?',
        whereArgs: [localId],
      );
    }
  }
}

/// Mixin for singletons keyed on `user_id` (always 1 locally). The
/// REPLACE semantics of `INSERT OR REPLACE` collapse the row into the
/// fixed user_id slot regardless of what cloud_id arrived.
mixin _SingletonByUserId on _CloudPullHandler {
  @override
  Future<void> _upsertByCloudId(
    Database db,
    Map<String, Object?> row,
    String cloudId,
  ) async {
    row.remove('id');
    await db.insert(tableName, row,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }
}

/// Mixin for tables with a UNIQUE constraint other than `cloud_id` —
/// muscle_ranks `(user_id, muscle)`, weight_logs `(user_id, logged_on)`.
/// Replace semantics collapse onto the natural key.
mixin _UpsertByNaturalKey on _CloudPullHandler {
  @override
  Future<void> _upsertByCloudId(
    Database db,
    Map<String, Object?> row,
    String cloudId,
  ) async {
    row.remove('id');
    await db.insert(tableName, row,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }
}

// ─────────────────────────────────────────────────────────────────
// Singletons
// ─────────────────────────────────────────────────────────────────

class PlayerPullHandler extends _CloudPullHandler with _SingletonByUserId {
  const PlayerPullHandler();
  @override
  String get tableName => T.player;
  @override
  String get cloudTable => 'cloud_player';

  @override
  Future<Map<String, Object?>> toLocalRow(Map<String, Object?> c) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return {
      CPlayer.id: 1,
      CPlayer.displayName: c['display_name'] ?? 'Player',
      CPlayer.age: c['age'] ?? 0,
      CPlayer.heightCm: c['height_cm'] ?? 0,
      CPlayer.weightKg: c['weight_kg'] ?? 0,
      CPlayer.bodyFatEstimate: c['body_fat_estimate'],
      CPlayer.unitsPref: c['units_pref'] ?? 'metric',
      CPlayer.onboardedAt: isoToUnixSeconds(c['onboarded_at']),
      CPlayer.createdAt: isoToUnixSeconds(c['created_at']) ?? now,
      CPlayer.updatedAt: isoToUnixSeconds(c['updated_at']) ?? now,
    };
  }
}

class GoalsPullHandler extends _CloudPullHandler with _SingletonByUserId {
  const GoalsPullHandler();
  @override
  String get tableName => T.goals;
  @override
  String get cloudTable => 'cloud_goals';

  @override
  Future<Map<String, Object?>> toLocalRow(Map<String, Object?> c) async {
    return {
      CGoals.userId: 1,
      CGoals.bodyType: c['body_type'],
      CGoals.priorityMuscles: listToJsonString(c['priority_muscles']),
      CGoals.rewardStyle: c['reward_style'],
      CGoals.weightDirection: c['weight_direction'],
      CGoals.targetWeightKg: c['target_weight_kg'],
      CGoals.updatedAt: isoToUnixSeconds(c['updated_at']) ??
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };
  }
}

class ExperiencePullHandler extends _CloudPullHandler with _SingletonByUserId {
  const ExperiencePullHandler();
  @override
  String get tableName => T.experience;
  @override
  String get cloudTable => 'cloud_experience';

  @override
  Future<Map<String, Object?>> toLocalRow(Map<String, Object?> c) async {
    return {
      CExperience.userId: 1,
      CExperience.tenure: c['tenure'],
      CExperience.equipment: listToJsonString(c['equipment']),
      CExperience.limitations: listToJsonString(c['limitations']),
      CExperience.styles: listToJsonString(c['styles']),
      CExperience.updatedAt: isoToUnixSeconds(c['updated_at']) ??
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };
  }
}

class SchedulePullHandler extends _CloudPullHandler with _SingletonByUserId {
  const SchedulePullHandler();
  @override
  String get tableName => T.schedule;
  @override
  String get cloudTable => 'cloud_schedule';

  @override
  Future<Map<String, Object?>> toLocalRow(Map<String, Object?> c) async {
    return {
      CSchedule.userId: 1,
      CSchedule.days: listToJsonString(c['days']),
      CSchedule.sessionMinutes: c['session_minutes'],
      CSchedule.updatedAt: isoToUnixSeconds(c['updated_at']) ??
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };
  }
}

class NotificationPrefsPullHandler extends _CloudPullHandler
    with _SingletonByUserId {
  const NotificationPrefsPullHandler();
  @override
  String get tableName => T.notificationPrefs;
  @override
  String get cloudTable => 'cloud_notification_prefs';

  @override
  Future<Map<String, Object?>> toLocalRow(Map<String, Object?> c) async {
    return {
      CNotificationPrefs.userId: 1,
      CNotificationPrefs.workoutReminders: boolToInt(c['workout_reminders']),
      CNotificationPrefs.streakWarnings: boolToInt(c['streak_warnings']),
      CNotificationPrefs.weeklyReports: boolToInt(c['weekly_reports']),
    };
  }
}

class PlayerClassPullHandler extends _CloudPullHandler
    with _SingletonByUserId {
  const PlayerClassPullHandler();
  @override
  String get tableName => T.playerClass;
  @override
  String get cloudTable => 'cloud_player_class';

  @override
  Future<Map<String, Object?>> toLocalRow(Map<String, Object?> c) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return {
      CPlayerClass.userId: 1,
      CPlayerClass.classKey: c['class_key'] ?? '',
      CPlayerClass.assignedAt: isoToUnixSeconds(c['assigned_at']) ?? now,
      CPlayerClass.lastChangedAt: isoToUnixSeconds(c['last_changed_at']) ?? now,
      CPlayerClass.evolutionHistory: listToJsonString(c['evolution_history']),
    };
  }
}

class StreakPullHandler extends _CloudPullHandler with _SingletonByUserId {
  const StreakPullHandler();
  @override
  String get tableName => T.streaks;
  @override
  String get cloudTable => 'cloud_streak';

  @override
  Future<Map<String, Object?>> toLocalRow(Map<String, Object?> c) async {
    return {
      CStreak.userId: 1,
      CStreak.current: c['current'] ?? 0,
      CStreak.longest: c['longest'] ?? 0,
      CStreak.lastActiveDate: dateStringToUnixSeconds(c['last_active_date']),
      CStreak.freezesRemaining: c['freezes_remaining'] ?? 1,
      CStreak.freezesPeriodStart:
          dateStringToUnixSeconds(c['freezes_period_start']) ??
              DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };
  }
}

// ─────────────────────────────────────────────────────────────────
// Append-only history
// ─────────────────────────────────────────────────────────────────

class WorkoutsPullHandler extends _CloudPullHandler {
  const WorkoutsPullHandler();
  @override
  String get tableName => T.workouts;
  @override
  String get cloudTable => 'cloud_workouts';

  @override
  Future<Map<String, Object?>> toLocalRow(Map<String, Object?> c) async {
    return {
      CWorkout.userId: 1,
      CWorkout.startedAt: isoToUnixSeconds(c['started_at']) ?? 0,
      CWorkout.endedAt: isoToUnixSeconds(c['ended_at']),
      CWorkout.xpEarned: c['xp_earned'] ?? 0,
      CWorkout.volumeKg: c['volume_kg'] ?? 0,
      CWorkout.note: c['note'],
    };
  }
}

class SetsPullHandler extends _CloudPullHandler {
  const SetsPullHandler();
  @override
  String get tableName => T.sets;
  @override
  String get cloudTable => 'cloud_sets';

  @override
  Future<Map<String, Object?>> toLocalRow(Map<String, Object?> c) async {
    // workout_id in the cloud is the parent's UUID; locally it's the
    // int auto-inc PK. Resolve via the cloud_id column on workouts —
    // workouts are pulled before sets so this lookup is reliable.
    final db = await AppDb.instance;
    final cloudWorkoutId = c['workout_id'] as String?;
    int? localWorkoutId;
    if (cloudWorkoutId != null && cloudWorkoutId.isNotEmpty) {
      final rows = await db.query(
        T.workouts,
        columns: [CWorkout.id],
        where: '${CSync.cloudId} = ?',
        whereArgs: [cloudWorkoutId],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        localWorkoutId = rows.first[CWorkout.id] as int?;
      }
    }
    return {
      // workoutId NOT NULL FK — if we couldn't resolve, the row is
      // skipped by `_upsertByCloudId` below (we throw to bail).
      CSet.workoutId: localWorkoutId ?? 0,
      CSet.exerciseId: c['exercise_id'] ?? 0,
      CSet.setNumber: c['set_number'] ?? 1,
      CSet.weightKg: c['weight_kg'],
      CSet.reps: c['reps'] ?? 0,
      CSet.rpe: c['rpe'],
      CSet.isPr: boolToInt(c['is_pr']),
      CSet.xpEarned: c['xp_earned'] ?? 0,
      CSet.completedAt: isoToUnixSeconds(c['completed_at']) ?? 0,
    };
  }

  @override
  Future<void> _upsertByCloudId(
    Database db,
    Map<String, Object?> row,
    String cloudId,
  ) async {
    // Skip orphaned sets — workout_id 0 means we couldn't resolve the
    // parent's local id. The next pull-pass (after the parent lands)
    // will pick it up.
    if (row[CSet.workoutId] == 0) return;
    return super._upsertByCloudId(db, row, cloudId);
  }
}

class QuestsPullHandler extends _CloudPullHandler {
  const QuestsPullHandler();
  @override
  String get tableName => T.quests;
  @override
  String get cloudTable => 'cloud_quests';

  @override
  Future<Map<String, Object?>> toLocalRow(Map<String, Object?> c) async {
    return {
      CQuest.userId: 1,
      CQuest.type: c['type'] ?? 'daily',
      CQuest.title: c['title'] ?? '',
      CQuest.description: c['description'],
      CQuest.target: c['target'] ?? 1,
      CQuest.progress: c['progress'] ?? 0,
      CQuest.xpReward: c['xp_reward'] ?? 0,
      CQuest.issuedAt: isoToUnixSeconds(c['issued_at']) ?? 0,
      CQuest.expiresAt: isoToUnixSeconds(c['expires_at']),
      CQuest.completedAt: isoToUnixSeconds(c['completed_at']),
      CQuest.locked: boolToInt(c['locked']),
    };
  }
}

class StreakFreezeEventsPullHandler extends _CloudPullHandler {
  const StreakFreezeEventsPullHandler();
  @override
  String get tableName => T.streakFreezeEvents;
  @override
  String get cloudTable => 'cloud_streak_freeze_events';

  @override
  Future<Map<String, Object?>> toLocalRow(Map<String, Object?> c) async {
    return {
      CStreakFreezeEvent.userId: 1,
      CStreakFreezeEvent.usedOn: dateStringToUnixSeconds(c['used_on']) ?? 0,
      CStreakFreezeEvent.reason: c['reason'],
    };
  }
}

class WeightLogsPullHandler extends _CloudPullHandler with _UpsertByNaturalKey {
  const WeightLogsPullHandler();
  @override
  String get tableName => T.weightLogs;
  @override
  String get cloudTable => 'cloud_weight_logs';

  @override
  Future<Map<String, Object?>> toLocalRow(Map<String, Object?> c) async {
    return {
      CWeightLog.userId: 1,
      CWeightLog.loggedOn: dateStringToUnixSeconds(c['logged_on']) ?? 0,
      CWeightLog.weightKg: c['weight_kg'] ?? 0,
      CWeightLog.note: c['note'],
    };
  }
}

class MuscleRanksPullHandler extends _CloudPullHandler with _UpsertByNaturalKey {
  const MuscleRanksPullHandler();
  @override
  String get tableName => T.muscleRanks;
  @override
  String get cloudTable => 'cloud_muscle_ranks';

  @override
  Future<Map<String, Object?>> toLocalRow(Map<String, Object?> c) async {
    return {
      CMuscleRank.userId: 1,
      CMuscleRank.muscle: c['muscle'] ?? '',
      CMuscleRank.rank: c['rank'] ?? 'F',
      CMuscleRank.subRank: c['sub_rank'],
      CMuscleRank.rankXp: c['rank_xp'] ?? 0,
      CMuscleRank.updatedAt: isoToUnixSeconds(c['updated_at']) ??
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };
  }
}

// ─────────────────────────────────────────────────────────────────
// Production registry
// ─────────────────────────────────────────────────────────────────

extension PullHandlerRegistryProduction on PullHandlerRegistry {
  static PullHandlerRegistry production() {
    final reg = PullHandlerRegistry.empty();
    const handlers = <PullHandler>[
      PlayerPullHandler(),
      GoalsPullHandler(),
      ExperiencePullHandler(),
      SchedulePullHandler(),
      NotificationPrefsPullHandler(),
      MuscleRanksPullHandler(),
      StreakPullHandler(),
      PlayerClassPullHandler(),
      WorkoutsPullHandler(),
      SetsPullHandler(),
      QuestsPullHandler(),
      StreakFreezeEventsPullHandler(),
      WeightLogsPullHandler(),
    ];
    for (final h in handlers) {
      reg.register(h);
    }
    return reg;
  }
}

// Default page size constant exported for callers (orchestrator).
int get pullPageSize => _defaultPageSize;
