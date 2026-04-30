import 'package:sqflite/sqflite.dart';

import '../app_db.dart';
import '../models/notification_prefs.dart';
import '../schema.dart';
import '../sync/outbox_enqueuer.dart';

class NotificationPrefsService {
  NotificationPrefsService._();

  static Future<NotificationPrefs?> get() async {
    final db = await AppDb.instance;
    final rows = await db.query(T.notificationPrefs,
        where: '${CNotificationPrefs.userId} = ?', whereArgs: [1], limit: 1);
    return rows.isEmpty ? null : NotificationPrefs.fromRow(rows.first);
  }

  static Future<void> upsert(NotificationPrefs prefs) async {
    final db = await AppDb.instance;
    await db.insert(
      T.notificationPrefs,
      NotificationPrefs(
        userId: 1,
        workoutReminders: prefs.workoutReminders,
        streakWarnings: prefs.streakWarnings,
        weeklyReports: prefs.weeklyReports,
      ).toRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await OutboxEnqueuer.upsertSingletonByUserId(T.notificationPrefs);
  }
}
