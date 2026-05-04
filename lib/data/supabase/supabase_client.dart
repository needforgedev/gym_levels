import 'package:supabase_flutter/supabase_flutter.dart';

/// Initializes the Supabase client and exposes the singleton.
///
/// **Config delivery (P0-2):** values arrive via `--dart-define` at
/// build time, embedded as `String.fromEnvironment` constants. Nothing
/// is read from disk at runtime, and nothing is bundled as a separate
/// asset — so a release APK / IPA cannot leak credentials via an
/// extracted `.env` file.
///
/// Build commands look like:
///
/// ```bash
/// # Local dev — use the Makefile so .env values get translated into
/// # --dart-define flags automatically.
/// make run                          # equivalent: flutter run --dart-define=PROJECT_URL=... --dart-define=PUBLISHABLE_KEY=... --dart-define=PHONE_HASH_SALT=...
///
/// # Production build (CI provides the values from a secret store).
/// flutter build apk --release \
///   --dart-define=PROJECT_URL=https://<ref>.supabase.co \
///   --dart-define=PUBLISHABLE_KEY=sb_publishable_... \
///   --dart-define=PHONE_HASH_SALT=<32-byte-hex>
/// ```
///
/// The publishable key is safe to ship — it's RLS-clamped on the
/// database side. The `service_role` key (which bypasses RLS) is
/// never put into either dart-defines or `.env`.
class SupabaseConfig {
  SupabaseConfig._();

  // Compile-time constants from --dart-define. Empty string when not
  // provided; in that case the app runs in offline-only mode and
  // every Supabase-dependent feature is gated by [isConfigured].
  static const String _projectUrl = String.fromEnvironment('PROJECT_URL');
  static const String _publishableKey =
      String.fromEnvironment('PUBLISHABLE_KEY');

  static bool _initialized = false;

  /// Whether the app has valid Supabase credentials. False when
  /// `--dart-define` values weren't passed at build time, and false
  /// in any test that doesn't call [initialize] — in those cases we
  /// degrade gracefully (no socials, no leaderboard) and the rest
  /// of the app keeps working.
  ///
  /// Pure getter — no I/O, no env-file reads, safe to call from any
  /// thread or test context.
  static bool get isConfigured =>
      _initialized && _projectUrl.isNotEmpty && _publishableKey.isNotEmpty;

  /// Initializes Supabase if credentials are present. Call once
  /// before `runApp`. Safe to call when nothing is configured — the
  /// app simply runs in offline-only mode.
  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (_projectUrl.isEmpty || _publishableKey.isEmpty) return;

    await Supabase.initialize(
      url: _projectUrl,
      anonKey: _publishableKey,
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: true,
      ),
    );
  }

  /// Convenience accessor. Throws if accessed before [initialize] ran
  /// successfully — guard call sites with [isConfigured] first.
  static SupabaseClient get client => Supabase.instance.client;
}
