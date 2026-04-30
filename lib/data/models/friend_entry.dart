/// One row from `list_my_friend_graph` — a friendship + the
/// counterparty's public profile fields, with a `direction` label
/// the UI uses to sort the row into Incoming / Friends / Outgoing /
/// Blocked sections.
enum FriendDirection {
  incoming, // pending, I am the receiver
  outgoing, // pending, I am the sender
  mutual; // accepted or blocked (symmetric)

  static FriendDirection fromWire(String s) => switch (s) {
        'incoming' => FriendDirection.incoming,
        'outgoing' => FriendDirection.outgoing,
        _ => FriendDirection.mutual,
      };
}

enum FriendStatus {
  pending,
  accepted,
  blocked;

  static FriendStatus fromWire(String s) => switch (s) {
        'accepted' => FriendStatus.accepted,
        'blocked' => FriendStatus.blocked,
        _ => FriendStatus.pending,
      };
}

class FriendEntry {
  const FriendEntry({
    required this.friendshipId,
    required this.otherUserId,
    required this.username,
    required this.displayName,
    this.avatarKey,
    required this.level,
    required this.currentStreak,
    required this.status,
    required this.direction,
  });

  final String friendshipId;
  final String otherUserId;
  final String username;
  final String displayName;
  final String? avatarKey;
  final int level;
  final int currentStreak;
  final FriendStatus status;
  final FriendDirection direction;

  bool get isIncoming => direction == FriendDirection.incoming;
  bool get isOutgoing => direction == FriendDirection.outgoing;
  bool get isFriend => status == FriendStatus.accepted;
  bool get isBlocked => status == FriendStatus.blocked;

  factory FriendEntry.fromRpcRow(Map<String, dynamic> r) => FriendEntry(
        friendshipId: r['friendship_id'] as String,
        otherUserId: r['other_user_id'] as String,
        username: (r['username'] as String?) ?? '',
        displayName: (r['display_name'] as String?) ?? '',
        avatarKey: r['avatar_key'] as String?,
        level: (r['level'] as int?) ?? 1,
        currentStreak: (r['current_streak'] as int?) ?? 0,
        status: FriendStatus.fromWire((r['status'] as String?) ?? 'pending'),
        direction:
            FriendDirection.fromWire((r['direction'] as String?) ?? 'mutual'),
      );
}

/// Result row from `search_users_by_username`. Lighter than
/// [FriendEntry] — has no friendship state, since the user might not
/// have one with this person yet. Used by the typeahead screen.
class UsernameSearchResult {
  const UsernameSearchResult({
    required this.userId,
    required this.username,
    required this.displayName,
    this.avatarKey,
    required this.level,
  });

  final String userId;
  final String username;
  final String displayName;
  final String? avatarKey;
  final int level;

  factory UsernameSearchResult.fromRpcRow(Map<String, dynamic> r) =>
      UsernameSearchResult(
        userId: r['user_id'] as String,
        username: (r['username'] as String?) ?? '',
        displayName: (r['display_name'] as String?) ?? '',
        avatarKey: r['avatar_key'] as String?,
        level: (r['level'] as int?) ?? 1,
      );
}
