import '../schema.dart';

class Streak {
  const Streak({
    this.userId = 1,
    this.current = 0,
    this.longest = 0,
    this.lastActiveDate,
    this.freezesRemaining = 1,
    required this.freezesPeriodStart,
  });

  final int userId;
  final int current;
  final int longest;
  final int? lastActiveDate;
  final int freezesRemaining;
  final int freezesPeriodStart;

  factory Streak.fromRow(Map<String, Object?> r) => Streak(
        userId: r[CStreak.userId] as int,
        current: r[CStreak.current] as int? ?? 0,
        longest: r[CStreak.longest] as int? ?? 0,
        lastActiveDate: r[CStreak.lastActiveDate] as int?,
        freezesRemaining: r[CStreak.freezesRemaining] as int? ?? 1,
        freezesPeriodStart: r[CStreak.freezesPeriodStart] as int,
      );

  Map<String, Object?> toRow() => {
        CStreak.userId: userId,
        CStreak.current: current,
        CStreak.longest: longest,
        CStreak.lastActiveDate: lastActiveDate,
        CStreak.freezesRemaining: freezesRemaining,
        CStreak.freezesPeriodStart: freezesPeriodStart,
      };
}
