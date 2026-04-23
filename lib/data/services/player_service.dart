import 'package:sqflite/sqflite.dart';

import '../app_db.dart';
import '../models/player.dart';
import '../schema.dart';
import '_now.dart';

/// Single-row `player` table (user_id = 1 in v1.0). PRD §11.7.
class PlayerService {
  PlayerService._();

  static Future<Player?> getPlayer() async {
    final db = await AppDb.instance;
    final rows = await db.query(
      T.player,
      where: '${CPlayer.id} = ?',
      whereArgs: [1],
      limit: 1,
    );
    return rows.isEmpty ? null : Player.fromRow(rows.first);
  }

  /// Create the singleton player row with sensible defaults if missing.
  /// Returns the resulting row (existing or new).
  static Future<Player> ensurePlayer({String displayName = 'Player'}) async {
    final existing = await getPlayer();
    if (existing != null) return existing;
    final db = await AppDb.instance;
    final now = nowSeconds();
    final row = Player(
      displayName: displayName,
      createdAt: now,
      updatedAt: now,
    );
    await db.insert(T.player, row.toRow(),
        conflictAlgorithm: ConflictAlgorithm.abort);
    return row;
  }

  static Future<void> setDisplayName(String name) async {
    final db = await AppDb.instance;
    await ensurePlayer(displayName: name);
    await db.update(
      T.player,
      {
        CPlayer.displayName: name,
        CPlayer.updatedAt: nowSeconds(),
      },
      where: '${CPlayer.id} = ?',
      whereArgs: [1],
    );
  }

  /// Overwrites the whole player row.
  static Future<void> upsert(Player player) async {
    final db = await AppDb.instance;
    await db.insert(
      T.player,
      player.copyWith(updatedAt: nowSeconds()).toRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Patches a subset of player columns. Creates the row if missing.
  /// Used by onboarding screens to persist one field at a time.
  static Future<void> patch({
    String? displayName,
    int? age,
    double? heightCm,
    double? weightKg,
    String? bodyFatEstimate,
    String? unitsPref,
  }) async {
    final existing = await ensurePlayer(displayName: displayName ?? 'Player');
    await upsert(existing.copyWith(
      displayName: displayName,
      age: age,
      heightCm: heightCm,
      weightKg: weightKg,
      bodyFatEstimate: bodyFatEstimate,
      unitsPref: unitsPref,
    ));
  }

  static Future<void> completeOnboarding() async {
    final db = await AppDb.instance;
    final now = nowSeconds();
    await db.update(
      T.player,
      {CPlayer.onboardedAt: now, CPlayer.updatedAt: now},
      where: '${CPlayer.id} = ?',
      whereArgs: [1],
    );
  }

  /// Wipes every row via cascade. PRD §19 — "Delete my data".
  static Future<void> deleteAll() async {
    final db = await AppDb.instance;
    await db.delete(T.player, where: '${CPlayer.id} = ?', whereArgs: [1]);
  }
}
