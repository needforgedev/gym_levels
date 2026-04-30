-- 007_cron.sql
-- Scheduled jobs via pg_cron.
-- - 30-day soft-delete purge: physically removes rows whose deleted_at
--   is more than 30 days in the past. Keeps the table sizes bounded.
--   Runs daily at 03:00 UTC (low-traffic window for India launch).
-- - rpc_call_log cleanup: opportunistic cleanup happens on every RPC
--   call (see 004_rpcs.sql), but a daily belt-and-braces sweep handles
--   the case where no RPC call hits the cleanup branch for a long time.

-- ─────────────────────────────────────────────────────────────────
-- Daily soft-delete purge
-- ─────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION _purge_soft_deleted()
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
  cutoff TIMESTAMPTZ := NOW() - INTERVAL '30 days';
BEGIN
  DELETE FROM cloud_workouts             WHERE deleted_at IS NOT NULL AND deleted_at < cutoff;
  DELETE FROM cloud_sets                 WHERE deleted_at IS NOT NULL AND deleted_at < cutoff;
  DELETE FROM cloud_weight_logs          WHERE deleted_at IS NOT NULL AND deleted_at < cutoff;
  DELETE FROM cloud_quests               WHERE deleted_at IS NOT NULL AND deleted_at < cutoff;
  DELETE FROM cloud_muscle_ranks         WHERE deleted_at IS NOT NULL AND deleted_at < cutoff;
  DELETE FROM cloud_streak_freeze_events WHERE deleted_at IS NOT NULL AND deleted_at < cutoff;
  DELETE FROM cloud_streak               WHERE deleted_at IS NOT NULL AND deleted_at < cutoff;
  DELETE FROM cloud_player               WHERE deleted_at IS NOT NULL AND deleted_at < cutoff;
  DELETE FROM cloud_goals                WHERE deleted_at IS NOT NULL AND deleted_at < cutoff;
  DELETE FROM cloud_experience           WHERE deleted_at IS NOT NULL AND deleted_at < cutoff;
  DELETE FROM cloud_schedule             WHERE deleted_at IS NOT NULL AND deleted_at < cutoff;
  DELETE FROM cloud_notification_prefs   WHERE deleted_at IS NOT NULL AND deleted_at < cutoff;
  DELETE FROM cloud_player_class         WHERE deleted_at IS NOT NULL AND deleted_at < cutoff;
  DELETE FROM public_profiles            WHERE deleted_at IS NOT NULL AND deleted_at < cutoff;
END;
$$;

SELECT cron.schedule(
  'purge_soft_deleted_daily',
  '0 3 * * *',          -- 03:00 UTC every day
  $$ SELECT _purge_soft_deleted(); $$
);

-- ─────────────────────────────────────────────────────────────────
-- Daily rpc_call_log cleanup (defense-in-depth)
-- ─────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION _purge_rpc_call_log()
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
  DELETE FROM rpc_call_log WHERE called_at < NOW() - INTERVAL '1 day';
END;
$$;

SELECT cron.schedule(
  'purge_rpc_call_log_daily',
  '15 3 * * *',         -- 03:15 UTC every day
  $$ SELECT _purge_rpc_call_log(); $$
);

-- ─────────────────────────────────────────────────────────────────
-- Weekly auto-rollover of weekly_xp on public_profiles
-- ─────────────────────────────────────────────────────────────────
--
-- The app pushes weekly_xp computed from local-week-start so the
-- value naturally resets when the week boundary passes locally on
-- the next workout-finish push. But if a user doesn't train for a
-- whole week, their weekly_xp stays at last week's number until they
-- come back. This cron flips it to 0 every Monday 00:00 UTC as a
-- belt-and-braces fallback for long-inactive users.
--
-- Trade-off: users in timezones west of UTC see their leaderboard
-- "reset" Sunday evening local time (one day early). Acceptable for
-- v1.x.0 since most users in India are UTC+5:30 (resets Monday morning
-- local). Can revisit when we add timezone-per-user.

CREATE OR REPLACE FUNCTION _reset_weekly_xp()
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
  -- Only reset rows that didn't already get reset by a fresher push
  -- this week. Anything updated in the last 24 hours is presumed
  -- already current.
  UPDATE public_profiles
     SET weekly_xp = 0
   WHERE weekly_xp > 0
     AND updated_at < NOW() - INTERVAL '24 hours';
END;
$$;

SELECT cron.schedule(
  'reset_weekly_xp_monday',
  '0 0 * * 1',          -- 00:00 UTC every Monday
  $$ SELECT _reset_weekly_xp(); $$
);
