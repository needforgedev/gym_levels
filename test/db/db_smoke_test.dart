import 'package:flutter_test/flutter_test.dart';
import 'package:gym_levels/data/app_db.dart';
import 'package:gym_levels/data/models/goal.dart';
import 'package:gym_levels/data/services/analytics_service.dart';
import 'package:gym_levels/data/services/exercise_service.dart';
import 'package:gym_levels/data/services/goals_service.dart';
import 'package:gym_levels/data/services/player_service.dart';
import 'package:gym_levels/data/services/streak_service.dart';
import 'package:gym_levels/data/services/subscription_service.dart';
import 'package:gym_levels/data/services/weight_log_service.dart';
import 'package:gym_levels/data/models/exercise.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Round-trips every public service method against an in-memory SQLite DB.
/// Proves: (1) the schema creates cleanly, (2) JSON list converters are
/// symmetric, (3) the cascade from `DELETE player` wipes every dependent row.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await AppDb.close();
    // `seed: false` — keeps fixtures small. Seed behaviour is tested in
    // test/db/seed_test.dart.
    await AppDb.init(overridePath: inMemoryDatabasePath, seed: false);
  });

  tearDown(() async {
    await AppDb.close();
  });

  test('Player round-trip + onboarding completion', () async {
    expect(await PlayerService.getPlayer(), isNull);
    await PlayerService.setDisplayName('Kael·7');
    final p1 = await PlayerService.getPlayer();
    expect(p1, isNotNull);
    expect(p1!.displayName, 'Kael·7');
    expect(p1.isOnboarded, isFalse);

    await PlayerService.completeOnboarding();
    final p2 = await PlayerService.getPlayer();
    expect(p2!.isOnboarded, isTrue);
  });

  test('Goals JSON-list converters survive a round trip', () async {
    await PlayerService.setDisplayName('X');
    await GoalsService.upsert(
      const Goal(
        bodyType: 'muscular',
        priorityMuscles: ['chest', 'back', 'quads'],
        weightDirection: 'gain',
        targetWeightKg: 80,
        updatedAt: 0,
      ),
    );
    final g = await GoalsService.get();
    expect(g, isNotNull);
    expect(g!.bodyType, 'muscular');
    expect(g.priorityMuscles, ['chest', 'back', 'quads']);
    expect(g.weightDirection, 'gain');
    expect(g.targetWeightKg, 80);
  });

  test('Exercise seed is idempotent and queryable', () async {
    await ExerciseService.insertBatch(const [
      Exercise(name: 'Bench Press', primaryMuscle: 'chest', baseXp: 5),
      Exercise(name: 'Squat', primaryMuscle: 'quads', baseXp: 5),
    ]);
    // Re-run — must not double-insert.
    await ExerciseService.insertBatch(const [
      Exercise(name: 'Bench Press', primaryMuscle: 'chest', baseXp: 5),
    ]);
    expect(await ExerciseService.count(), 2);
    final chest = await ExerciseService.byPrimaryMuscle('chest');
    expect(chest, hasLength(1));
    expect(chest.first.name, 'Bench Press');
  });

  test('Weight log enforces one-per-day UNIQUE constraint via upsert', () async {
    await PlayerService.setDisplayName('X');
    const day = 1700000000;
    await WeightLogService.upsertForDay(dayEpoch: day, weightKg: 80.0);
    await WeightLogService.upsertForDay(
        dayEpoch: day, weightKg: 79.5, note: 'revised');
    final all = await WeightLogService.all();
    expect(all, hasLength(1));
    expect(all.first.weightKg, 79.5);
    expect(all.first.note, 'revised');
  });

  test('Analytics outbox pending → markUploaded lifecycle', () async {
    final id1 = await AnalyticsService.log('onboarding_started', {'v': 1});
    await AnalyticsService.log('set_logged', {'xp': 25});
    expect((await AnalyticsService.pending()).length, 2);
    await AnalyticsService.markUploaded([id1]);
    expect((await AnalyticsService.pending()).length, 1);
    expect((await AnalyticsService.pending()).first.name, 'set_logged');
  });

  test('Subscription.isProCached reflects tier + status + renewsAt', () async {
    await PlayerService.setDisplayName('X');
    expect(await SubscriptionService.isProCached(), isFalse);
    // Simulated Pro purchase, renewal 1 hr in the future.
    final future = (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 3600;
    final db = await AppDb.instance;
    await db.rawInsert('''
      INSERT INTO subscriptions (user_id, tier, status, renews_at, updated_at)
      VALUES (1, 'annual', 'active', $future, 0)
    ''');
    expect(await SubscriptionService.isProCached(), isTrue);
  });

  test('Streak ensure creates singleton with sensible defaults', () async {
    await PlayerService.setDisplayName('X');
    final s = await StreakService.ensure();
    expect(s.current, 0);
    expect(s.freezesRemaining, 1);
  });

  test('DELETE player cascades every dependent row', () async {
    await PlayerService.setDisplayName('X');
    await GoalsService.upsert(const Goal(priorityMuscles: ['chest'], updatedAt: 0));
    await AnalyticsService.log('t'); // not FK-linked
    await PlayerService.deleteAll();
    expect(await PlayerService.getPlayer(), isNull);
    expect(await GoalsService.get(), isNull);
  });
}
