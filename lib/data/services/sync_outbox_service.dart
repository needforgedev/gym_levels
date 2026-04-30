import 'dart:math';

import '../app_db.dart';
import '../models/sync_outbox.dart';
import '../schema.dart';
import '_now.dart';

/// CRUD over the `sync_outbox` local table.
///
/// Domain services and the [SyncEngine] never touch the table directly
/// — they go through this service. Keeps every outbox interaction
/// behind a single seam so retry/backoff logic lives in one place.
class SyncOutboxService {
  SyncOutboxService._();

  /// Enqueue a pending push. Called from domain services after every
  /// local write to a cloud-mirrored table.
  ///
  /// `payloadJson` is the snapshot of the row at enqueue time —
  /// captures the value to push *now*, even if the local row is
  /// edited again before this outbox entry drains.
  static Future<int> enqueue({
    required String tableName,
    required int localRowId,
    required String cloudId,
    required SyncOpType opType,
    String? payloadJson,
  }) async {
    final db = await AppDb.instance;
    final row = SyncOutboxRow(
      tableName: tableName,
      localRowId: localRowId,
      cloudId: cloudId,
      opType: opType,
      payloadJson: payloadJson,
      createdAt: nowSeconds(),
    );
    final id = await db.insert(T.syncOutbox, row.toRow());
    return id;
  }

  /// Returns the next batch of rows eligible to push. Filters:
  ///   • not yet pushed (`pushed_at IS NULL`)
  ///   • not dead-lettered (`attempt_count < kMaxAttempts`)
  ///   • backoff window elapsed (last_attempt_at + backoff <= now)
  ///
  /// Ordered by `created_at ASC` (FIFO) so older pushes drain first.
  static Future<List<SyncOutboxRow>> nextBatch({int limit = 50}) async {
    final db = await AppDb.instance;
    final now = nowSeconds();

    // Eligible-to-retry rows: never attempted yet, OR backoff elapsed.
    // Backoff for attempt N is `_backoffSeconds(N)`. Compute the
    // earliest-eligible timestamp inline via CASE.
    final rows = await db.rawQuery(
      '''
      SELECT * FROM ${T.syncOutbox}
      WHERE ${CSyncOutbox.pushedAt} IS NULL
        AND ${CSyncOutbox.attemptCount} < ?
        AND (
          ${CSyncOutbox.lastAttemptAt} IS NULL
          OR ${CSyncOutbox.lastAttemptAt} + ? <= ?
        )
      ORDER BY ${CSyncOutbox.createdAt} ASC, ${CSyncOutbox.id} ASC
      LIMIT ?
      ''',
      [
        kMaxAttempts,
        // Conservative: use the smallest backoff window for the SQL
        // filter, then re-check per-row in Dart with the actual
        // attempt-aware backoff. Keeps the query simple at the cost of
        // a tiny bit of post-fetch filtering.
        _backoffSeconds(0),
        now,
        limit,
      ],
    );

    final batch = rows.map(SyncOutboxRow.fromRow).toList();
    // Tighten the filter in Dart: skip rows whose attempt-aware
    // backoff hasn't elapsed yet.
    batch.removeWhere((r) {
      if (r.lastAttemptAt == null) return false;
      final ready = r.lastAttemptAt! + _backoffSeconds(r.attemptCount);
      return now < ready;
    });
    return batch;
  }

  /// Mark a row as successfully pushed.
  static Future<void> markPushed(int id) async {
    final db = await AppDb.instance;
    await db.update(
      T.syncOutbox,
      {
        CSyncOutbox.pushedAt: nowSeconds(),
        CSyncOutbox.lastError: null,
      },
      where: '${CSyncOutbox.id} = ?',
      whereArgs: [id],
    );
  }

  /// Record a failed push attempt. Bumps `attempt_count`, writes the
  /// error, stamps `last_attempt_at`. Rows that hit [kMaxAttempts] are
  /// dead-lettered (no further drain attempts).
  static Future<void> markFailed(int id, String error) async {
    final db = await AppDb.instance;
    await db.rawUpdate(
      '''
      UPDATE ${T.syncOutbox}
      SET ${CSyncOutbox.attemptCount} = ${CSyncOutbox.attemptCount} + 1,
          ${CSyncOutbox.lastAttemptAt} = ?,
          ${CSyncOutbox.lastError} = ?
      WHERE ${CSyncOutbox.id} = ?
      ''',
      [nowSeconds(), error, id],
    );
  }

  /// Prune successfully-pushed rows older than [olderThanSeconds].
  /// Default: 1 hour. Keeps recent pushed rows in the table briefly
  /// for telemetry / debugging without unbounded growth.
  static Future<int> prunePushed({int olderThanSeconds = 3600}) async {
    final db = await AppDb.instance;
    final cutoff = nowSeconds() - olderThanSeconds;
    return db.delete(
      T.syncOutbox,
      where:
          '${CSyncOutbox.pushedAt} IS NOT NULL AND ${CSyncOutbox.pushedAt} < ?',
      whereArgs: [cutoff],
    );
  }

  /// Total pending rows (not pushed yet, regardless of attempt count).
  static Future<int> pendingCount() async {
    final db = await AppDb.instance;
    final r = await db.rawQuery(
      'SELECT COUNT(*) AS n FROM ${T.syncOutbox} '
      'WHERE ${CSyncOutbox.pushedAt} IS NULL',
    );
    return (r.first['n'] as int?) ?? 0;
  }

  /// Dead-lettered rows — pending forever because they hit
  /// [kMaxAttempts] without success. Surfaced in a debug screen later.
  static Future<int> deadLetteredCount() async {
    final db = await AppDb.instance;
    final r = await db.rawQuery(
      'SELECT COUNT(*) AS n FROM ${T.syncOutbox} '
      'WHERE ${CSyncOutbox.pushedAt} IS NULL '
      'AND ${CSyncOutbox.attemptCount} >= ?',
      [kMaxAttempts],
    );
    return (r.first['n'] as int?) ?? 0;
  }

  /// Drop everything in the outbox. Called on sign-out so a different
  /// user signing in doesn't accidentally push the previous user's
  /// pending operations under their own auth.
  static Future<void> clear() async {
    final db = await AppDb.instance;
    await db.delete(T.syncOutbox);
  }

  // ─── Retry policy ────────────────────────────────────────────────

  /// Maximum push attempts per row. Rows that exceed this are
  /// dead-lettered (never re-attempted automatically).
  static const int kMaxAttempts = 5;

  /// Exponential backoff: 60s, 2m, 4m, 8m, 16m. Caps at 16m so a
  /// long-failing row still gets retried periodically (e.g. server
  /// outage that lasts hours).
  static int _backoffSeconds(int attempt) {
    final base = 60 * pow(2, attempt.clamp(0, 4)).toInt();
    return base;
  }
}
