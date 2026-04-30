/// One row from `find_users_by_phone_hashes` — a public profile of
/// a user whose phone number matches one of our contacts. Drives the
/// "Friends found" screen list.
class ContactMatch {
  const ContactMatch({
    required this.userId,
    required this.username,
    required this.displayName,
    this.avatarKey,
    required this.level,
    required this.currentStreak,
  });

  /// Supabase auth.users.id of the matched user.
  final String userId;
  final String username;
  final String displayName;
  final String? avatarKey;
  final int level;
  final int currentStreak;

  factory ContactMatch.fromRpcRow(Map<String, dynamic> r) => ContactMatch(
        userId: r['user_id'] as String,
        username: (r['username'] as String?) ?? '',
        displayName: (r['display_name'] as String?) ?? '',
        avatarKey: r['avatar_key'] as String?,
        level: (r['level'] as int?) ?? 1,
        currentStreak: (r['current_streak'] as int?) ?? 0,
      );
}
