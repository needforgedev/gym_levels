import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'schema.dart';
import 'seed/exercise_catalog.dart';
import 'services/exercise_service.dart';

/// Singleton holder for the app's SQLite database.
///
/// Usage (production):
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await AppDb.init();
///   runApp(...);
/// }
/// ```
///
/// Services call `await AppDb.instance` for every query.
///
/// Tests: `AppDb.overrideForTesting(memoryDatabase)` to swap in an in-memory
/// sqflite_common_ffi database. Call `AppDb.close()` in `tearDown`.
class AppDb {
  AppDb._();

  static Database? _db;
  static Completer<Database>? _opening;

  /// Eagerly opens (or re-opens) the singleton database. Safe to call from
  /// `main()` after `WidgetsFlutterBinding.ensureInitialized()`.
  ///
  /// When [seed] is `true` (default), the exercise catalog is auto-inserted
  /// on first launch via [_seedIfEmpty]. Tests pass `seed: false` to keep
  /// fixture DBs free of the 80-row seed.
  static Future<Database> init({
    String? overridePath,
    bool seed = true,
  }) async {
    if (_db != null) return _db!;
    _db = await _open(overridePath);
    if (seed) await _seedIfEmpty();
    return _db!;
  }

  /// Returns the open singleton. If not open yet, opens lazily (without
  /// seeding — use [init] for that).
  static Future<Database> get instance async {
    if (_db != null) return _db!;
    // Guard against concurrent callers during cold boot.
    if (_opening != null) return _opening!.future;
    final c = _opening = Completer<Database>();
    try {
      final db = await _open(null);
      _db = db;
      c.complete(db);
      return db;
    } catch (e, st) {
      c.completeError(e, st);
      rethrow;
    } finally {
      _opening = null;
    }
  }

  /// Closes the DB (hot restart, tests, sign-out).
  static Future<void> close() async {
    final db = _db;
    _db = null;
    if (db != null) await db.close();
  }

  /// PRD §19 — "Delete my data" wipes every row and closes the DB. The next
  /// open re-runs `onCreate` (clean slate).
  static Future<void> reset() async {
    final db = await instance;
    final path = db.path;
    await db.close();
    _db = null;
    await deleteDatabase(path);
  }

  /// Test hook: bypass the file-based opener and inject a pre-opened DB.
  static void overrideForTesting(Database db) {
    _db = db;
  }

  // ─── internal ─────────────────────────────────────────────────────────

  static Future<Database> _open(String? overridePath) async {
    final path = overridePath ?? await _defaultPath();
    return openDatabase(
      path,
      version: kSchemaVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<String> _defaultPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, 'gym_levels.db');
  }

  static Future<void> _onConfigure(Database db) async {
    // PRD §11.7 integrity rules — SQLite ships with foreign keys off.
    await db.execute('PRAGMA foreign_keys = ON');
  }

