import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/supabase_client.dart';

/// Result type returned by every mutation. Keeps screens from
/// boilerplate try/catch — callers just check `ok` and surface
/// `errorMessage` if not.
typedef AuthResult = ({bool ok, String? errorMessage});

/// Thin wrapper over `Supabase.instance.client.auth`.
///
/// Static-only — there's exactly one auth state per app instance and
/// the SDK handles its own lifecycle. Callers can subscribe to
/// [authStateChanges] from any screen for reactive updates.
///
/// Every mutation returns an [AuthResult]. On failure, `errorMessage`
/// is the human-readable string from Supabase — already user-friendly
/// for the common cases ("Invalid login credentials", "Email not
/// confirmed", etc.). Don't show a snackbar with a stack trace.
///
/// Methods are no-ops with `errorMessage = 'socials not configured'`
/// when [SupabaseConfig.isConfigured] is false (dev machine without
/// a `.env`). That way the rest of the app keeps working in offline-
/// only mode and screens render a graceful "set up Supabase first"
/// state instead of crashing.
class AuthService {
  AuthService._();

  static GoTrueClient get _auth => SupabaseConfig.client.auth;

  // ─── Reactive surface ──────────────────────────────────────

  /// Stream of every auth-state transition (signed in, signed out,
  /// token refreshed, email verified, password recovered).
  /// Subscribe in `initState`, cancel in `dispose`.
  static Stream<AuthState> get authStateChanges {
    if (!SupabaseConfig.isConfigured) return const Stream.empty();
    return _auth.onAuthStateChange;
  }

  // ─── Snapshot getters ──────────────────────────────────────

  static bool get isConfigured => SupabaseConfig.isConfigured;

  static bool get isAuthenticated =>
      isConfigured && _auth.currentSession != null;

  static bool get isEmailVerified =>
      isAuthenticated && _auth.currentUser?.emailConfirmedAt != null;

  static String? get currentEmail => isConfigured ? _auth.currentUser?.email : null;

  static String? get currentUserId =>
      isConfigured ? _auth.currentUser?.id : null;

  // ─── Mutations ─────────────────────────────────────────────

  static Future<AuthResult> signUp({
    required String email,
    required String password,
  }) async {
    if (!isConfigured) {
      return (ok: false, errorMessage: 'Socials not configured.');
    }
    try {
      final response = await _auth.signUp(
        email: email.trim(),
        password: password,
        // Email confirmation deep-link target. Supabase appends the
        // recovery token as a fragment.
        emailRedirectTo: 'levelupirl://email-confirmed',
      );
      if (response.user == null) {
        return (ok: false, errorMessage: 'Sign-up did not complete. Try again.');
      }
      return (ok: true, errorMessage: null);
    } on AuthException catch (e) {
      return (ok: false, errorMessage: e.message);
    } catch (e) {
      return (ok: false, errorMessage: 'Unexpected error. Try again.');
    }
  }

  static Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    if (!isConfigured) {
      return (ok: false, errorMessage: 'Socials not configured.');
    }
    try {
      final response = await _auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      if (response.user == null) {
        return (ok: false, errorMessage: 'Sign-in failed. Try again.');
      }
      return (ok: true, errorMessage: null);
    } on AuthException catch (e) {
      return (ok: false, errorMessage: e.message);
    } catch (e) {
      return (ok: false, errorMessage: 'Unexpected error. Try again.');
    }
  }

  /// Destroys the local Supabase session token. **Does NOT touch local
  /// sqflite** — the user can keep training offline-only after this.
  /// They can sign back in any time to re-hydrate their cloud state.
  static Future<AuthResult> signOut() async {
    if (!isConfigured) {
      return (ok: true, errorMessage: null);
    }
    try {
      await _auth.signOut();
      return (ok: true, errorMessage: null);
    } on AuthException catch (e) {
      return (ok: false, errorMessage: e.message);
    } catch (e) {
      return (ok: false, errorMessage: 'Unexpected error. Try again.');
    }
  }

  /// Resends the verification email after sign-up. Supabase enforces
  /// its own rate-limit (default 60s between sends).
  static Future<AuthResult> resendVerification(String email) async {
    if (!isConfigured) {
      return (ok: false, errorMessage: 'Socials not configured.');
    }
    try {
      await _auth.resend(
        type: OtpType.signup,
        email: email.trim(),
        emailRedirectTo: 'levelupirl://email-confirmed',
      );
      return (ok: true, errorMessage: null);
    } on AuthException catch (e) {
      return (ok: false, errorMessage: e.message);
    } catch (e) {
      return (ok: false, errorMessage: 'Unexpected error. Try again.');
    }
  }

  /// Sends the "reset your password" email. Supabase's default
  /// template includes a deep link to `levelupirl://reset-password`
  /// which is handled by [ResetPasswordScreen] after deep-link parsing.
  static Future<AuthResult> sendPasswordReset(String email) async {
    if (!isConfigured) {
      return (ok: false, errorMessage: 'Socials not configured.');
    }
    try {
      await _auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: 'levelupirl://reset-password',
      );
      return (ok: true, errorMessage: null);
    } on AuthException catch (e) {
      return (ok: false, errorMessage: e.message);
    } catch (e) {
      return (ok: false, errorMessage: 'Unexpected error. Try again.');
    }
  }

  /// Updates the password — used by the password-reset deep-link
  /// landing screen after the user has been authenticated by Supabase
  /// via the recovery token in the email link.
  static Future<AuthResult> updatePassword(String newPassword) async {
    if (!isConfigured) {
      return (ok: false, errorMessage: 'Socials not configured.');
    }
    try {
      final response = await _auth.updateUser(
        UserAttributes(password: newPassword),
      );
      if (response.user == null) {
        return (ok: false, errorMessage: 'Could not update password.');
      }
      return (ok: true, errorMessage: null);
    } on AuthException catch (e) {
      return (ok: false, errorMessage: e.message);
    } catch (e) {
      return (ok: false, errorMessage: 'Unexpected error. Try again.');
    }
  }
}
