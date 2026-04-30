import 'package:sqflite/sqflite.dart';

import '../app_db.dart';
import '../models/muscle_rank.dart';
import '../schema.dart';
import '../sync/outbox_enqueuer.dart';
import '_now.dart';

class MuscleRankService {
  MuscleRankService._();

  static Future<List<MuscleRank>> getAll() async {
    final db = await AppDb.instance;
    final rows = await db.query(
      T.muscleRanks,
      where: '${CMuscleRank.userId} = ?',
      whereArgs: [1],
      orderBy: '${CMuscleRank.muscle} ASC',
    );
    return rows.map(MuscleRank.fromRow).toList();
  }

  static Future<MuscleRank?> forMuscle(String muscle) async {
    final db = await AppDb.instance;
    final rows = await db.query(
      T.muscleRanks,
      where: '${CMuscleRank.userId} = ? AND ${CMuscleRank.muscle} = ?',
      whereArgs: [1, muscle],
      limit: 1,
    );
    return rows.isEmpty ? null : MuscleRank.fromRow(rows.first);
  }

  static Future<void> upsert({
    required String muscle,
    required String rank,
    String? subRank,
    required int rankXp,
  }) async {
    final db = await AppDb.instance;
    await db.insert(
      T.muscleRanks,
      MuscleRank(
        muscle: muscle,
        rank: rank,
        subRank: subRank,
        rankXp: rankXp,
        updatedAt: nowSeconds(),
      ).toRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await OutboxEnqueuer.upsertMuscleRank(muscle);
  }
}
