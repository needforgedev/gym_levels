import 'package:flutter_test/flutter_test.dart';
import 'package:gym_levels/data/app_db.dart';
import 'package:gym_levels/data/models/streak.dart';
import 'package:gym_levels/data/services/player_service.dart';
import 'package:gym_levels/data/services/streak_service.dart';
import 'package:gym_levels/game/streak_engine.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

int _todayEpoch() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day).millisecondsSinceEpoch ~/ 1000;
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await AppDb.close();
    await AppDb.init(overridePath: inMemoryDatabasePath, seed: false);
    await PlayerService.setDisplayName('X');
  });

  tearDown(() async {
    await AppDb.close();
  });

  test('first finished workout increments to 1', () async {
    final r = await StreakEngine.onWorkoutFinished();
    expect(r.incremented, isTrue);
    expect(r.current, 1);
    expect(r.longest, 1);
  });

  test('second finish same day is a no-op', () async {
    await StreakEngine.onWorkoutFinished();
    final r = await StreakEngine.onWorkoutFinished();
    expect(r.incremented, isFalse);
    expect(r.current, 1);
  });

  test('gap of >1 day resets current to 1 but keeps longest', () async {
    // Seed an older streak: current=7, longest=7, lastActive=10 days ago.
    final tenDaysAgo = _todayEpoch() - (10 * Duration.secondsPerDay);
    await StreakService.upsert(Streak(
      current: 7,
      longest: 7,
      lastActiveDate: tenDaysAgo,
      freezesPeriodStart: tenDaysAgo,
    ));

    final r = await StreakEngine.onWorkoutFinished();
    expect(r.current, 1);
    expect(r.longest, 7);
  });

  test('consecutive-day streak increments without reset', () async {
    final yesterday = _todayEpoch() - Duration.secondsPerDay;
    await StreakService.upsert(Streak(
      current: 6,
      longest: 6,
      lastActiveDate: yesterday,
      freezesPeriodStart: yesterday,
    ));

    final r = await StreakEngine.onWorkoutFinished();
    expect(r.current, 7);
    expect(r.longest, 7);
    expect(r.milestoneReached, isTrue);
  });

  test('milestone flag only fires on exact milestone days', () async {
    final yesterday = _todayEpoch() - Duration.secondsPerDay;
    await StreakService.upsert(Streak(
      current: 4,
      longest: 4,
      lastActiveDate: yesterday,
      freezesPeriodStart: yesterday,
    ));

    final r = await StreakEngine.onWorkoutFinished();
    expect(r.current, 5);
    expect(r.milestoneReached, isFalse);
  });
}
