import '../app_db.dart';
import '../models/quest.dart';
import '../schema.dart';
import '_now.dart';

/// Quest CRUD only. Rotation / progress logic lives in Phase 2's gameplay
/// services layer; this service is the persistence seam.
class QuestService {
  QuestService._();

  static Future<int> insert(Quest quest) async {
    final db = await AppDb.instance;
    return db.insert(T.quests, quest.toRow());
  }

  /// Active quests of a given type (`daily` / `weekly` / `boss`).
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
  }

  static Future<void> complete(int id) async {
    final db = await AppDb.instance;
    await db.update(T.quests, {CQuest.completedAt: nowSeconds()},
        where: '${CQuest.id} = ?', whereArgs: [id]);
  }
}
