import 'package:sqflite/sqflite.dart';

import '../app_db.dart';
import '../models/goal.dart';
import '../schema.dart';
import '../sync/outbox_enqueuer.dart';
import '_now.dart';

class GoalsService {
  GoalsService._();

  static Future<Goal?> get() async {
    final db = await AppDb.instance;
    final rows = await db.query(T.goals,
        where: '${CGoals.userId} = ?', whereArgs: [1], limit: 1);
    return rows.isEmpty ? null : Goal.fromRow(rows.first);
  }

  static Future<void> upsert(Goal goal) async {
    final db = await AppDb.instance;
    await db.insert(
      T.goals,
      Goal(
        userId: 1,
        bodyType: goal.bodyType,
        priorityMuscles: goal.priorityMuscles,
        rewardStyle: goal.rewardStyle,
        weightDirection: goal.weightDirection,
        targetWeightKg: goal.targetWeightKg,
        updatedAt: nowSeconds(),
      ).toRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await OutboxEnqueuer.upsertSingletonByUserId(T.goals);
  }

  /// Patches a subset of goal columns. Creates the row if missing.
  static Future<void> patch({
    String? bodyType,
    List<String>? priorityMuscles,
    String? rewardStyle,
    String? weightDirection,
    double? targetWeightKg,
  }) async {
    final existing = (await get()) ?? Goal(updatedAt: nowSeconds());
    await upsert(existing.copyWith(
      bodyType: bodyType,
      priorityMuscles: priorityMuscles,
      rewardStyle: rewardStyle,
      weightDirection: weightDirection,
      targetWeightKg: targetWeightKg,
    ));
  }
}
