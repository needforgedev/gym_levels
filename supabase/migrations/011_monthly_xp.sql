-- 011_monthly_xp.sql
-- Adds the monthly_xp column to public_profiles so the leaderboard's
-- "Month" tab can render real data. Mirrors the weekly_xp pattern:
--   • client computes the value from local sqflite (sum of xp_earned
--     since the 1st of the current UTC month) and pushes it via
--     LeaderboardStatsService.refresh()
--   • a delta-cap trigger blocks forged spikes
--   • a monthly cron resets long-inactive users to 0 on the 1st

ALTER TABLE public_profiles
  ADD COLUMN IF NOT EXISTS monthly_xp INT NOT NULL DEFAULT 0;

CREATE INDEX IF NOT EXISTS idx_public_profiles_monthly_xp
  ON public_profiles(monthly_xp DESC)
  WHERE deleted_at IS NULL;

-- ─────────────────────────────────────────────────────────────────
-- Anti-cheat: monthly_xp delta cap (4× the weekly cap)
-- ─────────────────────────────────────────────────────────────────
-- A month has ~4.3 weeks; weekly cap is 1500 per push, so monthly
-- caps at 6000. Resets to 0 are always allowed.

CREATE OR REPLACE FUNCTION _enforce_monthly_xp_delta()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  delta INT;
BEGIN
  delta := COALESCE(NEW.monthly_xp, 0) - COALESCE(OLD.monthly_xp, 0);

  IF NEW.monthly_xp = 0 THEN
    RETURN NEW;
  END IF;

  IF delta > 6000 THEN
    RAISE EXCEPTION 'monthly_xp delta exceeds cap (% > 6000)', delta
      USING ERRCODE = 'P0001';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS public_profiles_enforce_monthly_xp_delta
  ON public_profiles;
CREATE TRIGGER public_profiles_enforce_monthly_xp_delta
  BEFORE UPDATE OF monthly_xp ON public_profiles
  FOR EACH ROW EXECUTE FUNCTION _enforce_monthly_xp_delta();

-- ─────────────────────────────────────────────────────────────────
-- Monthly auto-rollover of monthly_xp
-- ─────────────────────────────────────────────────────────────────
-- The client recomputes monthly_xp from local data on every workout
-- finish, so the value naturally resets the first time the user
-- trains in a new month. This cron is the belt-and-braces fallback
-- for users who don't train for an entire month.

CREATE OR REPLACE FUNCTION _reset_monthly_xp()
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE public_profiles
     SET monthly_xp = 0
   WHERE monthly_xp > 0
     AND updated_at < NOW() - INTERVAL '24 hours';
END;
$$;

SELECT cron.schedule(
  'reset_monthly_xp_first_of_month',
  '0 0 1 * *',          -- 00:00 UTC on the 1st of every month
  $$ SELECT _reset_monthly_xp(); $$
);
