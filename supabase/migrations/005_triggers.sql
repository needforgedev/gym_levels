-- 005_triggers.sql
-- Anti-cheat triggers + updated_at maintenance.
--
-- Triggers run inside the database transaction; the app cannot bypass
-- them by editing local sqflite to inflate XP. If a trigger raises,
-- the whole transaction rolls back — the row is rejected.

-- ─────────────────────────────────────────────────────────────────
-- Generic updated_at auto-bump
-- ─────────────────────────────────────────────────────────────────
--
-- Every cloud_* table has an updated_at column that should reflect
-- the most recent server-side write. The app pushes its own updated_at
-- value (used for client-side last-write-wins reasoning), but we also
-- bump it server-side on every UPDATE so server-time clock skew can't
-- make a client-side push appear "older" than the server thinks.

CREATE OR REPLACE FUNCTION _bump_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

DO $$
DECLARE
  t TEXT;
  tables TEXT[] := ARRAY[
    'public_profiles',
    'cloud_player',
    'cloud_goals',
    'cloud_experience',
    'cloud_schedule',
    'cloud_notification_prefs',
    'cloud_player_class',
    'cloud_workouts',
    'cloud_sets',
    'cloud_weight_logs',
    'cloud_quests',
    'cloud_muscle_ranks',
    'cloud_streak',
    'cloud_streak_freeze_events'
  ];
BEGIN
  FOREACH t IN ARRAY tables LOOP
    EXECUTE format($f$
      CREATE TRIGGER %I_bump_updated_at
        BEFORE UPDATE ON %I
        FOR EACH ROW EXECUTE FUNCTION _bump_updated_at()
    $f$, t, t);
  END LOOP;
END$$;

-- ─────────────────────────────────────────────────────────────────
-- Anti-cheat: weekly_xp delta cap on public_profiles
-- ─────────────────────────────────────────────────────────────────
--
-- A legitimate hard workout earns 200-400 XP. Cap at 1500 per push so
-- a forged client can't dump arbitrary XP at once.

CREATE OR REPLACE FUNCTION _enforce_weekly_xp_delta()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  delta INT;
BEGIN
  delta := COALESCE(NEW.weekly_xp, 0) - COALESCE(OLD.weekly_xp, 0);

  -- Resets are fine (Monday rollover sets it back to 0).
  IF NEW.weekly_xp = 0 THEN
    RETURN NEW;
  END IF;

  -- Otherwise cap upward delta.
  IF delta > 1500 THEN
    RAISE EXCEPTION 'weekly_xp delta exceeds cap (% > 1500)', delta
      USING ERRCODE = 'P0001';
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER public_profiles_enforce_weekly_xp_delta
  BEFORE UPDATE OF weekly_xp ON public_profiles
  FOR EACH ROW EXECUTE FUNCTION _enforce_weekly_xp_delta();

-- ─────────────────────────────────────────────────────────────────
-- Anti-cheat: total_xp monotonicity
-- ─────────────────────────────────────────────────────────────────
--
-- total_xp can only go up. The only way to reset it is via
-- delete_my_account, which deletes the row entirely.

CREATE OR REPLACE FUNCTION _enforce_total_xp_monotonic()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.total_xp < OLD.total_xp THEN
    RAISE EXCEPTION 'total_xp cannot decrease (was %, attempted %)',
      OLD.total_xp, NEW.total_xp
      USING ERRCODE = 'P0001';
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER public_profiles_enforce_total_xp_monotonic
  BEFORE UPDATE OF total_xp ON public_profiles
  FOR EACH ROW EXECUTE FUNCTION _enforce_total_xp_monotonic();

-- ─────────────────────────────────────────────────────────────────
-- Anti-cheat: streak increment cap (1 per local day)
-- ─────────────────────────────────────────────────────────────────
--
-- current_streak should grow by at most 1 per UTC day. We use UTC
-- here because we don't know the user's local timezone server-side;
-- a forged push that increments by more than 1 in the same UTC day
-- gets rejected.

CREATE OR REPLACE FUNCTION _enforce_streak_increment_cap()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  -- Decreases (or resets after a missed day) are fine.
  IF NEW.current_streak <= OLD.current_streak THEN
    RETURN NEW;
  END IF;

  -- Cap upward delta to 1 per write. Multiple writes in the same day
  -- still can't exceed 1 because each one would need to increment
  -- past the previous and we trip the cap.
  IF NEW.current_streak - OLD.current_streak > 1 THEN
    RAISE EXCEPTION 'current_streak can only increment by 1 per write (delta=%)',
      NEW.current_streak - OLD.current_streak
      USING ERRCODE = 'P0001';
  END IF;

  -- longest_streak must be >= current_streak.
  IF NEW.longest_streak < NEW.current_streak THEN
    NEW.longest_streak = NEW.current_streak;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER public_profiles_enforce_streak_cap
  BEFORE UPDATE OF current_streak ON public_profiles
  FOR EACH ROW EXECUTE FUNCTION _enforce_streak_increment_cap();

-- ─────────────────────────────────────────────────────────────────
-- Anti-cheat: workouts xp_earned + sets per-row checks
-- ─────────────────────────────────────────────────────────────────
--
-- The CHECK constraints on cloud_workouts.xp_earned and
-- cloud_sets.(weight_kg, reps, weight_kg * reps) already enforce the
-- per-row caps. No additional triggers needed.

-- ─────────────────────────────────────────────────────────────────
-- Friendship: prevent duplicate (sender, receiver) under different
-- ordering — already enforced by the LEAST/GREATEST unique index in
-- 002_schema.sql. No extra trigger needed.
-- ─────────────────────────────────────────────────────────────────

-- ─────────────────────────────────────────────────────────────────
-- Username lock — prevent rename more than once per 30 days
-- ─────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION _enforce_username_lock()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.username = OLD.username THEN
    RETURN NEW;
  END IF;

  -- First-time set: allow.
  IF OLD.username_locked_until IS NULL THEN
    NEW.username_locked_until := NOW() + INTERVAL '30 days';
    RETURN NEW;
  END IF;

  -- Subsequent renames: only allowed once the lock has expired.
  IF NOW() < OLD.username_locked_until THEN
    RAISE EXCEPTION 'username locked until % (try again later)',
      OLD.username_locked_until
      USING ERRCODE = 'P0001';
  END IF;

  NEW.username_locked_until := NOW() + INTERVAL '30 days';
  RETURN NEW;
END;
$$;

CREATE TRIGGER public_profiles_enforce_username_lock
  BEFORE UPDATE OF username ON public_profiles
  FOR EACH ROW EXECUTE FUNCTION _enforce_username_lock();

-- ─────────────────────────────────────────────────────────────────
-- Auto-create public_profiles row on signup (deferred)
-- ─────────────────────────────────────────────────────────────────
--
-- We deliberately do NOT auto-create a public_profiles row on signup.
-- The Pick Username + Phone Number screens (S2) collect those fields
-- before the row is INSERTed by the client. If we auto-created the
-- row here, we'd need a default username — which means a placeholder
-- holding a unique slot. Better to let the client manage row creation
-- in a single explicit INSERT once the user has filled out their
-- handle.
