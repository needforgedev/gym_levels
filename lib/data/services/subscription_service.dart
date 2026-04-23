import 'package:sqflite/sqflite.dart';

import '../app_db.dart';
import '../models/subscription.dart';
import '../schema.dart';
import '_now.dart';

class SubscriptionService {
  SubscriptionService._();

  static Future<Subscription?> get() async {
    final db = await AppDb.instance;
    final rows = await db.query(T.subscriptions,
        where: '${CSubscription.userId} = ?', whereArgs: [1], limit: 1);
    return rows.isEmpty ? null : Subscription.fromRow(rows.first);
  }

  static Future<void> upsert(Subscription sub) async {
    final db = await AppDb.instance;
    await db.insert(
      T.subscriptions,
      Subscription(
        tier: sub.tier,
        status: sub.status,
        purchasedAt: sub.purchasedAt,
        renewsAt: sub.renewsAt,
        receiptData: sub.receiptData,
        lastVerifiedAt: sub.lastVerifiedAt,
        updatedAt: nowSeconds(),
      ).toRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// PRD §13 — "honored offline until renews_at". Callers should treat this
  /// as authoritative; the opportunistic re-validation (Phase 2.6) updates
  /// the row in the background.
  static Future<bool> isProCached() async {
    final sub = await get();
    return sub?.isPro ?? false;
  }
}
