import 'dart:async';

import '../services/auth_service.dart';
import '../services/sync_state_service.dart';
import 'cloud_pull_handlers.dart';
import 'pull_handler.dart';

/// Snapshot of progress through one [InitialSync.run] invocation.
///
/// `tableIndex` / `tableCount` count tiers in [kPullPriorityOrder] —
/// not rows. The UI renders both: the per-table progress (rows pulled
/// so far) and the overall progress (how many tables completed).
class InitialSyncProgress {
  const InitialSyncProgress({
    required this.tableName,
    required this.tableIndex,
    required this.tableCount,
    required this.rowsThisTable,
    this.complete = false,
    this.error,
  });

  /// Cloud-mirrored table currently being hydrated (`workouts`, etc.).
  final String tableName;

  /// 0-based position of [tableName] in [kPullPriorityOrder].
  final int tableIndex;
  final int tableCount;

  /// Cumulative row count fetched for the current table.
  final int rowsThisTable;

  /// `true` once every table has been pulled.
  final bool complete;

  /// Non-null if the orchestrator stopped early. Caller decides
  /// whether to retry or surface the error.
  final Object? error;

  /// Coarse 0..1 fraction across the whole sync, treating each table
  /// as equal weight. Good enough for a progress bar; the UI can
  /// render the per-table count separately for transparency.
  double get fractionComplete {
    if (complete) return 1;
    if (tableCount == 0) return 0;
    return tableIndex / tableCount;
  }

  /// Human label for the welcome-back screen.
  String get tableDisplayName => switch (tableName) {
        'player' => 'Profile',
        'goals' => 'Goals',
        'experience' => 'Training history',
        'schedule' => 'Schedule',
        'notification_prefs' => 'Notification preferences',
        'muscle_ranks' => 'Muscle ranks',
        'streaks' => 'Streak',
        'player_class' => 'Player class',
        'workouts' => 'Workout history',
        'sets' => 'Sets',
        'quests' => 'Quests',
        'streak_freeze_events' => 'Streak freezes',
        'weight_logs' => 'Weight log',
        _ => tableName,
      };
}

/// Orchestrates initial-sync pulls in priority order, persisting
/// progress to `sync_state` so a kill mid-sync resumes cleanly.
///
/// Lifecycle:
///   1. Caller checks [needed] — `false` skips straight to Home.
///   2. Caller invokes [run] with an `onProgress` callback.
///   3. Orchestrator reads `sync_state` to find the resume cursor
///      (`initial_sync_table` + `initial_sync_offset`).
///   4. For each table from cursor onward, fetches pages of
///      `pullPageSize` rows until the handler returns `< pageSize`.
///   5. Persists the per-page offset between fetches.
///   6. On final table done, calls
///      [SyncStateService.markFullSyncComplete].
class InitialSync {
  InitialSync({PullHandlerRegistry? registry})
      : _registry = registry ?? PullHandlerRegistryProduction.production();

  final PullHandlerRegistry _registry;

  /// `true` iff the user is authenticated and a full hydration has
  /// not yet completed on this device. Caller (typically the sign-in
  /// flow) uses this to decide whether to route to the welcome-back
  /// screen.
  static Future<bool> needed() async {
    if (!AuthService.isAuthenticated) return false;
    final state = await SyncStateService.get();
    return state.lastFullSyncAt == null;
  }

  /// Run the orchestrator. Safe to call repeatedly — the resume
  /// cursor in `sync_state` makes each call pick up where the prior
  /// one left off.
  Future<InitialSyncProgress> run({
    void Function(InitialSyncProgress)? onProgress,
  }) async {
    if (!AuthService.isAuthenticated) {
      return InitialSyncProgress(
        tableName: '',
        tableIndex: 0,
        tableCount: kPullPriorityOrder.length,
        rowsThisTable: 0,
        error: StateError('Not authenticated.'),
      );
    }

    const tables = kPullPriorityOrder;
    final state = await SyncStateService.get();

    // Determine where to resume.
    final resumeFrom = state.initialSyncTable;
    int startIndex = 0;
    int startOffset = 0;
    if (resumeFrom != null) {
      final idx = tables.indexOf(resumeFrom);
      if (idx >= 0) {
        startIndex = idx;
        startOffset = state.initialSyncOffset;
      }
    }

    InitialSyncProgress? lastEmitted;

    for (int i = startIndex; i < tables.length; i++) {
      final tableName = tables[i];
      final handler = _registry.handlerFor(tableName);
      if (handler == null) continue; // No registered handler — skip.

      int offset = (i == startIndex) ? startOffset : 0;
      int rowsThisTable = offset;
      while (true) {
        try {
          final fetched = await handler.pullPage(
            offset: offset,
            pageSize: pullPageSize,
          );
          rowsThisTable += fetched;
          offset += fetched;

          await SyncStateService.setInitialSyncProgress(
            table: tableName,
            offset: offset,
          );

          final p = InitialSyncProgress(
            tableName: tableName,
            tableIndex: i,
            tableCount: tables.length,
            rowsThisTable: rowsThisTable,
          );
          lastEmitted = p;
          onProgress?.call(p);

          if (fetched < pullPageSize) break;
        } catch (e) {
          final p = InitialSyncProgress(
            tableName: tableName,
            tableIndex: i,
            tableCount: tables.length,
            rowsThisTable: rowsThisTable,
            error: e,
          );
          onProgress?.call(p);
          return p;
        }
      }
    }

    await SyncStateService.markFullSyncComplete();
    final done = InitialSyncProgress(
      tableName: '',
      tableIndex: tables.length,
      tableCount: tables.length,
      rowsThisTable: lastEmitted?.rowsThisTable ?? 0,
      complete: true,
    );
    onProgress?.call(done);
    return done;
  }
}
