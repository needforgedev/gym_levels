import 'package:sqflite/sqflite.dart';

import '../app_db.dart';
import '../models/streak.dart';
import '../models/streak_freeze_event.dart';
import '../schema.dart';
import '../sync/outbox_enqueuer.dart';
import '_now.dart';
import 'leaderboard_stats_service.dart';

class StreakService {
  StreakService._();

  static Future<Streak?> get() async {
    final db = await AppDb.instance;
    final rows = await db.query(T.streaks,
        where: '${CStreak.userId} = ?', whereArgs: [1], limit: 1);
    return rows.isEmpty ? null : Streak.fromRow(rows.first);
  }

  /// Create the row with starting values if absent.
  static Future<Streak> ensure() async {
    final existing = await get();
    if (existing != null) return existing;
    final row = Streak(freezesPeriodStart: nowSeconds());
    final db = await AppDb.instance;
    await db.insert(T.streaks, row.toRow(),
        conflictAlgorithm: ConflictAlgorithm.abort);
    await OutboxEnqueuer.upsertSingletonByUserId(T.streaks);
    return row;
  }

  static Future<void> upsert(Streak streak) async {
    final db = await AppDb.instance;
    await db.insert(T.streaks, streak.toRow(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    await OutboxEnqueuer.upsertSingletonByUserId(T.streaks);
    // current/longest streak just changed — keep public_profiles in
    // lockstep so friends' leaderboard streak column is current.
    await LeaderboardStatsService.refresh();
  }

  /// PRD §9A.5 — log a freeze consumption. Caller is responsible for also
  /// decrementing `freezesRemaining` via `upsert`.
  static Future<int> logFreezeUsed({
    required int dayEpoch,
    String? reason,
  }) async {
    final db = await AppDb.instance;
    final id = await db.insert(
      T.streakFreezeEvents,
      StreakFreezeEvent(usedOn: dayEpoch, reason: reason).toRow(),
    );
    await OutboxEnqueuer.upsertAutoinc(table: T.streakFreezeEvents, id: id);
    return id;
  }
}
