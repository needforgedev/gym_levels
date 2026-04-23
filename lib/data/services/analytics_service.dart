import 'dart:convert';

import '../app_db.dart';
import '../models/analytics_event.dart';
import '../schema.dart';
import '_now.dart';

/// PRD §15 — local-first outbox. Writes are synchronous on the UI event.
/// Upload is fire-and-forget in Phase 2.7.
class AnalyticsService {
  AnalyticsService._();

  static Future<int> log(
    String name, [
    Map<String, Object?> payload = const {},
  ]) async {
    final db = await AppDb.instance;
    return db.insert(
      T.analyticsEvents,
      AnalyticsEvent(
        name: name,
        payloadJson: jsonEncode(payload),
        createdAt: nowSeconds(),
      ).toRow(),
    );
  }

  static Future<List<AnalyticsEvent>> pending({int limit = 100}) async {
    final db = await AppDb.instance;
    final rows = await db.query(
      T.analyticsEvents,
      where: '${CAnalyticsEvent.uploadedAt} IS NULL',
      orderBy: '${CAnalyticsEvent.createdAt} ASC',
      limit: limit,
    );
    return rows.map(AnalyticsEvent.fromRow).toList();
  }

  static Future<void> markUploaded(List<int> ids) async {
    if (ids.isEmpty) return;
    final db = await AppDb.instance;
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.rawUpdate(
      'UPDATE ${T.analyticsEvents} SET ${CAnalyticsEvent.uploadedAt} = ? '
      'WHERE ${CAnalyticsEvent.id} IN ($placeholders)',
      [nowSeconds(), ...ids],
    );
  }

  /// PRD §15 — purge events older than the TTL if still unuploaded.
  static Future<int> purgeStale({int olderThanSeconds = 30 * 24 * 3600}) async {
    final db = await AppDb.instance;
    final cutoff = nowSeconds() - olderThanSeconds;
    return db.delete(
      T.analyticsEvents,
      where: '${CAnalyticsEvent.createdAt} < ?',
      whereArgs: [cutoff],
    );
  }
}
