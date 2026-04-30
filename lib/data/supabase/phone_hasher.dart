import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// SHA-256 hashing for phone numbers in the contact-match flow.
///
/// Both the user's own phone (stored on `public_profiles.phone_hash`)
/// and every contact's phone (sent to `find_users_by_phone_hashes`)
/// flow through [PhoneHasher.hash]. The same salt must be used in
/// both places, otherwise the hashes won't match across users.
///
/// The salt comes from `PHONE_HASH_SALT` in `.env`. It must be the
/// same value as the `PHONE_HASH_SALT` secret stored in Supabase
/// Vault (admin reference; the server doesn't actually re-compute the
/// hash — it just compares the string).
class PhoneHasher {
  PhoneHasher._();

  static String? get _salt => dotenv.env['PHONE_HASH_SALT'];

  /// Whether the salt has been configured. False on a dev machine
  /// without a `.env`. Callers should guard with this before relying
  /// on contact-match behaviour.
  static bool get isConfigured => (_salt ?? '').isNotEmpty;

  /// Hashes a phone number. Returns the hex-encoded SHA-256 of
  /// `(normalizedPhone || salt)`. Throws [StateError] if the salt
  /// isn't configured — call [isConfigured] first.
  ///
  /// `phone` should already be in E.164 format (`+919876543210`). Use
  /// [normalizeToE164] to coerce loosely-formatted input.
  static String hash(String phone) {
    final salt = _salt;
    if (salt == null || salt.isEmpty) {
      throw StateError(
        'PHONE_HASH_SALT not set in .env — cannot hash phone numbers.',
      );
    }
    final bytes = utf8.encode('$phone$salt');
    return sha256.convert(bytes).toString();
  }

  /// Best-effort E.164 normalization. Strips spaces, hyphens,
  /// parentheses, and dots; ensures a leading `+`. If the input has
  /// neither a `+` nor a leading country code we can't safely guess,
  /// so we return null and the caller should reject it.
  ///
  /// Examples:
  ///   `+91 98765 43210`    → `+919876543210`
  ///   `(98765) 43210`      → null (no country code)
  ///   `91-9876543210`      → null (ambiguous; require explicit `+`)
  ///   `+91-98765-43210`    → `+919876543210`
  static String? normalizeToE164(String input) {
    final stripped = input.replaceAll(RegExp(r'[\s\-\(\)\.]'), '');
    if (stripped.isEmpty) return null;
    if (!stripped.startsWith('+')) return null;
    final digitsOnly = stripped.substring(1);
    if (!RegExp(r'^[0-9]{7,15}$').hasMatch(digitsOnly)) return null;
    return '+$digitsOnly';
  }
}
