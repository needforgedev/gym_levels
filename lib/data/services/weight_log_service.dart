import 'package:sqflite/sqflite.dart';

import '../app_db.dart';
import '../models/weight_log.dart';
import '../schema.dart';
import '../sync/outbox_enqueuer.dart';

class WeightLogService {
  WeightLogService._();

  static Future<List<WeightLog>> all() async {
    final db = await AppDb.instance;
    final rows = await db.query(
      T.weightLogs,
      where: '${CWeightLog.userId} = ?',
      whereArgs: [1],
      orderBy: '${CWeightLog.loggedOn} DESC',
    );
    return rows.map(WeightLog.fromRow).toList();
  }

  static Future<WeightLog?> latest() async {
    final db = await AppDb.instance;
    final rows = await db.query(
      T.weightLogs,
      where: '${CWeightLog.userId} = ?',
      whereArgs: [1],
      orderBy: '${CWeightLog.loggedOn} DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : WeightLog.fromRow(rows.first);
  }

  /// PRD §9A.6 — at most one log per day. Uses the UNIQUE constraint +
  /// `REPLACE` to overwrite an existing entry for the same day.
  static Future<void> upsertForDay({
    required int dayEpoch,
    required double weightKg,
    String? note,
  }) async {
    final db = await AppDb.instance;
    final id = await db.insert(
      T.weightLogs,
      WeightLog(loggedOn: dayEpoch, weightKg: weightKg, note: note).toRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    // ConflictAlgorithm.replace returns the new row id (existing
    // row is deleted then re-inserted). Pass directly.
    await OutboxEnqueuer.upsertAutoinc(table: T.weightLogs, id: id);
  }
}
