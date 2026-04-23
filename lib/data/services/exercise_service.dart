import 'package:sqflite/sqflite.dart';

import '../app_db.dart';
import '../models/exercise.dart';
import '../schema.dart';

/// Exercise catalog — seeded from `assets/seed/exercises.sql` in Phase 1.3.
class ExerciseService {
  ExerciseService._();

  static Future<List<Exercise>> getAll() async {
    final db = await AppDb.instance;
    final rows = await db.query(T.exercises,
        orderBy: '${CExercise.primaryMuscle} ASC, ${CExercise.name} ASC');
    return rows.map(Exercise.fromRow).toList();
  }

  static Future<Exercise?> byId(int id) async {
    final db = await AppDb.instance;
    final rows = await db.query(T.exercises,
        where: '${CExercise.id} = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : Exercise.fromRow(rows.first);
  }

  static Future<List<Exercise>> byPrimaryMuscle(String muscle) async {
    final db = await AppDb.instance;
    final rows = await db.query(
      T.exercises,
      where: '${CExercise.primaryMuscle} = ?',
      whereArgs: [muscle],
      orderBy: '${CExercise.name} ASC',
    );
    return rows.map(Exercise.fromRow).toList();
  }

  static Future<int> count() async {
    final db = await AppDb.instance;
    final r = await db.rawQuery('SELECT COUNT(*) AS n FROM ${T.exercises}');
    return (r.first['n'] as int?) ?? 0;
  }

  /// Bulk insert, skipping rows whose `name` already exists (catalog is
  /// idempotent — seed is safe to re-run on app upgrade).
  static Future<void> insertBatch(List<Exercise> exercises) async {
    final db = await AppDb.instance;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final e in exercises) {
        batch.insert(T.exercises, e.toRow(),
            conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      await batch.commit(noResult: true);
    });
  }
}
