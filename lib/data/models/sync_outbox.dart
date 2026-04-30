import '../schema.dart';

/// One pending sync operation in the local outbox.
///
/// The `SyncEngine` (S3.1) drains these in FIFO order — for each row
/// it calls the per-table push handler with `payloadJson`, marks the
/// row `pushedAt` on success, or bumps `attemptCount` + writes
/// `lastError` on failure.
///
/// Append-only from the app's perspective: domain-service writes
/// enqueue a new row, and the engine prunes successfully-pushed rows
/// asynchronously.
class SyncOutboxRow {
  const SyncOutboxRow({
    this.id,
    required this.tableName,
    required this.localRowId,
    required this.cloudId,
    required this.opType,
    this.payloadJson,
    required this.createdAt,
    this.attemptCount = 0,
    this.lastAttemptAt,
    this.lastError,
    this.pushedAt,
  });

  final int? id;
  final String tableName;
  final int localRowId;
  final String cloudId;
  final SyncOpType opType;
  final String? payloadJson;
  final int createdAt;
  final int attemptCount;
  final int? lastAttemptAt;
  final String? lastError;
  final int? pushedAt;

  bool get isPushed => pushedAt != null;
  bool get hasFailed => lastError != null && pushedAt == null;

  factory SyncOutboxRow.fromRow(Map<String, Object?> r) => SyncOutboxRow(
        id: r[CSyncOutbox.id] as int?,
        tableName: r[CSyncOutbox.tableName] as String,
        localRowId: r[CSyncOutbox.localRowId] as int,
        cloudId: r[CSyncOutbox.cloudId] as String,
        opType: SyncOpType.fromWire(r[CSyncOutbox.opType] as String),
        payloadJson: r[CSyncOutbox.payloadJson] as String?,
        createdAt: r[CSyncOutbox.createdAt] as int,
        attemptCount: r[CSyncOutbox.attemptCount] as int? ?? 0,
        lastAttemptAt: r[CSyncOutbox.lastAttemptAt] as int?,
        lastError: r[CSyncOutbox.lastError] as String?,
        pushedAt: r[CSyncOutbox.pushedAt] as int?,
      );

  Map<String, Object?> toRow() => {
        if (id != null) CSyncOutbox.id: id,
        CSyncOutbox.tableName: tableName,
        CSyncOutbox.localRowId: localRowId,
        CSyncOutbox.cloudId: cloudId,
        CSyncOutbox.opType: opType.wire,
        CSyncOutbox.payloadJson: payloadJson,
        CSyncOutbox.createdAt: createdAt,
        CSyncOutbox.attemptCount: attemptCount,
        CSyncOutbox.lastAttemptAt: lastAttemptAt,
        CSyncOutbox.lastError: lastError,
        CSyncOutbox.pushedAt: pushedAt,
      };
}

enum SyncOpType {
  upsert('upsert'),
  delete('delete');

  const SyncOpType(this.wire);
  final String wire;

  static SyncOpType fromWire(String s) => switch (s) {
        'upsert' => SyncOpType.upsert,
        'delete' => SyncOpType.delete,
        _ => throw ArgumentError('Unknown SyncOpType wire value: $s'),
      };
}
