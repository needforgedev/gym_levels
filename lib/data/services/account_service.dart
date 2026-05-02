import '../supabase/supabase_client.dart';
import 'auth_service.dart';
import 'player_service.dart';

/// Result for account-management actions. `ok = true` only if the
/// requested operation completed end-to-end (server + local where
/// applicable). `errorMessage` carries a user-presentable string.
typedef AccountResult = ({bool ok, String? errorMessage});

/// Account-level destructive flows that span Supabase + local sqflite.
///
/// Sign-out lives on [AuthService] because it's an auth-only concern;
/// account-deletion needs the cloud RPC + an auth sign-out + a local
/// wipe in a specific order, which justifies a dedicated entry point.
class AccountService {
  AccountService._();

  /// Permanently deletes the user's cloud + local data.
  ///
  /// Order:
  ///   1. `delete_my_account` RPC — cascades through every cloud_*
  ///      table + friendships + public_profiles + auth.users. This is
  ///      the irreversible step. If it fails we abort and leave the
  ///      local DB untouched so the user can retry.
  ///   2. [AuthService.signOut] — drops the session token, clears the
  ///      outbox + sync state.
  ///   3. [PlayerService.deleteAll] — wipes the local sqflite domain
  ///      rows. The exercise catalog stays.
  ///
  /// Returns `(ok: false, ...)` if Supabase isn't configured or the
  /// RPC call throws — in either case the local DB is left intact.
  static Future<AccountResult> deleteAccount() async {
    if (!SupabaseConfig.isConfigured) {
      return (
        ok: false,
        errorMessage: 'Cloud not configured — cannot delete server data.',
      );
    }
    if (!AuthService.isAuthenticated) {
      return (ok: false, errorMessage: 'Not signed in.');
    }

    try {
      await SupabaseConfig.client.rpc('delete_my_account');
    } catch (e) {
      return (
        ok: false,
        errorMessage:
            'Could not delete your account on the server. Try again.',
      );
    }

    // Server side gone. Drop the token + outbox + sync state. Failures
    // here aren't user-actionable — the cloud row is already deleted —
    // so swallow and continue to the local wipe.
    await AuthService.signOut();
    await PlayerService.deleteAll();

    return (ok: true, errorMessage: null);
  }
}
