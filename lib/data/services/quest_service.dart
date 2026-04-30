import '../app_db.dart';
import '../models/quest.dart';
import '../schema.dart';
import '../sync/outbox_enqueuer.dart';
import '_now.dart';

/// Quest CRUD only. Rotation / progress logic lives in Phase 2's gameplay
/// services layer; this service is the persistence seam.
class QuestService {
  QuestService._();

  static Future<int> insert(Quest quest) async {
    final db = await AppDb.instance;
    final id = await db.insert(T.quests, quest.toRow());
    await OutboxEnqueuer.upsertAutoinc(table: T.quests, id: id);
    return id;
  }

  /// Active (not-yet-completed) quests of a given type
  /// (`daily` / `weekly` / `boss`).
  static Future<List<Quest>> active(String type) async {
    final db = await AppDb.instance;
    final rows = await db.query(
      T.quests,
      where: '${CQuest.userId} = ? AND ${CQuest.type} = ? '
          'AND ${CQuest.completedAt} IS NULL',
      whereArgs: [1, type],
      orderBy: '${CQuest.issuedAt} ASC',
    );
    return rows.map(Quest.fromRow).toList();
  }

  /// Every quest of a given type issued at or after [sinceEpoch],
  /// regardless of completion. Drives today's quest UI: users should keep
  /// seeing a completed quest stamped "DONE" for the rest of the day
  /// instead of having it disappear (which the rotation logic would then
  /// misread as "time to issue a fresh batch").
  static Future<List<Quest>> issuedSince(String type, int sinceEpoch) async {
    final db = await AppDb.instance;
    final rows = await db.query(
      T.quests,
      where: '${CQuest.userId} = ? AND ${CQuest.type} = ? '
          'AND ${CQuest.issuedAt} >= ?',
      whereArgs: [1, type, sinceEpoch],
      orderBy: '${CQuest.issuedAt} ASC',
    );
    return rows.map(Quest.fromRow).toList();
  }

  static Future<List<Quest>> all() async {
    final db = await AppDb.instance;
    final rows = await db.query(T.quests,
        where: '${CQuest.userId} = ?',
        whereArgs: [1],
        orderBy: '${CQuest.issuedAt} DESC');
    return rows.map(Quest.fromRow).toList();
  }

  static Future<void> updateProgress(int id, int progress) async {
    final db = await AppDb.instance;
    await db.update(T.quests, {CQuest.progress: progress},
        where: '${CQuest.id} = ?', whereArgs: [id]);
    await OutboxEnqueuer.upsertAutoinc(table: T.quests, id: id);
  }

  static Future<void> complete(int id) async {
    final db = await AppDb.instance;
    await db.update(T.quests, {CQuest.completedAt: nowSeconds()},
        where: '${CQuest.id} = ?', whereArgs: [id]);
    await OutboxEnqueuer.upsertAutoinc(table: T.quests, id: id);
  }
}
