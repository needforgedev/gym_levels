import '../schema.dart';

/// Singleton sync-state row. Always exactly one row in the
/// `sync_state` table, `id = 1`. Tracks the in-progress initial-sync
/// cursor (so device-switch hydration is resumable across app kills)
/// and the last-known good drain timestamp for telemetry.
class SyncStateRow {
  const SyncStateRow({
    this.lastFullSyncAt,
    this.initialSyncTable,
    this.initialSyncOffset = 0,
    this.lastOutboxDrainAt,
  });

  /// Epoch seconds of the most recent full hydration completion.
  /// `null` until the first successful initial-sync.
  final int? lastFullSyncAt;

  /// Which table the in-progress initial-sync is currently pulling.
  /// `null` when no initial-sync is in flight.
  final String? initialSyncTable;

  /// Pagination cursor (offset) inside [initialSyncTable].
  final int initialSyncOffset;

  /// Epoch seconds of the most recent outbox-drain attempt (whether
  /// it succeeded or failed). Used by the app-foreground hook to
  /// avoid re-draining too eagerly.
  final int? lastOutboxDrainAt;

  bool get isInitialSyncInProgress => initialSyncTable != null;

  factory SyncStateRow.fromRow(Map<String, Object?> r) => SyncStateRow(
        lastFullSyncAt: r[CSyncState.lastFullSyncAt] as int?,
        initialSyncTable: r[CSyncState.initialSyncTable] as String?,
        initialSyncOffset: r[CSyncState.initialSyncOffset] as int? ?? 0,
        lastOutboxDrainAt: r[CSyncState.lastOutboxDrainAt] as int?,
      );

  Map<String, Object?> toRow() => {
        CSyncState.id: 1,
        CSyncState.lastFullSyncAt: lastFullSyncAt,
        CSyncState.initialSyncTable: initialSyncTable,
        CSyncState.initialSyncOffset: initialSyncOffset,
        CSyncState.lastOutboxDrainAt: lastOutboxDrainAt,
      };

  SyncStateRow copyWith({
    int? lastFullSyncAt,
    String? initialSyncTable,
    bool clearInitialSyncTable = false,
    int? initialSyncOffset,
    int? lastOutboxDrainAt,
  }) =>
      SyncStateRow(
        lastFullSyncAt: lastFullSyncAt ?? this.lastFullSyncAt,
        initialSyncTable: clearInitialSyncTable
            ? null
            : (initialSyncTable ?? this.initialSyncTable),
        initialSyncOffset: initialSyncOffset ?? this.initialSyncOffset,
        lastOutboxDrainAt: lastOutboxDrainAt ?? this.lastOutboxDrainAt,
      );
}
