import '../services/auth_service.dart';
import '../supabase/supabase_client.dart';

typedef FriendActionResult = ({
  bool ok,
  bool alreadyExists,
  String? errorMessage,
});

/// Minimal friendship operations for S4 — just enough to send a
/// pending request from the "Friends found" screen. Full graph
/// (accept / decline / block / remove) lands in S5.
///
/// RLS clamps every mutation: INSERT requires `sender_id = auth.uid()`
/// and `status = 'pending'`. The client never has to set those
/// explicitly — Postgres defaults take care of `status`, and we send
/// `sender_id` as the current user.
class FriendService {
  FriendService._();

  /// Insert a friendship row with `(sender_id = me, receiver_id =
  /// otherUserId, status = 'pending')`.
  ///
  /// Idempotent against the UNIQUE pair index on `(LEAST, GREATEST)` —
  /// re-sending the same request returns `alreadyExists: true` rather
  /// than an error, so the UI can flip the button state regardless.
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
        // status defaults to 'pending' on the server.
      });
      return (ok: true, alreadyExists: false, errorMessage: null);
    } catch (e) {
      // 23505 = unique_violation; the pair already has a friendship
      // row in some state. Surface as `alreadyExists` rather than an
      // error so the UI can render "Sent ✓" or "Friends".
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
}