  static Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();
    for (final stmt in createStatements) {
      batch.execute(stmt);
    }
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    batch.insert(T.schemaVersion, {
      CSchemaVersion.version: version,
      CSchemaVersion.appliedAt: now,
      CSchemaVersion.note: 'initial schema',
    });
    await batch.commit(noResult: true);
  }

  static Future<void> _onUpgrade(Database db, int from, int to) async {
    // Forward-only migrations. Each numbered branch is idempotent —
    // safe to re-run if a previous attempt failed mid-way (sqflite
    // does not transactionally roll back DDL on iOS / Android).
    //
    // PRD §17 risk — back the DB file up to `gym_levels.db.pre-migration`
    // before running each upgrade once migration logic lands. (TODO).
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // v1 → v2: Scope B sync columns + sync_outbox + sync_state. Lands
    // with socials_plan.md S3.0. Adds three nullable columns to every
    // cloud-mirrored local table, plus two new local tables.
    if (from < 2 && to >= 2) {
      await _migrateV1toV2(db);
    }

    await db.insert(T.schemaVersion, {
      CSchemaVersion.version: to,
      CSchemaVersion.appliedAt: now,
      CSchemaVersion.note: 'upgraded from v$from',
    });
  }

  /// v1 → v2: Adds `cloud_id`, `cloud_updated_at`, `cloud_deleted_at`
  /// columns to every cloud-mirrored local table, then creates the
  /// `sync_outbox` and `sync_state` tables.
  ///
  /// The column-add operations are individually idempotent — sqflite's
  /// `ALTER TABLE ADD COLUMN` succeeds-or-throws-with-duplicate. Wrap
  /// each in a try/catch that swallows duplicate-column exceptions so
  /// re-runs after a partial failure resume cleanly.
  static Future<void> _migrateV1toV2(Database db) async {
    const syncedTables = <String>[
      T.player,
      T.goals,
      T.experience,
      T.schedule,
      T.notificationPrefs,
      T.playerClass,
      T.workouts,
      T.sets,
      T.muscleRanks,
      T.quests,
      T.streaks,
      T.streakFreezeEvents,
      T.weightLogs,
    ];

    for (final table in syncedTables) {
      await _addColumnIfMissing(db, table, CSync.cloudId, 'TEXT');
      await _addColumnIfMissing(db, table, CSync.cloudUpdatedAt, 'INTEGER');
      await _addColumnIfMissing(db, table, CSync.cloudDeletedAt, 'INTEGER');
    }

    // sync_outbox + indexes.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${T.syncOutbox} (
        ${CSyncOutbox.id}            INTEGER PRIMARY KEY AUTOINCREMENT,
        ${CSyncOutbox.tableName}     TEXT NOT NULL,
        ${CSyncOutbox.localRowId}    INTEGER NOT NULL,
        ${CSyncOutbox.cloudId}       TEXT NOT NULL,
        ${CSyncOutbox.opType}        TEXT NOT NULL CHECK (${CSyncOutbox.opType} IN ('upsert', 'delete')),
        ${CSyncOutbox.payloadJson}   TEXT,
        ${CSyncOutbox.createdAt}     INTEGER NOT NULL,
        ${CSyncOutbox.attemptCount}  INTEGER NOT NULL DEFAULT 0,
        ${CSyncOutbox.lastAttemptAt} INTEGER,
        ${CSyncOutbox.lastError}     TEXT,
        ${CSyncOutbox.pushedAt}      INTEGER
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sync_outbox_pending '
      'ON ${T.syncOutbox}(${CSyncOutbox.createdAt}) '
      'WHERE ${CSyncOutbox.pushedAt} IS NULL',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sync_outbox_pushed '
      'ON ${T.syncOutbox}(${CSyncOutbox.pushedAt}) '
      'WHERE ${CSyncOutbox.pushedAt} IS NOT NULL',
    );

    // sync_state singleton.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${T.syncState} (
        ${CSyncState.id}                 INTEGER PRIMARY KEY CHECK (${CSyncState.id} = 1),
        ${CSyncState.lastFullSyncAt}     INTEGER,
        ${CSyncState.initialSyncTable}   TEXT,
        ${CSyncState.initialSyncOffset}  INTEGER NOT NULL DEFAULT 0,
        ${CSyncState.lastOutboxDrainAt}  INTEGER
      )
    ''');
    // Seed the singleton row if it doesn't already exist.
    await db.rawInsert(
      'INSERT OR IGNORE INTO ${T.syncState} (${CSyncState.id}) VALUES (1)',
    );
  }

  /// Idempotent ALTER TABLE ADD COLUMN. sqflite throws on duplicate
  /// columns; catch and ignore so re-running the migration after a
  /// partial failure is safe.
  static Future<void> _addColumnIfMissing(
    Database db,
    String table,
    String column,
    String type,
  ) async {
    try {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $type');
    } on DatabaseException catch (e) {
      // SQLite returns "duplicate column name" when the column already
      // exists — ignore. Any other error rethrows.
      if (!e.toString().toLowerCase().contains('duplicate column')) {
        rethrow;
      }
    }
  }

  /// Seeds the `exercises` table from [exerciseCatalog] if empty.
  /// Idempotent — safe to call on every launch. PRD Appendix A.
  static Future<void> _seedIfEmpty() async {
    final existing = await ExerciseService.count();
    if (existing > 0) return;
    await ExerciseService.insertBatch(exerciseCatalog);
  }
}
