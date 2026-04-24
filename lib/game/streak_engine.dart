import '../data/models/streak.dart';
import '../data/services/streak_service.dart';

/// PRD §12 + §9.5 — streak state machine.
///
/// Minimum-viable rules shipped now:
/// - Increment current once per calendar day on a workout finish.
/// - Break in any day gap (lastActive < yesterday) resets current to 1.
/// - Track `longest`.
/// - Milestone hook fires on 7 / 14 / 30 / 60 / 90 / 180 / 365-day marks.
///
/// Deferred (TODO as the gameplay loop matures):
/// - Respect `schedule.days` (only count scheduled days).
/// - Freeze auto-consumption (PRD §9A.5).
/// - RPE ≥ 6 gate.
/// - Clock-skew guard (PRD §17).
class StreakEngine {
  StreakEngine._();

  static const List<int> _milestones = [7, 14, 30, 60, 90, 180, 365];

  /// Public read of the milestone ladder — lets the Streak screen compute
  /// the next milestone without duplicating the constant.
  static List<int> get milestones => _milestones;

  /// Called by [GameHandlers.onWorkoutFinished] after a session is committed.
  /// Returns the post-update snapshot + whether the streak changed.
  static Future<StreakUpdate> onWorkoutFinished() async {
    final existing = await StreakService.ensure();
    final todayEpoch = _todayEpoch();

    // Already counted today — no-op.
    if (existing.lastActiveDate == todayEpoch) {
      return StreakUpdate(
        current: existing.current,
        longest: existing.longest,
        incremented: false,
      );
    }

    final yesterdayEpoch = todayEpoch - Duration.secondsPerDay;
    final last = existing.lastActiveDate;

    // Consecutive day? keep counting. Missed one or more days? reset to 1.
    final int newCurrent;
    if (last == null || last < yesterdayEpoch) {
      newCurrent = 1;
    } else {
      newCurrent = existing.current + 1;
    }

    final newLongest =
        newCurrent > existing.longest ? newCurrent : existing.longest;

    await StreakService.upsert(Streak(
      current: newCurrent,
      longest: newLongest,
      lastActiveDate: todayEpoch,
      freezesRemaining: existing.freezesRemaining,
      freezesPeriodStart: existing.freezesPeriodStart,
    ));

    return StreakUpdate(
      current: newCurrent,
      longest: newLongest,
      incremented: true,
      milestoneReached: _milestones.contains(newCurrent),
    );
  }

  /// Epoch seconds of local midnight for today. Keeps the
  /// "one-streak-per-day" comparison safe across time zones.
  static int _todayEpoch() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    return midnight.millisecondsSinceEpoch ~/ 1000;
  }
}

class StreakUpdate {
  const StreakUpdate({
    required this.current,
    required this.longest,
    required this.incremented,
    this.milestoneReached = false,
  });

  final int current;
  final int longest;
  final bool incremented;
  final bool milestoneReached;
}
