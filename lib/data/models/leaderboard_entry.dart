/// Which column to rank by — drives the LeaderboardScreen tab choice.
enum LeaderboardMetric {
  weeklyXp('weekly_xp', 'Weekly XP'),
  monthlyXp('monthly_xp', 'Monthly XP'),
  currentStreak('current_streak', 'Streak'),
  totalXp('total_xp', 'All-time XP');

  const LeaderboardMetric(this.column, this.label);
  final String column;
  final String label;
}

/// One row of the leaderboard — a `public_profiles` snapshot ranked
/// by the active metric. `rank` is computed client-side from the
/// fetched ordering (1-based).
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.userId,
    required this.username,
    required this.displayName,
    this.avatarKey,
    required this.level,
    required this.totalXp,
    required this.weeklyXp,
    required this.monthlyXp,
    required this.currentStreak,
    required this.longestStreak,
    required this.rank,
    required this.isMe,
  });

  final String userId;
  final String username;
  final String displayName;
  final String? avatarKey;
  final int level;
  final int totalXp;
  final int weeklyXp;
  final int monthlyXp;
  final int currentStreak;
  final int longestStreak;
  final int rank;
  final bool isMe;

  factory LeaderboardEntry.fromRow(
    Map<String, dynamic> r, {
    required int rank,
    required bool isMe,
  }) =>
      LeaderboardEntry(
        userId: r['user_id'] as String,
        username: (r['username'] as String?) ?? '',
        displayName: (r['display_name'] as String?) ?? '',
        avatarKey: r['avatar_key'] as String?,
        level: (r['level'] as int?) ?? 1,
        totalXp: (r['total_xp'] as int?) ?? 0,
        weeklyXp: (r['weekly_xp'] as int?) ?? 0,
        monthlyXp: (r['monthly_xp'] as int?) ?? 0,
        currentStreak: (r['current_streak'] as int?) ?? 0,
        longestStreak: (r['longest_streak'] as int?) ?? 0,
        rank: rank,
        isMe: isMe,
      );

  /// Value for the active metric — rendered as the right-side column
  /// on the leaderboard row.
  int valueFor(LeaderboardMetric m) => switch (m) {
        LeaderboardMetric.weeklyXp => weeklyXp,
        LeaderboardMetric.monthlyXp => monthlyXp,
        LeaderboardMetric.currentStreak => currentStreak,
        LeaderboardMetric.totalXp => totalXp,
      };
}
