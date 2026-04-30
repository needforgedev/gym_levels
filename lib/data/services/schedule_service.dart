import 'package:sqflite/sqflite.dart';

import '../app_db.dart';
import '../models/schedule_row.dart';
import '../schema.dart';
import '../sync/outbox_enqueuer.dart';
import '_now.dart';

class ScheduleService {
  ScheduleService._();

  static Future<ScheduleRow?> get() async {
    final db = await AppDb.instance;
    final rows = await db.query(T.schedule,
        where: '${CSchedule.userId} = ?', whereArgs: [1], limit: 1);
    return rows.isEmpty ? null : ScheduleRow.fromRow(rows.first);
  }

  static Future<void> upsert(ScheduleRow row) async {
    final db = await AppDb.instance;
    await db.insert(
      T.schedule,
      ScheduleRow(
        userId: 1,
        days: row.days,
        sessionMinutes: row.sessionMinutes,
        updatedAt: nowSeconds(),
      ).toRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await OutboxEnqueuer.upsertSingletonByUserId(T.schedule);
  }

  /// Patches a subset of schedule columns. Creates the row if missing.
  static Future<void> patch({
    List<int>? days,
    int? sessionMinutes,
  }) async {
    final existing = (await get()) ?? ScheduleRow(updatedAt: nowSeconds());
    await upsert(existing.copyWith(
      days: days,
      sessionMinutes: sessionMinutes,
    ));
  }
}
