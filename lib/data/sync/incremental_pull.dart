import '../models/sync_state.dart';
import '../services/auth_service.dart';
import '../services/sync_state_service.dart';
import 'cloud_pull_handlers.dart';
import 'pull_handler.dart';

/// One-line summary of an incremental-pull pass — surfaced for
/// telemetry / debug.
class IncrementalPullReport {
  const IncrementalPullReport({
    required this.applied,
    required this.skippedNoAuth,
    required this.skippedNotHydrated,
    required this.skippedAlreadyRunning,
    this.error,
  });

  /// Total rows applied across all tables.
  final int applied;

  /// Pull bailed because the user isn't signed in.
  final bool skippedNoAuth;

  /// Pull bailed because initial-sync hasn't run yet — we have no
  /// `since` cursor, and a cold full-pull would duplicate work that
  /// belongs to [InitialSync].
  final bool skippedNotHydrated;

  /// Another pull pass was already in flight.
  final bool skippedAlreadyRunning;

  /// Non-null on partial failure. The cursor is NOT advanced when an
  /// error is returned, so the next pass re-fetches the missed rows.
  final Object? error;

  bool get didRun =>
      !skippedNoAuth && !skippedNotHydrated && !skippedAlreadyRunning;

  static const empty = IncrementalPullReport(
    applied: 0,
    skippedNoAuth: false,
    skippedNotHydrated: false,
    skippedAlreadyRunning: false,
  );
}

/// Pulls cloud-side updates into local sqflite for tables that have
/// already been initial-sync'd. Driven by [SyncEngine] alongside the
/// outbox drain — runs on every drain tick (foreground + 30s
/// periodic) so two devices sharing an account converge within ~30s.
///
/// Cursor: [SyncStateRow.lastFullSyncAt]. Re-purposed from "last full
/// sync timestamp" to "high-water mark of cloud `updated_at` we've
/// hydrated into local." Stays NULL until [InitialSync] completes,
/// after which every successful pass advances it forward.
///
/// Each pass:
///   1. Snapshot `cutoff = now()` *before* fetching, so rows that
///      land mid-pass aren't lost — the cursor moves to `cutoff`,
///      not to the latest fetched row's `updated_at`.
///   2. For each table in [kPullPriorityOrder], call
///      [PullHandler.pullSince] with the prior cursor.
///   3. On full success, persist `cutoff` as the new cursor.
class IncrementalPull {
  IncrementalPull({PullHandlerRegistry? registry})
      : _registry = registry ?? PullHandlerRegistryProduction.production();

  final PullHandlerRegistry _registry;
  bool _running = false;

  /// Run one incremental pull pass. Safe to call concurrently — the
  /// in-process mutex collapses overlapping calls.
  Future<IncrementalPullReport> runOnce() async {
    if (!AuthService.isAuthenticated) {
      return const IncrementalPullReport(
        applied: 0,
        skippedNoAuth: true,
        skippedNotHydrated: false,
        skippedAlreadyRunning: false,
      );
    }
    if (_running) {
      return const IncrementalPullReport(
        applied: 0,
        skippedNoAuth: false,
        skippedNotHydrated: false,
        skippedAlreadyRunning: true,
      );
    }
    _running = true;

    try {
      final state = await SyncStateService.get();
      final sinceUnix = state.lastFullSyncAt;
      if (sinceUnix == null) {
        // Initial-sync hasn't run — nothing to incrementally pull.
        return const IncrementalPullReport(
          applied: 0,
          skippedNoAuth: false,
          skippedNotHydrated: true,
          skippedAlreadyRunning: false,
        );
      }
      final since = DateTime.fromMillisecondsSinceEpoch(
        sinceUnix * 1000,
        isUtc: true,
      );

      // Snapshot cutoff *before* fetching so rows landing during the
      // pass aren't missed by the next cursor advance.
      final cutoff = DateTime.now().toUtc();
      final cutoffUnix = cutoff.millisecondsSinceEpoch ~/ 1000;

      int applied = 0;
      for (final tableName in kPullPriorityOrder) {
        final handler = _registry.handlerFor(tableName);
        if (handler == null) continue;
        try {
          applied += await handler.pullSince(since);
        } catch (e) {
          // Bail on first failure — keep the cursor where it was so
          // the next pass retries the missed range.
          return IncrementalPullReport(
            applied: applied,
            skippedNoAuth: false,
            skippedNotHydrated: false,
            skippedAlreadyRunning: false,
            error: e,
          );
        }
      }

      // Full pass succeeded — advance the cursor.
      await SyncStateService.save(
        state.copyWith(lastFullSyncAt: cutoffUnix),
      );

      return IncrementalPullReport(
        applied: applied,
        skippedNoAuth: false,
        skippedNotHydrated: false,
        skippedAlreadyRunning: false,
      );
    } finally {
      _running = false;
    }
  }
}
