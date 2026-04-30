import 'package:sqflite/sqflite.dart';

import '../app_db.dart';
import '../models/player_class_row.dart';
import '../schema.dart';
import '../sync/outbox_enqueuer.dart';
import '_now.dart';

/// PRD §9A.7 — player class derivation + reassignment.
class PlayerClassService {
  PlayerClassService._();

  static Future<PlayerClassRow?> get() async {
    final db = await AppDb.instance;
    final rows = await db.query(T.playerClass,
        where: '${CPlayerClass.userId} = ?', whereArgs: [1], limit: 1);
    return rows.isEmpty ? null : PlayerClassRow.fromRow(rows.first);
  }

  /// Appends a free-form audit string to `evolution_history`. Used by
  /// boss-completion to record buff awards (`'buff:<key>@<epoch>'`)
  /// without taking a schema bump for an `active_buffs` table — the
  /// real XP-modifier integration lands later.
  static Future<void> appendEvolutionEntry(String entry) async {
    final existing = await get();
    if (existing == null) return;
    final db = await AppDb.instance;
    final history = [...existing.evolutionHistory, entry];
    await db.insert(
      T.playerClass,
      PlayerClassRow(
        userId: 1,
        classKey: existing.classKey,
        assignedAt: existing.assignedAt,
        lastChangedAt: nowSeconds(),
        evolutionHistory: history,
      ).toRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await OutboxEnqueuer.upsertSingletonByUserId(T.playerClass);
  }

  /// Assign or reassign the player class. Appends the previous class to
  /// `evolution_history` for audit.
  static Future<void> assign(String classKey) async {
    final db = await AppDb.instance;
    final now = nowSeconds();
    final existing = await get();

    final history = [...?existing?.evolutionHistory];
    if (existing != null && existing.classKey != classKey) {
      history.add('${existing.classKey}@${existing.lastChangedAt}');
    }

    await db.insert(
      T.playerClass,
      PlayerClassRow(
        userId: 1,
        classKey: classKey,
        assignedAt: existing?.assignedAt ?? now,
        lastChangedAt: now,
        evolutionHistory: history,
      ).toRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await OutboxEnqueuer.upsertSingletonByUserId(T.playerClass);
  }
}
