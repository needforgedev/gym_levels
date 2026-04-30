import '../models/friend_entry.dart';
import '../services/auth_service.dart';
import '../supabase/supabase_client.dart';

typedef FriendActionResult = ({
  bool ok,
  bool alreadyExists,
  String? errorMessage,
});

/// Friend-graph operations against Supabase.
///
/// Reads go through the [list_my_friend_graph] RPC (single-call,
/// joins public_profiles for counterparty fields, bypasses RLS via
/// SECURITY DEFINER). Mutations (accept / decline / block / remove)
/// are direct UPDATE / DELETE — RLS policies in [003_rls.sql] gate
/// them per direction (receiver-only accept, either-side block, etc.).
///
/// Username search uses the existing [search_users_by_username] RPC
/// from [004_rpcs.sql] — debounced typeahead in [UsernameSearchScreen].
class FriendService {
  FriendService._();

  // ─── Reads ─────────────────────────────────────────────────────

  /// Full friend graph: incoming requests, accepted friends, outgoing
  /// requests, blocked counterparties — in display-ready order. The
  /// RPC orders rows so the client renders without re-sorting.
  static Future<List<FriendEntry>> fullGraph() async {
    if (!AuthService.isAuthenticated) return const [];
    try {
      final response =
          await SupabaseConfig.client.rpc('list_my_friend_graph');
      if (response is! List) return const [];
      return response
          .map((r) => FriendEntry.fromRpcRow(
                (r as Map).cast<String, dynamic>(),
              ))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Username typeahead. Server enforces a 3-character minimum + a
  /// rate limit (30/min/user). Returns an empty list on rejection.
  static Future<List<UsernameSearchResult>> searchByUsername(
    String prefix,
  ) async {
    if (!AuthService.isAuthenticated) return const [];
    if (prefix.trim().length < 3) return const [];
    try {
      final response = await SupabaseConfig.client.rpc(
        'search_users_by_username',
        params: {'prefix': prefix.trim()},
      );
      if (response is! List) return const [];
      return response
          .map((r) => UsernameSearchResult.fromRpcRow(
                (r as Map).cast<String, dynamic>(),
              ))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  // ─── Mutations ─────────────────────────────────────────────────

  /// Insert `(sender_id = me, receiver_id = otherUserId, status =
  /// pending)`. Idempotent against the unique-pair index.
  static Future<FriendActionResult> sendRequest(String otherUserId) async {
    final me = AuthService.currentUserId;
    if (me == null) {
      return (
        ok: false,
        alreadyExists: false,
        errorMessage: 'Not signed in.',
      );
    }
    if (me == otherUserId) {
      return (
        ok: false,
        alreadyExists: false,
        errorMessage: 'Cannot add yourself.',
      );
    }
    try {
      await SupabaseConfig.client.from('friendships').insert({
        'sender_id': me,
        'receiver_id': otherUserId,
      });
      return (ok: true, alreadyExists: false, errorMessage: null);
    } catch (e) {
      final s = e.toString();
      if (s.contains('23505') || s.contains('duplicate key')) {
        return (ok: true, alreadyExists: true, errorMessage: null);
      }
      return (
        ok: false,
        alreadyExists: false,
        errorMessage: 'Could not send request.',
      );
    }
  }

  /// Receiver accepts a pending request. RLS allows this only when
  /// `receiver_id = auth.uid()` AND the incoming row is currently
  /// `pending`.
  static Future<FriendActionResult> accept(String friendshipId) =>
      _updateStatus(friendshipId, 'accepted');

  /// Receiver declines a pending request. The row stays in the table
  /// (status='declined') but [list_my_friend_graph] filters declined
  /// rows out, so it disappears from the UI.
  static Future<FriendActionResult> decline(String friendshipId) =>
      _updateStatus(friendshipId, 'declined');

  /// Either side blocks. RLS policy (`status='blocked' AND (sender_id
  /// = auth.uid() OR receiver_id = auth.uid())`) lets either party
  /// trigger the transition.
  static Future<FriendActionResult> block(String friendshipId) =>
      _updateStatus(friendshipId, 'blocked');

  /// Remove a friendship row entirely. Either side may delete (RLS
  /// `friendships_delete` allows both). After deletion, the row can
  /// be re-INSERTed via [sendRequest].
  static Future<FriendActionResult> remove(String friendshipId) async {
    if (!AuthService.isAuthenticated) {
      return (
        ok: false,
        alreadyExists: false,
        errorMessage: 'Not signed in.',
      );
    }
    try {
      await SupabaseConfig.client
          .from('friendships')
          .delete()
          .eq('id', friendshipId);
      return (ok: true, alreadyExists: false, errorMessage: null);
    } catch (_) {
      return (
        ok: false,
        alreadyExists: false,
        errorMessage: 'Could not remove friend.',
      );
    }
  }

  static Future<FriendActionResult> _updateStatus(
    String friendshipId,
    String newStatus,
  ) async {
    if (!AuthService.isAuthenticated) {
      return (
        ok: false,
        alreadyExists: false,
        errorMessage: 'Not signed in.',
      );
    }
    try {
      await SupabaseConfig.client
          .from('friendships')
          .update({'status': newStatus})
          .eq('id', friendshipId);
      return (ok: true, alreadyExists: false, errorMessage: null);
    } catch (_) {
      return (
        ok: false,
        alreadyExists: false,
        errorMessage: 'Could not update status.',
      );
    }
  }
}
