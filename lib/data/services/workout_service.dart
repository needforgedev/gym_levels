import '../app_db.dart';
import '../models/sync_outbox.dart';
import '../models/workout.dart';
import '../schema.dart';
import '../sync/outbox_enqueuer.dart';
import '_now.dart';
import 'leaderboard_stats_service.dart';
import 'sync_outbox_service.dart';

class WorkoutService {
  WorkoutService._();

  /// Insert a new in-progress workout and return its id. Enqueues an
  /// outbox push immediately so the row gets a `cloud_id` up-front —
  /// sets logged later can FK-reference it without waiting for the
  /// workout to "finish".
  static Future<int> start() async {
    final db = await AppDb.instance;
    final id =
        await db.insert(T.workouts, Workout(startedAt: nowSeconds()).toRow());
    await OutboxEnqueuer.upsertAutoinc(table: T.workouts, id: id);
    return id;
  }

  /// Mark a workout finished. Totals are pre-computed by callers.
  static Future<void> finish(
    int id, {
    required int xpEarned,
    required double volumeKg,
  }) async {
    final db = await AppDb.instance;
    await db.update(
      T.workouts,
      {
        CWorkout.endedAt: nowSeconds(),
        CWorkout.xpEarned: xpEarned,
        CWorkout.volumeKg: volumeKg,
      },
      where: '${CWorkout.id} = ?',
      whereArgs: [id],
    );
    await OutboxEnqueuer.upsertAutoinc(table: T.workouts, id: id);
    // Total / weekly XP + last_active just changed — push the new
    // public_profiles snapshot so the leaderboard reflects it. Best-
    // effort; failure is non-fatal.
    await LeaderboardStatsService.refresh();
  }

  /// Add XP on top of what was set by `finish`. Used by `GameHandlers` to
  /// fold in quest-reward XP once the quest engine has resolved which
  /// quests were just completed.
  static Future<void> addXp(int id, int extraXp) async {
    if (extraXp <= 0) return;
    final db = await AppDb.instance;
    await db.rawUpdate(
      'UPDATE ${T.workouts} '
      'SET ${CWorkout.xpEarned} = COALESCE(${CWorkout.xpEarned}, 0) + ? '
      'WHERE ${CWorkout.id} = ?',
      [extraXp, id],
    );
    await OutboxEnqueuer.upsertAutoinc(table: T.workouts, id: id);
    await LeaderboardStatsService.refresh();
  }

