import 'package:flutter_test/flutter_test.dart';
import 'package:gym_levels/data/app_db.dart';
import 'package:gym_levels/data/seed/exercise_catalog.dart';
import 'package:gym_levels/data/services/exercise_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Exercise catalog seed (Phase 1.3).
///
/// Verifies:
/// - The bundled catalog has exactly the PRD Appendix A breakdown.
/// - `AppDb.init(seed: true)` populates the `exercises` table on first run.
/// - Re-running `AppDb.init(seed: true)` against an already-seeded DB does
///   not duplicate rows (`ConflictAlgorithm.ignore` on UNIQUE name).
/// - `AppDb.init(seed: false)` skips seeding (used by other test files).
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    await AppDb.close();
  });

  test('catalog ships 80 exercises matching PRD Appendix A breakdown', () {
    expect(exerciseCatalog, hasLength(80));

    final byMuscle = <String, int>{};
    for (final e in exerciseCatalog) {
      byMuscle[e.primaryMuscle] = (byMuscle[e.primaryMuscle] ?? 0) + 1;
    }

    // PRD Appendix A exact counts
    expect(byMuscle['chest'], 12);
    expect(byMuscle['back'], 12);
    expect(byMuscle['shoulders'], 8);
    expect(byMuscle['biceps'], 6);
    expect(byMuscle['triceps'], 6);
    expect(byMuscle['core'], 8);
    expect(byMuscle['quads'], 10);
    expect(byMuscle['hamstrings'], 6);
    expect(byMuscle['glutes'], 6);
    expect(byMuscle['calves'], 6);

    // PRD §12 — compound lifts (baseXp 5) include at least these signatures.
    final compoundNames = exerciseCatalog
        .where((e) => e.baseXp >= 5)
        .map((e) => e.name)
        .toSet();
    expect(compoundNames, contains('Barbell Bench Press'));
    expect(compoundNames, contains('Back Squat'));
    expect(compoundNames, contains('Deadlift'));
    expect(compoundNames, contains('Overhead Press'));
  });

  test('AppDb.init(seed: true) populates the exercises table once', () async {
    await AppDb.init(overridePath: inMemoryDatabasePath, seed: true);
    expect(await ExerciseService.count(), 80);
  });

  test('Re-running the seed against an already-populated DB is a no-op',
      () async {
    await AppDb.init(overridePath: inMemoryDatabasePath, seed: true);
    expect(await ExerciseService.count(), 80);

    // Manually re-invoke the batch insert — `ignore` on UNIQUE name keeps
    // the table at 80 rows.
    await ExerciseService.insertBatch(exerciseCatalog);
    expect(await ExerciseService.count(), 80);
  });

  test('AppDb.init(seed: false) leaves exercises empty', () async {
    await AppDb.init(overridePath: inMemoryDatabasePath, seed: false);
    expect(await ExerciseService.count(), 0);
  });

  test('byPrimaryMuscle surfaces seeded rows', () async {
    await AppDb.init(overridePath: inMemoryDatabasePath, seed: true);
    final chest = await ExerciseService.byPrimaryMuscle('chest');
    expect(chest, hasLength(12));
    expect(chest.any((e) => e.name == 'Barbell Bench Press'), isTrue);
  });
}
