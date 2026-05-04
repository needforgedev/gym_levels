import 'package:flutter_contacts/flutter_contacts.dart';

import '../models/contact_match.dart';
import '../supabase/phone_hasher.dart';
import '../supabase/supabase_client.dart';
import 'public_profile_service.dart';

/// Outcome bundle returned by [ContactMatchService.scanAndMatch].
///
/// Captures both the success path (matches list) and the soft-failure
/// signals the UI needs to render distinct states without try/catch:
/// permission denied, no usable contacts, RPC rate-limited, etc.
typedef ContactMatchResult = ({
  bool ok,
  List<ContactMatch> matches,
  int contactsScanned,
  int contactsSkippedNoCountryCode,
  String? errorMessage,
  bool permissionDenied,
});

/// End-to-end contact-match flow:
///   1. Request the OS contacts permission (read-only) via the
///      flutter_contacts 2.x `permissions` sub-API.
///   2. Read every contact + phone, normalize to E.164.
///   3. SHA-256-hash each with the server salt (PhoneHasher).
///   4. POST the hashes to `find_users_by_phone_hashes` RPC.
///   5. Return the matched profiles (excluding the current user;
///      the server already filters that out).
///
/// Privacy posture: phone numbers never leave the device — only their
/// salted SHA-256 hashes are sent. The same salt is used on the user's
/// own row when AuthScreen's Join Now form persists their phone, so
/// cross-user hash equality is the matching criterion.
class ContactMatchService {
  ContactMatchService._();

  /// Maximum hashes per RPC call. Server clamps at 5000 (see
  /// `find_users_by_phone_hashes` in 004_rpcs.sql); we batch under
  /// that to leave headroom and keep individual round-trips small.
  static const int _maxHashesPerCall = 1000;

  /// Run the full flow. Safe to call repeatedly — the server's rate
  /// limiter is the only constraint (5 calls / hour / user).
  ///
  /// Returns a [ContactMatchResult]. The caller renders one of three
  /// states from the result: error/denied banner, empty-state with
  /// invite-link CTA, or the matched-friends list.
  static Future<ContactMatchResult> scanAndMatch() async {
    if (!SupabaseConfig.isConfigured) {
      return (
        ok: false,
        matches: const <ContactMatch>[],
        contactsScanned: 0,
        contactsSkippedNoCountryCode: 0,
        errorMessage: 'Socials not configured.',
        permissionDenied: false,
      );
    }
    if (!PhoneHasher.isConfigured) {
      return (
        ok: false,
        matches: const <ContactMatch>[],
        contactsScanned: 0,
        contactsSkippedNoCountryCode: 0,
        errorMessage: 'Hash salt not configured.',
        permissionDenied: false,
      );
    }

    // Triggers the system permission prompt on first call. Subsequent
    // calls are silent and return the cached grant. iOS 18+ may
    // return `limited` (partial-access) — treat it as granted; we'll
    // get whichever contacts the user chose to share.
    final status = await FlutterContacts.permissions.request(
      PermissionType.read,
    );
    final granted = status == PermissionStatus.granted ||
        status == PermissionStatus.limited;
    if (!granted) {
      return (
        ok: false,
        matches: const <ContactMatch>[],
        contactsScanned: 0,
        contactsSkippedNoCountryCode: 0,
        errorMessage: 'Contacts permission denied.',
        permissionDenied: true,
      );
    }

    // Read the user's own phone to derive their country dial code —
    // contacts saved without a country prefix get promoted using the
    // user's country as fallback. Without this, address-book entries
    // stored in national format (the default on most phones in
    // single-country regions) are silently skipped.
    //
    // Phone lives in `private_profiles` since migration 012 (P0-3),
    // so we read via the dedicated [PublicProfileService.getMyPhone]
    // helper instead of the now-public profile row.
    String? defaultDialCode;
    final myPhone = await PublicProfileService.getMyPhone();
    if (myPhone != null && myPhone.isNotEmpty) {
      defaultDialCode = PhoneHasher.extractDialCode(myPhone);
    }

    // Only request the `phone` property — keeps the read fast on
    // devices with thousands of contacts and avoids loading photos /
    // emails / postal addresses we'd never use.
    final contacts = await FlutterContacts.getAll(
      properties: {ContactProperty.phone},
    );

    final hashes = <String>{};
    int skippedNoCountryCode = 0;
    for (final c in contacts) {
      for (final phone in c.phones) {
        final raw = phone.number.trim();
        if (raw.isEmpty) continue;
        // Try strict first (covers the contact-already-E.164 case),
        // then lenient with the user's country as fallback. The
        // strict-first path also preserves correct hashing for
        // contacts that have a country code different from the
        // user's own — we don't accidentally re-stamp them with the
        // user's country.
        final strict = PhoneHasher.normalizeToE164(raw);
        final e164 = strict ??
            PhoneHasher.normalizeContactPhone(
              raw,
              defaultDialCode: defaultDialCode,
            );
        if (e164 == null) {
          skippedNoCountryCode++;
          continue;
        }
        hashes.add(PhoneHasher.hash(e164));
      }
    }

    if (hashes.isEmpty) {
      return (
        ok: true,
        matches: const <ContactMatch>[],
        contactsScanned: contacts.length,
        contactsSkippedNoCountryCode: skippedNoCountryCode,
        errorMessage: null,
        permissionDenied: false,
      );
    }

    // Batch the RPC if we exceed the per-call cap (rare on phones,
    // common on accounts that imported a CRM).
    final hashList = hashes.toList();
    final matches = <ContactMatch>[];
    try {
      for (var i = 0; i < hashList.length; i += _maxHashesPerCall) {
        final end = (i + _maxHashesPerCall).clamp(0, hashList.length);
        final batch = hashList.sublist(i, end);
        final response = await SupabaseConfig.client.rpc<List<dynamic>>(
          'find_users_by_phone_hashes',
          params: {'hashes': batch},
        );
        for (final row in response) {
          if (row is Map<String, dynamic>) {
            matches.add(ContactMatch.fromRpcRow(row));
          } else if (row is Map) {
            matches.add(
              ContactMatch.fromRpcRow(row.cast<String, dynamic>()),
            );
          }
        }
      }
    } catch (e) {
      return (
        ok: false,
        matches: matches,
        contactsScanned: contacts.length,
        contactsSkippedNoCountryCode: skippedNoCountryCode,
        errorMessage: _humanError(e),
        permissionDenied: false,
      );
    }

    // De-dup in case the same user is matched twice from two synonymous
    // phone entries (work + personal both pointing to the same E.164).
    final seen = <String>{};
    final unique = <ContactMatch>[];
    for (final m in matches) {
      if (seen.add(m.userId)) unique.add(m);
    }

    return (
      ok: true,
      matches: unique,
      contactsScanned: contacts.length,
      contactsSkippedNoCountryCode: skippedNoCountryCode,
      errorMessage: null,
      permissionDenied: false,
    );
  }

  static String _humanError(Object e) {
    final s = e.toString();
    if (s.contains('rate_limit_exceeded')) {
      return 'Too many tries. Try again in an hour.';
    }
    if (s.contains('too_many_hashes')) {
      return 'Address book too large. Skipping match for now.';
    }
    return 'Could not reach the server. Try again.';
  }
}
