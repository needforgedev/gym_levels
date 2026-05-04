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
  /// Callable pre-auth — the Join Now form on [AuthScreen] runs this
  /// while the user is still anonymous. See migration
  /// `010_username_check_public.sql` for the matching server-side
  /// grant.
  static Future<UsernameCheck> checkUsernameAvailable(String candidate) async {
    if (!SupabaseConfig.isConfigured) {
      return (available: false, reason: 'not_configured');
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

  /// Upserts the authenticated user's profile rows.
  ///
  /// Writes split across two tables (P0-3, migration 012):
  ///   - `public_profiles` — username + display_name (friend-readable)
  ///   - `private_profiles` — phone + phone_hash (owner-readable only)
  ///
  /// Internally branches on whether each row already exists:
  ///   - **Exists:** `UPDATE` only the supplied columns. Untouched
  ///     columns are preserved.
  ///   - **Doesn't exist (public_profiles):** `INSERT` — but
  ///     `username` and `display_name` are required (NOT NULL on the
  ///     table). If the caller didn't supply them, returns an error
  ///     so the UI can route the user through Pick-Username first.
  ///   - **Doesn't exist (private_profiles):** `INSERT` with whatever
  ///     phone fields were supplied; both columns are nullable.
  ///
  /// We deliberately avoid PostgREST's `.upsert()` — its default
  /// behaviour treats missing payload columns as `NULL` during the
  /// UPDATE half, which clobbers untouched fields. The explicit
  /// SELECT-then-UPDATE-or-INSERT pattern is clearer and safer.
  ///
  /// Phone, when provided, must already be in E.164 format. The
  /// matching `phone_hash` is computed via [PhoneHasher] before
  /// being pushed.
  static Future<({bool ok, String? errorMessage})> upsertProfile({
    String? username,
    String? displayName,
    String? phoneE164,
  }) async {
    if (!AuthService.isAuthenticated) {
      return (ok: false, errorMessage: 'Not signed in.');
    }
    final userId = AuthService.currentUserId!;

    // Split incoming fields by destination table.
    final publicFields = <String, dynamic>{};
    if (username != null) publicFields['username'] = username.toLowerCase();
    if (displayName != null) publicFields['display_name'] = displayName;

    final privateFields = <String, dynamic>{};
    if (phoneE164 != null) {
      privateFields['phone'] = phoneE164;
      if (PhoneHasher.isConfigured) {
        privateFields['phone_hash'] = PhoneHasher.hash(phoneE164);
      }
    }

    if (publicFields.isEmpty && privateFields.isEmpty) {
      return (ok: true, errorMessage: null);
    }

    try {
      if (publicFields.isNotEmpty) {
        final existing = await _client
            .from('public_profiles')
            .select('user_id')
            .eq('user_id', userId)
            .maybeSingle();

        if (existing != null) {
          await _client
              .from('public_profiles')
              .update(publicFields)
              .eq('user_id', userId);
        } else {
          // INSERT: username + display_name are NOT NULL.
          if (publicFields['username'] == null ||
              publicFields['display_name'] == null) {
            return (
              ok: false,
              errorMessage:
                  'Pick a username first — your profile row hasn\'t '
                  'been created yet.',
            );
          }
          publicFields['user_id'] = userId;
          await _client.from('public_profiles').insert(publicFields);
        }
      }

      if (privateFields.isNotEmpty) {
        final existingPriv = await _client
            .from('private_profiles')
            .select('user_id')
            .eq('user_id', userId)
            .maybeSingle();

        if (existingPriv != null) {
          await _client
              .from('private_profiles')
              .update(privateFields)
              .eq('user_id', userId);
        } else {
          privateFields['user_id'] = userId;
          await _client.from('private_profiles').insert(privateFields);
        }
      }

      return (ok: true, errorMessage: null);
    } on PostgrestException catch (e) {
      // 23505 = unique_violation. The TOCTOU window between the RPC
      // availability check and our INSERT is small but real — surface
      // a friendly message so the user retries with a different name
      // instead of seeing the raw Postgres error.
      if (e.code == '23505' ||
          e.message.toLowerCase().contains('duplicate key') ||
          e.message.toLowerCase().contains('unique')) {
        return (
          ok: false,
          errorMessage: 'That handle was just taken. Pick another.',
        );
      }
      return (ok: false, errorMessage: e.message);
    } catch (_) {
      return (ok: false, errorMessage: 'Unexpected error. Try again.');
    }
  }

  /// Fetches the authenticated user's `public_profiles` row, or null
  /// if it hasn't been created yet. Note: this no longer contains
  /// `phone` / `phone_hash` (those moved to `private_profiles` in
  /// migration 012). Use [getMyPhone] when you need the raw phone.
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

  /// Fetches the authenticated user's own raw phone number (E.164).
  /// Returns null if not signed in, no row exists, or phone wasn't
  /// set during onboarding.
  ///
  /// Reads from `private_profiles` — RLS only allows the row owner
  /// to read their own row, so this is the only sanctioned path to
  /// the raw value. Used by [ContactMatchService] to derive the
  /// user's country dial code at scan time.
  static Future<String?> getMyPhone() async {
    if (!AuthService.isAuthenticated) return null;
    final userId = AuthService.currentUserId!;
    try {
      final row = await _client
          .from('private_profiles')
          .select('phone')
          .eq('user_id', userId)
          .maybeSingle();
      return row?['phone'] as String?;
    } catch (_) {
      return null;
    }
  }
}
