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
    // Future migrations: keep them forward-only, idempotent, and unit-tested.
    // PRD §17 risk — back the DB file up to `gym_levels.db.pre-migration`
    // before running each upgrade once migration logic lands.
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await db.insert(T.schemaVersion, {
      CSchemaVersion.version: to,
      CSchemaVersion.appliedAt: now,
      CSchemaVersion.note: 'upgraded from v$from',
    });
  }

  /// Seeds the `exercises` table from [exerciseCatalog] if empty.
  /// Idempotent — safe to call on every launch. PRD Appendix A.
  static Future<void> _seedIfEmpty() async {
    final existing = await ExerciseService.count();
    if (existing > 0) return;
    await ExerciseService.insertBatch(exerciseCatalog);
  }
}
