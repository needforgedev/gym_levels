import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../app_db.dart';
import '../models/sync_outbox.dart';
import '../schema.dart';
import '../services/sync_outbox_service.dart';

/// One-stop helper that domain services call after every local write
/// to a cloud-mirrored table. Handles three concerns at once:
///
///   1. Ensures the row has a stable `cloud_id` UUIDv4 (generated on
///      first push and persisted back to the local row, so subsequent
///      pushes for the same row collapse onto the same cloud PK).
///   2. Snapshots the current row state as JSON. This is what the
///      [PushHandler] decodes and translates server-side.
///   3. Enqueues a [SyncOutboxRow] for the [SyncEngine] to drain.
///
/// Every helper is fire-and-forget from the caller's POV — failures to
/// enqueue do NOT propagate as exceptions, since a failed enqueue
/// shouldn't crash a workout-finish flow. The engine's own retry
/// machinery covers transient push failures; missed enqueues are
/// logged-and-swallowed.
class OutboxEnqueuer {
  OutboxEnqueuer._();

  static const _uuid = Uuid();

  /// Enqueue an upsert/delete for the row matching [pk] in [table].
  ///
  /// [pk] is `{column: value}` pairs that uniquely identify the row —
  /// `{id: 5}` for auto-increment tables, `{user_id: 1}` for
  /// singletons, `{user_id: 1, muscle: 'biceps'}` for composite keys.
  ///
  /// [extraPayload] gets merged into the snapshot before enqueue —
  /// useful for pre-resolving cross-table references (e.g. sets need
  /// the parent workout's `cloud_id` so the cloud INSERT can use it
  /// for the FK).
  ///
  /// [localRowIdOverride] forces the audit `local_row_id` value. When
  /// omitted, the helper picks the first of `id`, `pk['id']`,
  /// `pk['user_id']`, or `1`.
  static Future<void> enqueueByPk({
    required String table,
    required Map<String, Object?> pk,
    required SyncOpType opType,
    int? localRowIdOverride,
    Map<String, Object?>? extraPayload,
  }) async {
    try {
      final db = await AppDb.instance;
      final whereParts = pk.keys.map((k) => '$k = ?').join(' AND ');
      final whereArgs = pk.values.toList();

      final rows = await db.query(
        table,
        where: whereParts,
        whereArgs: whereArgs,
        limit: 1,
      );
      if (rows.isEmpty) return; // Row vanished — nothing to push.

      final row = Map<String, Object?>.from(rows.first);

      var cloudId = row[CSync.cloudId] as String?;
      if (cloudId == null || cloudId.isEmpty) {
        cloudId = _uuid.v4();
        await db.update(
          table,
          {CSync.cloudId: cloudId},
          where: whereParts,
          whereArgs: whereArgs,
        );
        row[CSync.cloudId] = cloudId;
      }

      // Strip sync-meta from the payload — handler doesn't use them.
      row
        ..remove(CSync.cloudId)
        ..remove(CSync.cloudUpdatedAt)
        ..remove(CSync.cloudDeletedAt);

      if (extraPayload != null) row.addAll(extraPayload);

      final localRowId = localRowIdOverride ??
          (row['id'] as int?) ??
          (pk['id'] as int?) ??
          (pk['user_id'] as int?) ??
          1;

      await SyncOutboxService.enqueue(
        tableName: table,
        localRowId: localRowId,
        cloudId: cloudId,
        opType: opType,
        payloadJson: jsonEncode(row),
      );
    } catch (_) {
      // Enqueue failures are non-fatal — local writes have already
      // succeeded; the row simply won't sync until the next mutation.
      // (Could surface to a debug screen later, S7.)
    }
  }

  // ─── Per-table convenience wrappers ──────────────────────────

  /// Singletons keyed on `user_id = 1` — goals, experience, schedule,
  /// notification_prefs, player_class, streak.
  static Future<void> upsertSingletonByUserId(String table) =>
      enqueueByPk(
        table: table,
        pk: {'user_id': 1},
        opType: SyncOpType.upsert,
      );

  /// Player uses `id` (not `user_id`) as its singleton PK.
  static Future<void> upsertPlayer() =>
      enqueueByPk(
        table: T.player,
        pk: {CPlayer.id: 1},
        opType: SyncOpType.upsert,
      );

  /// Quest / set / workout / weight_log / streak_freeze_event — all
  /// use auto-increment `id` PKs.
  static Future<void> upsertAutoinc({
    required String table,
    required int id,
    Map<String, Object?>? extraPayload,
  }) =>
      enqueueByPk(
        table: table,
        pk: {'id': id},
        opType: SyncOpType.upsert,
        extraPayload: extraPayload,
      );

  /// Muscle-ranks composite key.
  static Future<void> upsertMuscleRank(String muscle) => enqueueByPk(
        table: T.muscleRanks,
        pk: {CMuscleRank.userId: 1, CMuscleRank.muscle: muscle},
        opType: SyncOpType.upsert,
      );
}
