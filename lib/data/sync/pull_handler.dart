/// Pull-side counterpart of [PushHandler]. Each handler fetches a
/// page of cloud rows for its table and writes them into the local
/// sqflite DB.
///
/// S3b (initial-sync hydration) is the only caller — once the user is
/// signed in on a fresh install, the [SyncEngine] iterates a priority-
/// ordered list of tables, calling each handler's [pullPage] until it
/// returns fewer rows than the requested page size.
///
/// Handlers must:
///   • Translate cloud schema → local schema (TIMESTAMPTZ → unix-secs,
///     BOOLEAN → 0/1, TEXT[] → JSON string, etc.).
///   • Map cloud `user_id` UUIDs → local `user_id = 1` (single-user
///     model in v1.0).
///   • Be idempotent — re-running the same page must not duplicate
///     rows. Lookup by `cloud_id` + UPDATE-or-INSERT is the standard
///     pattern.
///   • Return the count of rows fetched. The orchestrator interprets
///     `< pageSize` as "last page".
abstract class PullHandler {
  const PullHandler();

  /// Local table name — used by [PullHandlerRegistry] for dispatch.
  String get tableName;

  /// Fetch one page of cloud rows starting at [offset]. Returns the
  /// number of rows fetched. A return value of `0` (or `< pageSize`)
  /// signals end-of-table to the orchestrator.
  Future<int> pullPage({required int offset, required int pageSize});

  /// Fetch every cloud row whose `updated_at > since` and apply each
  /// (upsert if `deleted_at IS NULL`, delete-by-cloud-id otherwise).
  /// Drives [IncrementalPull] for cross-device delta propagation
  /// after the initial-sync hydration is complete.
  ///
  /// Returns the number of rows applied. Implementations should
  /// tolerate `since == null` by treating it as a full pull (rare —
  /// the orchestrator only calls this once `last_full_sync_at` is
  /// set).
  Future<int> pullSince(DateTime? since);
}

class PullHandlerRegistry {
  PullHandlerRegistry._(this._handlers);

  final Map<String, PullHandler> _handlers;

  factory PullHandlerRegistry.empty() => PullHandlerRegistry._({});

  PullHandler? handlerFor(String tableName) => _handlers[tableName];

  void register(PullHandler handler) {
    _handlers[handler.tableName] = handler;
  }
}

/// Tables in the order [SyncEngine.pullAll] hydrates them. Earlier
/// entries unblock UX features sooner:
///   • Tier 1 — profile + onboarding answers (so onboarding is
///     skipped on the new device).
///   • Tier 2 — per-muscle ranks + streak + class (so Home renders
///     correctly without further loads).
///   • Tier 3 — append-only history (workouts must precede sets so
///     the FK lookup `workout_id → cloud_id → local id` resolves).
const List<String> kPullPriorityOrder = [
  // Tier 1 — onboarding-skip enablers.
  'player',
  'goals',
  'experience',
  'schedule',
  'notification_prefs',
  // Tier 2 — Home-render enablers.
  'muscle_ranks',
  'streaks',
  'player_class',
  // Tier 3 — bulk history.
  'workouts',
  'sets',
  'quests',
  'streak_freeze_events',
  'weight_logs',
];
