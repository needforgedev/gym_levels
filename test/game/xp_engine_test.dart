import 'package:flutter_test/flutter_test.dart';
import 'package:gym_levels/game/xp_engine.dart';

void main() {
  group('XpEngine.rpeMultiplier', () {
    test('anchor points match PRD §12 exactly', () {
      expect(XpEngine.rpeMultiplier(5), closeTo(0.6, 1e-9));
      expect(XpEngine.rpeMultiplier(8), closeTo(1.0, 1e-9));
      expect(XpEngine.rpeMultiplier(10), closeTo(1.3, 1e-9));
    });

    test('interpolates linearly between 5–8 and 8–10', () {
      expect(XpEngine.rpeMultiplier(6), closeTo(0.733, 1e-3));
      expect(XpEngine.rpeMultiplier(7), closeTo(0.866, 1e-3));
      expect(XpEngine.rpeMultiplier(9), closeTo(1.15, 1e-3));
    });

    test('clamps below 5 and above 10', () {
      expect(XpEngine.rpeMultiplier(1), 0.6);
      expect(XpEngine.rpeMultiplier(20), 1.3);
    });

    test('null rpe → 1.0 (treat as "on target")', () {
      expect(XpEngine.rpeMultiplier(null), 1.0);
    });
  });

  group('XpEngine.xpForSet', () {
    test('compound @ RPE 8, no PR → baseXp × 1.0', () {
      expect(
        XpEngine.xpForSet(baseXp: 5, rpe: 8, isPr: false),
        5,
      );
    });

    test('compound @ RPE 8, PR → base + 25', () {
      expect(
        XpEngine.xpForSet(baseXp: 5, rpe: 8, isPr: true),
        30,
      );
    });

    test('accessory @ RPE 10, no PR → 3 × 1.3 → 4 rounded', () {
      expect(
        XpEngine.xpForSet(baseXp: 3, rpe: 10, isPr: false),
        4,
      );
    });

    test('null rpe uses 1.0 multiplier', () {
      expect(
        XpEngine.xpForSet(baseXp: 5, rpe: null, isPr: false),
        5,
      );
    });
  });

  group('XpEngine.xpToNextLevel', () {
    test('level 1 → 100 XP (PRD §12 anchor)', () {
      expect(XpEngine.xpToNextLevel(1), 100);
    });

    test('level 10 ≈ 2818 XP (PRD §12 anchor)', () {
      final v = XpEngine.xpToNextLevel(10);
      expect(v, inInclusiveRange(2810, 2830));
    });

    test('level cap → 0', () {
      expect(XpEngine.xpToNextLevel(99), 0);
      expect(XpEngine.xpToNextLevel(100), 0);
    });
  });

  group('XpEngine.resolve', () {
    test('0 lifetime XP → level 1 @ 0/100', () {
      final s = XpEngine.resolve(0);
      expect(s.level, 1);
      expect(s.xpInLevel, 0);
      expect(s.xpToNext, 100);
      expect(s.progress, 0);
    });

    test('mid-level-1 progress math', () {
      final s = XpEngine.resolve(40);
      expect(s.level, 1);
      expect(s.xpInLevel, 40);
      expect(s.progress, closeTo(0.4, 1e-9));
    });

    test('exactly level-2 threshold crosses', () {
      final s = XpEngine.resolve(100);
      expect(s.level, 2);
      expect(s.xpInLevel, 0);
    });

    test('huge XP caps at 99', () {
      final s = XpEngine.resolve(999999999);
      expect(s.level, 99);
      expect(s.isCapped, isTrue);
      expect(s.progress, 1.0);
    });
  });
}
