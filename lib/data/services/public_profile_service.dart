import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/phone_hasher.dart';
import '../supabase/supabase_client.dart';
import 'auth_service.dart';

/// Result for username availability checks.
typedef UsernameCheck = ({bool available, String? reason});

/// CRUD over the cloud `public_profiles` table for the current user.
///
/// Talks directly to Supabase Postgres (RLS protects against accessing
/// anyone else's row). All mutations use UPSERT keyed on `user_id` so
/// the row is created on first push and updated thereafter.
///
/// Methods return the same `(bool ok, String? errorMessage)` record
/// shape as [AuthService] for screen-side ergonomics.
class PublicProfileService {
  PublicProfileService._();

  static SupabaseClient get _client => SupabaseConfig.client;

  /// Live availability check for the Pick-Username screen. Calls the
  /// `check_username_available` RPC, which:
  ///   - Validates the format (3-20 chars, [a-z0-9_])
  ///   - Checks the reserved_usernames blocklist
  ///   - Checks for case-insensitive collision with existing profiles
  ///
  /// Returns `(available: false, reason: 'invalid_format' | 'reserved'
  /// | 'taken')` on failure, or `(available: true, reason: null)` on
  /// success.
  ///
  /// Rate-limited server-side at 30 calls / minute / user.
  static Future<UsernameCheck> checkUsernameAvailable(String candidate) async {
    if (!AuthService.isAuthenticated) {
      return (available: false, reason: 'not_authenticated');
    }
    try {
      final rows = await _client.rpc(
        'check_username_available',
        params: {'candidate': candidate},
      ) as List<dynamic>;
      if (rows.isEmpty) return (available: false, reason: 'unknown');
      final row = rows.first as Map<String, dynamic>;
      return (
        available: row['available'] as bool? ?? false,
        reason: row['reason'] as String?,
      );
    } on PostgrestException catch (e) {
      return (available: false, reason: e.message);
    } catch (_) {
      return (available: false, reason: 'unexpected');
    }
  }

  /// Upserts the public_profiles row for the authenticated user.
  ///
  /// Internally branches on whether the row already exists:
  ///   - **Exists:** `UPDATE` only the supplied columns. Untouched
  ///     columns (e.g. existing username when called from /phone)
  ///     are preserved.
  ///   - **Doesn't exist:** `INSERT` — but `username` and
  ///     `display_name` are required (the table enforces NOT NULL).
  ///     If the caller didn't supply them, returns an error so the
  ///     UI can route the user back through Pick-Username first.
  ///
  /// We deliberately avoid PostgREST's `.upsert()` here — its default
  /// behaviour treats missing payload columns as `NULL` during the
  /// UPDATE half, which clobbers username/display_name when called
  /// from /phone with only `{phone, phone_hash}`. The explicit
  /// SELECT-then-UPDATE-or-INSERT pattern is clearer and safer.
  ///
  /// Phone, when provided, must already be in E.164 format. The
  /// matching `phone_hash` is computed via [PhoneHasher] before being
  /// pushed.
  static Future<({bool ok, String? errorMessage})> upsertProfile({
    String? username,
    String? displayName,
    String? phoneE164,
  }) async {
    if (!AuthService.isAuthenticated) {
      return (ok: false, errorMessage: 'Not signed in.');
    }
    final userId = AuthService.currentUserId!;

    final fields = <String, dynamic>{};
    if (username != null) fields['username'] = username.toLowerCase();
    if (displayName != null) fields['display_name'] = displayName;
    if (phoneE164 != null) {
      fields['phone'] = phoneE164;
      if (PhoneHasher.isConfigured) {
        fields['phone_hash'] = PhoneHasher.hash(phoneE164);
      }
    }

    if (fields.isEmpty) return (ok: true, errorMessage: null);

    try {
      // Does the row exist already? Single round-trip to find out.
      final existing = await _client
          .from('public_profiles')
          .select('user_id')
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        // UPDATE: only the provided columns; everything else preserved.
        await _client
            .from('public_profiles')
            .update(fields)
            .eq('user_id', userId);
      } else {
        // INSERT: requires username + display_name (NOT NULL columns).
        if (fields['username'] == null || fields['display_name'] == null) {
          return (
            ok: false,
            errorMessage:
                'Pick a username first — your profile row hasn\'t been '
                'created yet.',
          );
        }
        fields['user_id'] = userId;
        await _client.from('public_profiles').insert(fields);
      }
      return (ok: true, errorMessage: null);
    } on PostgrestException catch (e) {
      return (ok: false, errorMessage: e.message);
    } catch (_) {
      return (ok: false, errorMessage: 'Unexpected error. Try again.');
    }
  }

  /// Fetches the authenticated user's `public_profiles` row, or null
  /// if it hasn't been created yet (i.e. the user signed up but
  /// hasn't completed the username + phone collection step).
  static Future<Map<String, dynamic>?> getMyProfile() async {
    if (!AuthService.isAuthenticated) return null;
    final userId = AuthService.currentUserId!;
    try {
      final row = await _client
          .from('public_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      return row;
    } catch (_) {
      return null;
    }
  }
}
