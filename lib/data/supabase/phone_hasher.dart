import 'dart:convert';

import 'package:crypto/crypto.dart';

/// SHA-256 hashing for phone numbers in the contact-match flow.
///
/// Both the user's own phone (stored on `public_profiles.phone_hash`)
/// and every contact's phone (sent to `find_users_by_phone_hashes`)
/// flow through [PhoneHasher.hash]. The same salt must be used in
/// both places, otherwise the hashes won't match across users.
///
/// **The salt is bundled with the client, not server-side.** It
/// arrives via `--dart-define=PHONE_HASH_SALT=...` at build time, so
/// it ships inside every installed app. A determined attacker who
/// reverses the binary can rebuild rainbow tables — the salt's job
/// is making a casual database leak less catastrophic, not defending
/// against motivated adversaries. See `socials_plan.md` for the full
/// privacy-model discussion. The same value must be stored as a
/// reference in Supabase Vault so the contact-match RPC can verify
/// hashes line up across deploys.
class PhoneHasher {
  PhoneHasher._();

  // Compile-time constant from --dart-define. Empty string when not
  // provided.
  static const String _salt = String.fromEnvironment('PHONE_HASH_SALT');

  /// Whether the salt has been configured. False when no
  /// `--dart-define=PHONE_HASH_SALT=...` was passed at build time
  /// (e.g. in tests or offline-only dev runs). Callers should guard
  /// with this before relying on contact-match behaviour.
  static bool get isConfigured => _salt.isNotEmpty;

  /// Hashes a phone number. Returns the hex-encoded SHA-256 of
  /// `(normalizedPhone || salt)`. Throws [StateError] if the salt
  /// isn't configured — call [isConfigured] first.
  ///
  /// `phone` should already be in E.164 format (`+919876543210`). Use
  /// [normalizeToE164] to coerce loosely-formatted input.
  static String hash(String phone) {
    if (_salt.isEmpty) {
      throw StateError(
        'PHONE_HASH_SALT not configured — pass via --dart-define at '
        'build time. Cannot hash phone numbers.',
      );
    }
    final bytes = utf8.encode('$phone$_salt');
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
  ///
  /// Use [normalizeContactPhone] when scanning the address book —
  /// most users save numbers in national format ("9876543210") on
  /// their own device and rely on the OS to add the country code at
  /// dial time. The strict variant misses every one of those.
  static String? normalizeToE164(String input) {
    final stripped = input.replaceAll(RegExp(r'[\s\-\(\)\.]'), '');
    if (stripped.isEmpty) return null;
    if (!stripped.startsWith('+')) return null;
    final digitsOnly = stripped.substring(1);
    if (!RegExp(r'^[0-9]{7,15}$').hasMatch(digitsOnly)) return null;
    return '+$digitsOnly';
  }

  /// Lenient E.164 normalization for address-book entries. Falls back
  /// to [defaultDialCode] (e.g. `'+91'`) when the contact lacks a
  /// country prefix.
  ///
  /// Handles the four formats real phones save numbers in:
  ///   `+91 98765 43210`     → `+919876543210` (international)
  ///   `0091 98765 43210`    → `+919876543210` (00 = international prefix
  ///                                              in IN / EU / etc.)
  ///   `9876543210`          → `+919876543210` (national, prepend default)
  ///   `09876543210`         → `+919876543210` (national w/ trunk-0,
  ///                                              strip + prepend)
  ///
  /// Returns null when the input is empty, has no digits, or the
  /// digit count after normalization doesn't fit E.164 (7–15 digits).
  static String? normalizeContactPhone(
    String input, {
    required String? defaultDialCode,
  }) {
    var stripped = input.replaceAll(RegExp(r'[\s\-\(\)\.]'), '');
    if (stripped.isEmpty) return null;

    // International prefix variants → '+'.
    if (stripped.startsWith('00')) {
      stripped = '+${stripped.substring(2)}';
    }

    // Already E.164. Validate and return.
    if (stripped.startsWith('+')) {
      final digitsOnly = stripped.substring(1);
      if (!RegExp(r'^[0-9]{7,15}$').hasMatch(digitsOnly)) return null;
      return '+$digitsOnly';
    }

    // From here, the input is national-format. Need a fallback dial
    // code; without one we can't safely promote it to E.164.
    if (defaultDialCode == null || defaultDialCode.isEmpty) return null;
    var dial = defaultDialCode.startsWith('+')
        ? defaultDialCode
        : '+$defaultDialCode';

    // Strip a single leading trunk '0' that's used domestically in
    // IN / UK / DE / etc. but isn't part of the international form.
    var nationalDigits = stripped.replaceAll(RegExp(r'[^0-9]'), '');
    if (nationalDigits.startsWith('0')) {
      nationalDigits = nationalDigits.substring(1);
    }

    final candidate = '$dial$nationalDigits';
    final digitsOnly = candidate.substring(1);
    if (!RegExp(r'^[0-9]{7,15}$').hasMatch(digitsOnly)) return null;
    return candidate;
  }

  /// Derive the country dial code (e.g. `'+91'`) from a stored E.164
  /// phone number. Uses a longest-prefix match against
  /// [knownDialCodes] — covers the 30 countries our phone screen
  /// supports. Returns null for unrecognised prefixes (caller should
  /// degrade to strict normalization).
  static String? extractDialCode(String e164) {
    if (!e164.startsWith('+')) return null;
    // Try 4-digit, 3-digit, 2-digit, then 1-digit prefixes (longest
    // first wins — e.g. '+1' vs. '+1-XXX' is ambiguous, but our list
    // doesn't have +1XXX entries, so the 1-digit match resolves).
    for (final len in const [4, 3, 2, 1]) {
      if (e164.length < 1 + len) continue;
      final candidate = e164.substring(0, 1 + len);
      if (knownDialCodes.contains(candidate)) return candidate;
    }
    return null;
  }

  /// Dial codes the phone screen supports. Used by [extractDialCode]
  /// so contact-match can reverse-derive the user's country at scan
  /// time without a separate stored column.
  static const Set<String> knownDialCodes = {
    '+1',   // US, Canada
    '+7',   // Russia, Kazakhstan
    '+20',  // Egypt
    '+27',  // South Africa
    '+33',  // France
    '+34',  // Spain
    '+39',  // Italy
    '+44',  // United Kingdom
    '+49',  // Germany
    '+52',  // Mexico
    '+55',  // Brazil
    '+60',  // Malaysia
    '+61',  // Australia
    '+62',  // Indonesia
    '+63',  // Philippines
    '+64',  // New Zealand
    '+65',  // Singapore
    '+81',  // Japan
    '+82',  // South Korea
    '+86',  // China
    '+91',  // India
    '+92',  // Pakistan
    '+94',  // Sri Lanka
    '+234', // Nigeria
    '+254', // Kenya
    '+353', // Ireland
    '+880', // Bangladesh
    '+966', // Saudi Arabia
    '+971', // United Arab Emirates
    '+977', // Nepal
  };
}
