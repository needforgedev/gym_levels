import 'dart:async';

import '../models/sync_outbox.dart';
import '../services/auth_service.dart';
import '../services/leaderboard_stats_service.dart';
import '../services/sync_outbox_service.dart';
import '../services/sync_state_service.dart';
import 'incremental_pull.dart';
import 'push_handler.dart';

/// Outcome of one drain pass — surfaced for telemetry / debug screens.
class DrainReport {
  const DrainReport({
    required this.attempted,
    required this.succeeded,
    required this.failed,
    required this.skippedNoAuth,
    required this.skippedAlreadyRunning,
  });

  final int attempted;
  final int succeeded;
  final int failed;

  /// Drain bailed because the user isn't signed in (or Supabase isn't
  /// configured). Local writes still queue normally; we'll catch up on
  /// the next foreground after sign-in.
  final bool skippedNoAuth;

  /// Another drain was already in flight — the call was a no-op.
  final bool skippedAlreadyRunning;

  bool get didRun => !skippedNoAuth && !skippedAlreadyRunning;

  static const empty = DrainReport(
    attempted: 0,
    succeeded: 0,
    failed: 0,
    skippedNoAuth: false,
    skippedAlreadyRunning: false,
  );
}

/// Drains the local outbox into Supabase.
///
/// One drain pass:
///   1. Bail if not authenticated (caller is offline-only).
///   2. Acquire the in-process mutex so we never run two drains at once.
///   3. Pull a batch from [SyncOutboxService.nextBatch] (FIFO, backoff-
///      filtered, dead-letter excluded).
///   4. For each row, look up the per-table push handler. Run it.
///      Success → `markPushed`. Failure → `markFailed` (engine
///      increments attempt_count + stamps last_error; backoff window
///      is computed by the OutboxService for the *next* drain).
///   5. Stamp `sync_state.last_outbox_drain_at`, prune old pushed rows.
///
/// The engine is NOT a [ChangeNotifier]; UI listens to the outbox via
/// `SyncOutboxService.pendingCount()` polled from a debug screen
/// (S7 ships a real status pill).
class SyncEngine {
  SyncEngine({
    PushHandlerRegistry? registry,
    IncrementalPull? incrementalPull,
  })  : _registry = registry ?? PushHandlerRegistry.skeleton(),
        _incrementalPull = incrementalPull ?? IncrementalPull();

  final PushHandlerRegistry _registry;
  final IncrementalPull _incrementalPull;

  /// Mutex — `true` while a drain is in flight. Prevents the foreground
  /// hook + the periodic timer from racing each other.
  bool _draining = false;

  /// Allow tests / debug screens to swap the handler registry.
  PushHandlerRegistry get registry => _registry;

  /// Run one drain pass. Returns immediately (with `skippedAlreadyRunning`
  /// set) if another drain is in flight. Safe to call from anywhere —
  /// foreground hook, periodic timer, or a manual "Sync now" button.
  Future<DrainReport> drainOnce({int batchLimit = 50}) async {
    if (!AuthService.isAuthenticated) {
      return const DrainReport(
        attempted: 0,
        succeeded: 0,
        failed: 0,
        skippedNoAuth: true,
        skippedAlreadyRunning: false,
      );
    }

    if (_draining) {
      return const DrainReport(
        attempted: 0,
        succeeded: 0,
        failed: 0,
        skippedNoAuth: false,
        skippedAlreadyRunning: true,
      );
    }
    _draining = true;

    int attempted = 0;
    int succeeded = 0;
    int failed = 0;
    try {
      final batch = await SyncOutboxService.nextBatch(limit: batchLimit);
      for (final row in batch) {
        attempted++;
        final outcome = await _pushOne(row);
        if (outcome) {
          succeeded++;
        } else {
          failed++;
        }
      }
      // Always stamp the drain attempt — telemetry needs to know we
      // ran, even if every row failed.
      await SyncStateService.recordDrainAttempt();
      // Best-effort prune. Don't block the engine on prune errors.
      try {
        await SyncOutboxService.prunePushed();
      } catch (_) {/* swallow — prune is housekeeping */}
      // Pull deltas from cloud after pushing local writes — keeps
      // two devices on the same account converging within ~30s.
      // Errors are non-fatal; the cursor stays where it was, so the
      // next tick retries the missed range.
      try {
        await _incrementalPull.runOnce();
      } catch (_) {/* swallow — pull telemetry could land later */}
      // Defensive: refresh public_profiles totals in case a direct
      // call from WorkoutService.finish / StreakService.upsert was
      // missed (e.g. cold-boot before auth resolved). Cheap.
      try {
        await LeaderboardStatsService.refresh();
      } catch (_) {/* swallow */}
    } finally {
      _draining = false;
    }

    return DrainReport(
      attempted: attempted,
      succeeded: succeeded,
      failed: failed,
      skippedNoAuth: false,
      skippedAlreadyRunning: false,
    );
  }

  /// Push exactly one row. Returns `true` on success, `false` on any
  /// failure (the row's `attempt_count` is bumped by [SyncOutboxService]
  /// so subsequent drains shelve it with exponential backoff).
  Future<bool> _pushOne(SyncOutboxRow row) async {
    final id = row.id;
    if (id == null) {
      // Defensive — can't happen in practice (outbox PK is auto-inc).
      return false;
    }

    final handler = _registry.handlerFor(row.tableName);
    if (handler == null) {
      await SyncOutboxService.markFailed(
        id,
        'No push handler registered for table "${row.tableName}".',
      );
      return false;
    }

    try {
      await handler.push(row);
      await SyncOutboxService.markPushed(id);
      return true;
    } catch (e) {
      await SyncOutboxService.markFailed(id, e.toString());
      return false;
    }
  }
}