  static Future<Workout?> byId(int id) async {
    final db = await AppDb.instance;
    final rows = await db.query(T.workouts,
        where: '${CWorkout.id} = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : Workout.fromRow(rows.first);
  }

  static Future<List<Workout>> recent({int limit = 30}) async {
    final db = await AppDb.instance;
    final rows = await db.query(
      T.workouts,
      where: '${CWorkout.userId} = ?',
      whereArgs: [1],
      orderBy: '${CWorkout.startedAt} DESC',
      limit: limit,
    );
    return rows.map(Workout.fromRow).toList();
  }

  /// Count of finished workouts — surfaces on Home as "Total Workouts".
  static Future<int> totalFinished() async {
    final db = await AppDb.instance;
    final r = await db.rawQuery(
      'SELECT COUNT(*) AS n FROM ${T.workouts} '
      'WHERE ${CWorkout.userId} = ? AND ${CWorkout.endedAt} IS NOT NULL',
      [1],
    );
    return (r.first['n'] as int?) ?? 0;
  }

  /// Delete a workout. FK `ON DELETE CASCADE` on the `sets` table removes
  /// every logged set in the same transaction. Reads the row first so
  /// we can enqueue a soft-delete (carries the cloud_id forward); falls
  /// back to a no-op enqueue if the row was never pushed (no cloud_id).
  static Future<void> delete(int id) async {
    final db = await AppDb.instance;
    // Snapshot cloud_id before the delete so we can push the soft-delete.
    final rows = await db.query(
      T.workouts,
      columns: [CSync.cloudId],
      where: '${CWorkout.id} = ?',
      whereArgs: [id],
      limit: 1,
    );
    final cloudId = rows.isEmpty ? null : rows.first[CSync.cloudId] as String?;

    await db.delete(T.workouts, where: '${CWorkout.id} = ?', whereArgs: [id]);

    if (cloudId != null && cloudId.isNotEmpty) {
      // Direct enqueue — the row is already gone locally, so we can't
      // round-trip through OutboxEnqueuer's "read row" path.
      try {
        await SyncOutboxService.enqueue(
          tableName: T.workouts,
          localRowId: id,
          cloudId: cloudId,
          opType: SyncOpType.delete,
        );
      } catch (_) {/* see OutboxEnqueuer — non-fatal */}
    }
  }

  /// Lifetime XP (sum of `xp_earned` across finished workouts). Feeds
  /// `XpEngine.resolve` so Home's level + XP bar reflect real data.
  static Future<int> totalXp() async {
    final db = await AppDb.instance;
    final r = await db.rawQuery(
      'SELECT COALESCE(SUM(${CWorkout.xpEarned}), 0) AS x '
      'FROM ${T.workouts} WHERE ${CWorkout.userId} = ?',
      [1],
    );
    return (r.first['x'] as num?)?.toInt() ?? 0;
  }

  /// XP earned since the most recent Monday 00:00 UTC. Drives the
  /// leaderboard's Weekly XP tab + the `public_profiles.weekly_xp`
  /// column (which the server's Monday cron resets to 0). Mirrors
  /// the rollover semantics the cron job in 007_cron.sql uses.
  static Future<int> weeklyXp() async {
    final now = DateTime.now().toUtc();
    // Monday is weekday 1 in Dart (Sun=7, Mon=1, …). Walk back to
    // the most recent Monday at 00:00 UTC.
    final daysSinceMonday = (now.weekday + 6) % 7; // Mon → 0, Tue → 1…
    final monday = DateTime.utc(now.year, now.month, now.day)
        .subtract(Duration(days: daysSinceMonday));
    final mondayEpoch = monday.millisecondsSinceEpoch ~/ 1000;
    final db = await AppDb.instance;
    final r = await db.rawQuery(
      'SELECT COALESCE(SUM(${CWorkout.xpEarned}), 0) AS x '
      'FROM ${T.workouts} '
      'WHERE ${CWorkout.userId} = ? AND ${CWorkout.endedAt} >= ?',
      [1, mondayEpoch],
    );
    return (r.first['x'] as num?)?.toInt() ?? 0;
  }

  /// XP earned since the 1st of the current UTC month. Drives the
  /// leaderboard's Month tab + the `public_profiles.monthly_xp`
  /// column (which the server's 1st-of-month cron resets to 0).
  static Future<int> monthlyXp() async {
    final now = DateTime.now().toUtc();
    final firstOfMonth = DateTime.utc(now.year, now.month, 1);
    final firstEpoch = firstOfMonth.millisecondsSinceEpoch ~/ 1000;
    final db = await AppDb.instance;
    final r = await db.rawQuery(
      'SELECT COALESCE(SUM(${CWorkout.xpEarned}), 0) AS x '
      'FROM ${T.workouts} '
      'WHERE ${CWorkout.userId} = ? AND ${CWorkout.endedAt} >= ?',
      [1, firstEpoch],
    );
    return (r.first['x'] as num?)?.toInt() ?? 0;
  }

  /// Most recent finished workout whose `ended_at` falls on the current
  /// local calendar day. `null` if the user hasn't finished anything today.
  /// Drives the "already done" state on Home + Today's Workout.
  static Future<Workout?> finishedToday() async {
    final db = await AppDb.instance;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day)
            .millisecondsSinceEpoch ~/
        1000;
    final rows = await db.query(
      T.workouts,
      where: '${CWorkout.userId} = ? '
          'AND ${CWorkout.endedAt} IS NOT NULL '
          'AND ${CWorkout.endedAt} >= ?',
      whereArgs: [1, startOfDay],
      orderBy: '${CWorkout.endedAt} DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : Workout.fromRow(rows.first);
  }
}
