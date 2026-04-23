import 'package:flutter_test/flutter_test.dart';
import 'package:gym_levels/game/rank_engine.dart';

void main() {
  group('RankEngine.assign — tier boundaries', () {
    test('0 XP → Bronze I', () {
      final a = RankEngine.assign(0);
      expect(a.rank, 'bronze');
      expect(a.subRank, 'I');
    });

    test('just below Silver → Bronze III', () {
      final a = RankEngine.assign(499);
      expect(a.rank, 'bronze');
      expect(a.subRank, 'III');
    });

    test('exactly Silver lower bound → Silver I', () {
      final a = RankEngine.assign(500);
      expect(a.rank, 'silver');
      expect(a.subRank, 'I');
    });

    test('Gold lower bound → Gold I', () {
      final a = RankEngine.assign(1500);
      expect(a.rank, 'gold');
      expect(a.subRank, 'I');
    });

    test('Platinum lower bound → Platinum I', () {
      final a = RankEngine.assign(3500);
      expect(a.rank, 'platinum');
      expect(a.subRank, 'I');
    });

    test('Diamond lower bound → Diamond I', () {
      final a = RankEngine.assign(7000);
      expect(a.rank, 'diamond');
      expect(a.subRank, 'I');
    });

    test('Master lower bound → Master (no sub)', () {
      final a = RankEngine.assign(12000);
      expect(a.rank, 'master');
      expect(a.subRank, isNull);
    });

    test('Grandmaster → Grandmaster (no sub)', () {
      final a = RankEngine.assign(20000);
      expect(a.rank, 'grandmaster');
      expect(a.subRank, isNull);
      final bigger = RankEngine.assign(99999);
      expect(bigger.rank, 'grandmaster');
    });
  });

  group('RankEngine.assign — sub-rank thirds', () {
    test('Bronze thirds split 0–500 evenly', () {
      expect(RankEngine.assign(0).subRank, 'I');
      expect(RankEngine.assign(166).subRank, 'I');
      expect(RankEngine.assign(167).subRank, 'II');
      expect(RankEngine.assign(333).subRank, 'II');
      expect(RankEngine.assign(334).subRank, 'III');
      expect(RankEngine.assign(499).subRank, 'III');
    });

    test('Silver thirds split 500–1500 evenly', () {
      expect(RankEngine.assign(500).subRank, 'I');
      expect(RankEngine.assign(833).subRank, 'I');
      expect(RankEngine.assign(834).subRank, 'II');
      expect(RankEngine.assign(1166).subRank, 'II');
      expect(RankEngine.assign(1167).subRank, 'III');
    });
  });

  test('negative XP clamps to Bronze I', () {
    final a = RankEngine.assign(-50);
    expect(a.rank, 'bronze');
    expect(a.subRank, 'I');
  });
}
