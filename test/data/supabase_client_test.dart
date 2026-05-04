// Regression tests for the dotenv-not-loaded crash documented in the
// 2026-05-02 audit (P0-01). Before the fix, any call path that
// touched `SupabaseConfig.isConfigured` from a context where
// `dotenv.load()` had never run threw `NotInitializedError` from
// `flutter_dotenv`. The fix caches env values inside `initialize()`
// so the public getters never read `dotenv.env` directly.
//
// Two paths must stay safe:
//   1. `SupabaseConfig.isConfigured` — the gate every service checks.
//   2. `AuthService.isAuthenticated` — built on top of (1), so it
//      inherits the same risk.
//
// Both must return `false`, not throw, when the test harness has not
// initialized dotenv.

import 'package:flutter_test/flutter_test.dart';
import 'package:gym_levels/data/services/auth_service.dart';
import 'package:gym_levels/data/supabase/supabase_client.dart';

void main() {
  group('SupabaseConfig — offline-safe getters', () {
    test('isConfigured returns false when dotenv was never loaded', () {
      expect(SupabaseConfig.isConfigured, isFalse);
    });

    test('AuthService.isAuthenticated returns false (does not throw)', () {
      // Should not throw NotInitializedError.
      expect(() => AuthService.isAuthenticated, returnsNormally);
      expect(AuthService.isAuthenticated, isFalse);
    });

    test('AuthService.currentUserId returns null without env', () {
      expect(AuthService.currentUserId, isNull);
    });
  });
}
