import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Initializes the Supabase client and exposes the singleton.
///
/// Wired from [main.dart] before `runApp` so every screen can `await
/// SupabaseConfig.client.from('public_profiles').select(...)` without
/// re-initializing.
///
/// `.env` at the repo root holds:
///
/// ```env
/// PROJECT_URL=https://<ref>.supabase.co
/// PUBLISHABLE_KEY=sb_publishable_...
/// ```
///
/// `.env` is gitignored. The publishable key is safe to ship in the
/// client app — it's RLS-clamped on the database side. The
/// `service_role` key (which bypasses RLS) is *not* in `.env` and
/// never goes into the Flutter bundle.
class SupabaseConfig {
  SupabaseConfig._();

  /// Whether the app has valid Supabase credentials. False on a fresh
  /// dev machine that hasn't copied `.env.example` to `.env` yet — in
  /// that case we degrade gracefully (no socials, no leaderboard) and
  /// keep the rest of the app fully functional.
  static bool get isConfigured =>
      _projectUrl.isNotEmpty && _publishableKey.isNotEmpty;

  static String get _projectUrl => dotenv.env['PROJECT_URL'] ?? '';
  static String get _publishableKey => dotenv.env['PUBLISHABLE_KEY'] ?? '';

  /// Loads `.env` and initializes Supabase. Call once before `runApp`.
  ///
  /// Safe to call when `.env` is missing — logs a warning and returns
  /// without throwing. Callers should check [isConfigured] before any
  /// Supabase API call.
  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // .env not present — dev machine without credentials, or first-
      // time setup. Skip Supabase init; socials features will be
      // gated by `isConfigured`.
      return;
    }

    if (!isConfigured) return;

    await Supabase.initialize(
      url: _projectUrl,
      anonKey: _publishableKey,
      // Auth state persists across app launches via secure storage.
      // The Supabase Flutter SDK handles token refresh transparently.
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: true,
      ),
    );
  }

  /// Convenience accessor. Throws if accessed before [initialize] ran
  /// successfully — guard call sites with [isConfigured] first.
  static SupabaseClient get client => Supabase.instance.client;
}
