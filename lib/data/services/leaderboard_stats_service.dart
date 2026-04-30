import '../../game/xp_engine.dart';
import '../supabase/supabase_client.dart';
import 'auth_service.dart';
import 'streak_service.dart';
import 'workout_service.dart';

/// Recomputes the user's `public_profiles` summary fields from the
/// authoritative local sqflite state and pushes the result. The
/// leaderboard reads exclusively from `public_profiles`, so without
/// this nothing renders.
///
/// Pushed columns:
///   • `level`           — derived from total XP via [XpEngine.resolve]
///   • `total_xp`        — sum of every workout's `xp_earned`
///   • `weekly_xp`       — sum since most recent Monday 00:00 UTC
///   • `current_streak`  — from `streaks.current`
///   • `longest_streak`  — from `streaks.longest`
///   • `last_active_at`  — most recent workout end timestamp
///
/// Triggers:
///   • [WorkoutService.finish] — XP / level / weekly / last_active
///     all change at workout completion.
///   • [StreakService.upsert] — current / longest streak.
///   • [SyncEngine] drain tick — defensive sweep so a missed direct
///     call still converges within ~30s.
///
/// Idempotent + cheap (one local SUM, one PostgREST UPDATE). Failures
/// are swallowed — leaderboard going stale is annoying but never
/// blocks gameplay.
class LeaderboardStatsService {
  LeaderboardStatsService._();

  /// Recompute + push. Safe to call any time.
  static Future<void> refresh() async {
    if (!AuthService.isAuthenticated) return;
    final userId = AuthService.currentUserId!;

    try {
      final totalXp = await WorkoutService.totalXp();
      final weeklyXp = await WorkoutService.weeklyXp();
      final streak = await StreakService.get();
      final recent = await WorkoutService.recent(limit: 1);
      final lastActiveSecs = recent.isEmpty
          ? null
          : (recent.first.endedAt ?? recent.first.startedAt);
      final level = XpEngine.resolve(totalXp).level;

      final update = <String, Object?>{
        'level': level,
        'total_xp': totalXp,
        'weekly_xp': weeklyXp,
        'current_streak': streak?.current ?? 0,
        'longest_streak': streak?.longest ?? 0,
      };
      if (lastActiveSecs != null) {
        update['last_active_at'] = DateTime.fromMillisecondsSinceEpoch(
          lastActiveSecs * 1000,
          isUtc: true,
        ).toIso8601String();
      }

      await SupabaseConfig.client
          .from('public_profiles')
          .update(update)
          .eq('user_id', userId);
    } catch (_) {
      // Surface to a debug screen later (S7). Anti-cheat triggers can
      // legitimately reject the push when local has accumulated
      // suspiciously fast — that's not a client bug to fix.
    }
  }
}
