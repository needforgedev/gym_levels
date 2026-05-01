import '../models/friend_entry.dart';
import '../models/leaderboard_entry.dart';
import '../supabase/supabase_client.dart';
import 'auth_service.dart';
import 'friend_service.dart';

/// Read-side of the leaderboard. Returns the user's own row + their
/// accepted friends, ordered by the chosen [LeaderboardMetric].
///
/// Uses `public_profiles` directly — RLS already permits reading
/// rows where an accepted friendship exists between viewer and
/// target (003_rls.sql). Plus the viewer's own row.
///
/// One round-trip per tab switch. The friend list is sourced from
/// [FriendService.fullGraph] (cached locally via the call site if
/// needed) so we don't have to do a JOIN at the DB layer.
class LeaderboardService {
  LeaderboardService._();

  /// Fetch the ranked rows for [metric]. Includes the user's own
  /// row even if they have no friends yet, so the first-time
  /// experience isn't an empty list.
  static Future<List<LeaderboardEntry>> fetch(LeaderboardMetric metric) async {
    if (!AuthService.isAuthenticated) return const [];
    final me = AuthService.currentUserId!;

    // Friend user_ids whose status is 'accepted'. The fullGraph RPC
    // already filters declined / soft-deleted profiles for us.
    final graph = await FriendService.fullGraph();
    final friendIds = graph
        .where((g) => g.isFriend && g.direction == FriendDirection.mutual)
        .map((g) => g.otherUserId)
        .toList();

    final allIds = {me, ...friendIds}.toList();
    if (allIds.isEmpty) return const [];

    try {
      final response = await SupabaseConfig.client
          .from('public_profiles')
          .select(
            'user_id, username, display_name, avatar_key, '
            'level, total_xp, weekly_xp, monthly_xp, '
            'current_streak, longest_streak',
          )
          .inFilter('user_id', allIds)
          .filter('deleted_at', 'is', null)
          // Server-side ordering on the metric column. Ties broken by
          // total_xp then username so the ranking is stable across
          // re-fetches.
          .order(metric.column, ascending: false)
          .order('total_xp', ascending: false)
          .order('username', ascending: true);

      final rows = (response as List).cast<Map<String, dynamic>>();
      final out = <LeaderboardEntry>[];
      for (var i = 0; i < rows.length; i++) {
        final r = rows[i];
        out.add(LeaderboardEntry.fromRow(
          r,
          rank: i + 1,
          isMe: r['user_id'] == me,
        ));
      }
      return out;
    } catch (_) {
      return const [];
    }
  }
}
