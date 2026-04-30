import '../app_db.dart';
import '../models/workout_set.dart';
import '../schema.dart';
import '../sync/outbox_enqueuer.dart';

class SetsService {
  SetsService._();

  static Future<int> insertSet(WorkoutSet set) async {
    final db = await AppDb.instance;
    final id = await db.insert(T.sets, set.toRow());
    // Pre-resolve the parent workout's cloud_id so the push handler
    // doesn't have to round-trip the local DB at drain time.
    final parent = await db.query(
      T.workouts,
      columns: [CSync.cloudId],
      where: '${CWorkout.id} = ?',
      whereArgs: [set.workoutId],
      limit: 1,
    );
    final parentCloudId =
        parent.isEmpty ? null : parent.first[CSync.cloudId] as String?;
    await OutboxEnqueuer.upsertAutoinc(
      table: T.sets,
      id: id,
      extraPayload: parentCloudId == null
          ? null
          : {'workout_cloud_id': parentCloudId},
    );
    return id;
  }

  static Future<List<WorkoutSet>> forWorkout(int workoutId) async {
    final db = await AppDb.instance;
    final rows = await db.query(
      T.sets,
      where: '${CSet.workoutId} = ?',
      whereArgs: [workoutId],
      orderBy: '${CSet.setNumber} ASC',
    );
    return rows.map(WorkoutSet.fromRow).toList();
  }

  /// Best prior set (highest weight, then highest reps) for an exercise.
  /// Used by XpService for PR detection in Phase 2.
  static Future<WorkoutSet?> bestFor(int exerciseId) async {
    final db = await AppDb.instance;
    final rows = await db.query(
      T.sets,
      where: '${CSet.exerciseId} = ?',
      whereArgs: [exerciseId],
      orderBy: '${CSet.weightKg} DESC, ${CSet.reps} DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : WorkoutSet.fromRow(rows.first);
  }

  /// Total volume (kg × reps) across a workout — feeds WorkoutService.finish.
  static Future<double> volumeFor(int workoutId) async {
    final db = await AppDb.instance;
    final r = await db.rawQuery(
      'SELECT COALESCE(SUM(${CSet.weightKg} * ${CSet.reps}), 0) AS v '
      'FROM ${T.sets} WHERE ${CSet.workoutId} = ?',
      [workoutId],
    );
    return (r.first['v'] as num?)?.toDouble() ?? 0;
  }
}
