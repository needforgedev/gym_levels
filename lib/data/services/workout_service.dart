import '../app_db.dart';
import '../models/workout.dart';
import '../schema.dart';
import '_now.dart';

class WorkoutService {
  WorkoutService._();

  /// Insert a new in-progress workout and return its id.
  static Future<int> start() async {
    final db = await AppDb.instance;
    return db.insert(T.workouts, Workout(startedAt: nowSeconds()).toRow());
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
  /// every logged set in the same transaction.
  static Future<void> delete(int id) async {
    final db = await AppDb.instance;
    await db.delete(T.workouts, where: '${CWorkout.id} = ?', whereArgs: [id]);
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
}
