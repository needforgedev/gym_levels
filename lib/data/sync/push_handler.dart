import '../models/sync_outbox.dart';

/// One push handler per cloud-mirrored table. Converts an outbox row's
/// `payloadJson` snapshot into a Supabase upsert/delete and calls it.
///
/// Throws on transport / auth / RLS errors — the [SyncEngine] catches
/// the exception, increments `attempt_count`, and schedules a backoff
/// retry. Returning normally signals success → the outbox row is
/// stamped `pushed_at`.
abstract class PushHandler {
  const PushHandler();

  /// The local table this handler is responsible for. Must match the
  /// `table_name` column of any outbox row routed here.
  String get tableName;

  /// Push exactly one outbox row to Supabase. Implementations must be
  /// idempotent — the engine may re-call after a transient failure
  /// where the server actually persisted the row but the ack was lost.
  Future<void> push(SyncOutboxRow row);
}

/// Registry of per-table push handlers. S3.1 ships no real handlers —
/// every cloud-mirrored table maps to [_NoopHandler] which logs and
/// throws so the engine treats pushes as failed (and shelves them with
/// backoff) until S3.2 lands the real implementations.
class PushHandlerRegistry {
  PushHandlerRegistry._(this._handlers);

  final Map<String, PushHandler> _handlers;

  /// S3.1 default — every supported table maps to a no-op stub. Replace
  /// individual entries in S3.2 as real handlers come online.
  factory PushHandlerRegistry.skeleton() {
    return PushHandlerRegistry._({
      for (final t in syncedTables) t: _NoopHandler(t),
    });
  }

  /// Look up the handler for [tableName]. Returns `null` for tables
  /// the registry doesn't know about — the engine logs and dead-letters
  /// such rows so an unhandled table can't block the queue forever.
  PushHandler? handlerFor(String tableName) => _handlers[tableName];

  /// Register / override a handler. S3.2 calls this once per table at
  /// startup to swap the no-op stubs for real handlers.
  void register(PushHandler handler) {
    _handlers[handler.tableName] = handler;
  }
}

/// The 13 cloud-mirrored local tables. Mirrors the list in
/// `AppDb._migrateV1toV2` and `socials_plan.md` §1.2. Source-of-truth
/// for "what gets pushed" — anything not in this list shouldn't be
/// enqueued in the first place.
const List<String> syncedTables = [
  'player',
  'goals',
  'experience',
  'schedule',
  'notification_prefs',
  'player_class',
  'workouts',
  'sets',
  'muscle_ranks',
  'quests',
  'streaks',
  'streak_freeze_events',
  'weight_logs',
];

/// Placeholder for S3.1 — throws so the engine records a failure and
/// shelves the row with backoff. S3.2 replaces these with concrete
/// PostgREST calls.
class _NoopHandler extends PushHandler {
  const _NoopHandler(this.tableName);

  @override
  final String tableName;

  @override
  Future<void> push(SyncOutboxRow row) async {
    throw UnimplementedError(
      'PushHandler for $tableName not wired yet (S3.2). '
      'Outbox row id=${row.id} op=${row.opType.wire} cloud_id=${row.cloudId} '
      'will be retried with backoff.',
    );
  }
}
