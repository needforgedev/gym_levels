import '../app_db.dart';
import '../models/sync_state.dart';
import '../schema.dart';
import '_now.dart';

/// CRUD over the singleton `sync_state` row (`id = 1`).
///
/// The row is seeded by [AppDb] (initial install) and by the v1→v2
/// migration (existing installs), so reads can assume it exists. The
/// service still falls back to a default in-memory row if a malformed
/// DB ever returns nothing, since callers rely on `get()` always
/// returning non-null.
class SyncStateService {
  SyncStateService._();

  /// Reads the singleton. Falls back to an empty default if the row
  /// somehow isn't there (defensive — should never happen in practice).
  static Future<SyncStateRow> get() async {
    final db = await AppDb.instance;
    final rows = await db.query(
      T.syncState,
      where: '${CSyncState.id} = ?',
      whereArgs: [1],
      limit: 1,
    );
    if (rows.isEmpty) return const SyncStateRow();
    return SyncStateRow.fromRow(rows.first);
  }

  /// Overwrite the singleton. Uses raw UPDATE rather than upsert
  /// because the seed row is guaranteed to exist.
  static Future<void> save(SyncStateRow row) async {
    final db = await AppDb.instance;
    final values = row.toRow()..remove(CSyncState.id);
    await db.update(
      T.syncState,
      values,
      where: '${CSyncState.id} = ?',
      whereArgs: [1],
    );
  }

  /// Stamp `last_outbox_drain_at = now`. Called by [SyncEngine] at the
  /// end of every drain pass (success OR failure) so the foreground
  /// hook can throttle re-drains.
  static Future<void> recordDrainAttempt() async {
    final db = await AppDb.instance;
    await db.update(
      T.syncState,
      {CSyncState.lastOutboxDrainAt: nowSeconds()},
      where: '${CSyncState.id} = ?',
      whereArgs: [1],
    );
  }

  /// Persist the in-progress initial-sync cursor. Called by the pull
  /// loop after each page so a kill mid-sync resumes where it left off.
  static Future<void> setInitialSyncProgress({
    required String table,
    required int offset,
  }) async {
    final db = await AppDb.instance;
    await db.update(
      T.syncState,
      {
        CSyncState.initialSyncTable: table,
        CSyncState.initialSyncOffset: offset,
      },
      where: '${CSyncState.id} = ?',
      whereArgs: [1],
    );
  }

  /// Mark the full hydration done: clear the in-progress cursor and
  /// stamp `last_full_sync_at = now`.
  static Future<void> markFullSyncComplete() async {
    final db = await AppDb.instance;
    await db.update(
      T.syncState,
      {
        CSyncState.lastFullSyncAt: nowSeconds(),
        CSyncState.initialSyncTable: null,
        CSyncState.initialSyncOffset: 0,
      },
      where: '${CSyncState.id} = ?',
      whereArgs: [1],
    );
  }

  /// Reset to factory defaults. Called on sign-out so a different user
  /// signing in starts initial-sync from scratch (no leaked cursor).
  static Future<void> reset() async {
    final db = await AppDb.instance;
    await db.update(
      T.syncState,
      {
        CSyncState.lastFullSyncAt: null,
        CSyncState.initialSyncTable: null,
        CSyncState.initialSyncOffset: 0,
        CSyncState.lastOutboxDrainAt: null,
      },
      where: '${CSyncState.id} = ?',
      whereArgs: [1],
    );
  }
}
