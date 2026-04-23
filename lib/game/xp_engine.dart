import 'dart:math' as math;

/// PRD §12 — all XP + level math.
///
/// Pure functions, zero I/O. Callers bring the inputs (per-set baseXp, RPE,
/// PR flag, cumulative XP) and receive primitive outputs. Keeps the engine
/// unit-testable without touching `AppDb`.
class XpEngine {
  XpEngine._();

  /// +25 XP added to any set that beats the player's historical weight-for-reps
  /// PR for that exercise. Additive, not multiplicative — the PRD gloss reads
  /// "+25 XP" which implies addition after the base × multiplier roll-up.
  static const int prBonusXp = 25;

  /// Player level is capped at 99 (PRD §12).
  static const int maxLevel = 99;

  /// PRD §12 — RPE multiplier curve. Anchors:
  ///   RPE 5 → 0.6
  ///   RPE 8 → 1.0
  ///   RPE 10 → 1.3
  ///
  /// Linearly interpolated between the anchors; clamps outside [5, 10]; a
  /// null/unset RPE is treated as "on target" (1.0) rather than half-credit.
  static double rpeMultiplier(int? rpe) {
    if (rpe == null) return 1.0;
    final r = rpe.clamp(5, 10).toDouble();
    if (r <= 8) {
      // slope = (1.0 - 0.6) / (8 - 5) = 0.133…
      return 0.6 + (r - 5) * (1.0 - 0.6) / (8 - 5);
    }
    // slope = (1.3 - 1.0) / (10 - 8) = 0.15
    return 1.0 + (r - 8) * (1.3 - 1.0) / (10 - 8);
  }

  /// XP earned by a single completed set.
  /// Formula: round(baseXp × rpeMultiplier) + (isPr ? 25 : 0).
  static int xpForSet({
    required int baseXp,
    int? rpe,
    required bool isPr,
  }) {
    final scaled = (baseXp * rpeMultiplier(rpe)).round();
    return scaled + (isPr ? prBonusXp : 0);
  }

  /// PRD §12 — `xp_to_next(level) = round(100 × level^1.45)`.
  /// Returns 0 at the level cap so callers can detect "no further progression".
  static int xpToNextLevel(int currentLevel) {
    if (currentLevel >= maxLevel) return 0;
    if (currentLevel < 1) return 100;
    return (100 * math.pow(currentLevel, 1.45)).round();
  }

  /// Resolve `totalLifetimeXp` (cumulative across every workout) into the
  /// player's current level + how far they are within the current level.
  ///
  /// Linear walk from level 1 — fast enough for the level cap (99 hops max)
  /// and avoids building a lookup table for something that is queried once
  /// per Home paint.
  static LevelSnapshot resolve(int totalLifetimeXp) {
    if (totalLifetimeXp < 0) totalLifetimeXp = 0;
    var level = 1;
    var remaining = totalLifetimeXp;
    while (level < maxLevel) {
      final need = xpToNextLevel(level);
      if (remaining < need) {
        return LevelSnapshot(
          level: level,
          xpInLevel: remaining,
          xpToNext: need,
        );
      }
      remaining -= need;
      level++;
    }
    return const LevelSnapshot(level: maxLevel, xpInLevel: 0, xpToNext: 0);
  }
}

class LevelSnapshot {
  const LevelSnapshot({
    required this.level,
    required this.xpInLevel,
    required this.xpToNext,
  });

  /// Current level in `[1, XpEngine.maxLevel]`.
  final int level;

  /// XP earned within the current level (0..[xpToNext]).
  final int xpInLevel;

  /// XP required to reach the next level. `0` at the level cap.
  final int xpToNext;

  /// 0..1 progress toward next level. `1.0` at the cap.
  double get progress {
    if (xpToNext == 0) return 1.0;
    return (xpInLevel / xpToNext).clamp(0.0, 1.0);
  }

  bool get isCapped => level >= XpEngine.maxLevel;
}
