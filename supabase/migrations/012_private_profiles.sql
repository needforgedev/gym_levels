-- 012_private_profiles.sql
-- Closes the P0-3 privacy gap from the 2026-05-02 audit.
--
-- Before this migration, `phone` and `phone_hash` were columns on
-- `public_profiles`. The RLS policy on that table allows accepted
-- friends to SELECT each other's rows — and Postgres RLS gates rows,
-- not columns, so a malicious client with the publishable key could
-- request `?select=phone` and read a friend's raw number.
--
-- This migration moves the two private columns into a new
-- `private_profiles` table whose RLS rule is "owner only" — no
-- friendship exception, no public read. The contact-match RPC
-- (`find_users_by_phone_hashes`) is rewritten to look up hashes in
-- the new table; it still runs with `SECURITY DEFINER` so it can
-- read across users, but it only RETURNS safe public-profile fields
-- (no phone, no hash). Account deletion is updated to drop the new
-- table's row.
--
-- Pre-launch deployment: applied as a single atomic migration.
-- Drop-old-columns happens in this same file (Stage 1 + 2 + 3
-- collapsed) since there are no live users on old app versions.
--
-- Migration is idempotent — safe to re-run if the SQL editor errors
-- out partway through.

-- ─────────────────────────────────────────────────────────────────
-- 1. Create private_profiles
-- ─────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS private_profiles (
  user_id     UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  phone       TEXT,
  phone_hash  TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for the contact-match lookup. Migrated from public_profiles
-- (the index there is dropped at the bottom of this file).
CREATE INDEX IF NOT EXISTS idx_private_profiles_phone_hash
  ON private_profiles(phone_hash)
  WHERE phone_hash IS NOT NULL;

-- ─────────────────────────────────────────────────────────────────
-- 2. RLS — owner only, no friendship exception
-- ─────────────────────────────────────────────────────────────────

ALTER TABLE private_profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS private_profiles_select ON private_profiles;
CREATE POLICY private_profiles_select
  ON private_profiles
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS private_profiles_insert ON private_profiles;
CREATE POLICY private_profiles_insert
  ON private_profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS private_profiles_update ON private_profiles;
CREATE POLICY private_profiles_update
  ON private_profiles
  FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS private_profiles_delete ON private_profiles;
CREATE POLICY private_profiles_delete
  ON private_profiles
  FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

-- Anon role gets nothing. authenticated has only what the policies
-- above allow.
REVOKE ALL ON private_profiles FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON private_profiles TO authenticated;

-- ─────────────────────────────────────────────────────────────────
-- 3. updated_at auto-bump (mirrors the trigger pattern in 005)
-- ─────────────────────────────────────────────────────────────────

DROP TRIGGER IF EXISTS private_profiles_bump_updated_at ON private_profiles;
CREATE TRIGGER private_profiles_bump_updated_at
  BEFORE UPDATE ON private_profiles
  FOR EACH ROW EXECUTE FUNCTION _bump_updated_at();

-- ─────────────────────────────────────────────────────────────────
-- 4. Backfill from public_profiles
-- ─────────────────────────────────────────────────────────────────
-- Copy any existing phone / phone_hash values into the new table
-- before we drop the columns. Skip rows where both are null so we
-- don't create empty private_profiles rows for users who never set
-- a phone number.

INSERT INTO private_profiles (user_id, phone, phone_hash)
SELECT user_id, phone, phone_hash
  FROM public_profiles
 WHERE phone IS NOT NULL OR phone_hash IS NOT NULL
ON CONFLICT (user_id) DO UPDATE
   SET phone      = EXCLUDED.phone,
       phone_hash = EXCLUDED.phone_hash;

-- ─────────────────────────────────────────────────────────────────
-- 5. Update find_users_by_phone_hashes to read from private_profiles
-- ─────────────────────────────────────────────────────────────────
-- The RPC keeps SECURITY DEFINER (so it can cross-read regardless of
-- caller's RLS) but it only RETURNS public_profiles columns — the
-- raw phone never travels back to any client.

CREATE OR REPLACE FUNCTION find_users_by_phone_hashes(hashes TEXT[])
RETURNS TABLE (
  user_id        UUID,
  username       CITEXT,
  display_name   TEXT,
  avatar_key     TEXT,
  level          INT,
  current_streak INT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF _rpc_rate_limited('find_users_by_phone_hashes', 5, 3600) THEN
    RAISE EXCEPTION 'rate_limit_exceeded' USING ERRCODE = 'P0001';
  END IF;

  IF array_length(hashes, 1) IS NULL OR array_length(hashes, 1) = 0 THEN
    RETURN;
  END IF;

  IF array_length(hashes, 1) > 5000 THEN
    RAISE EXCEPTION 'too_many_hashes' USING ERRCODE = 'P0001';
  END IF;

  -- Match hashes against private_profiles, then join to public_profiles
  -- for the safe display columns. Excludes the caller's own row.
  RETURN QUERY
    SELECT
      pp.user_id,
      pp.username,
      pp.display_name,
      pp.avatar_key,
      pp.level,
      pp.current_streak
    FROM private_profiles priv
    JOIN public_profiles pp ON pp.user_id = priv.user_id
    WHERE priv.phone_hash = ANY(hashes)
      AND priv.user_id <> auth.uid()
      AND pp.deleted_at IS NULL
    LIMIT 200;
END;
$$;

-- ─────────────────────────────────────────────────────────────────
-- 6. Update delete_my_account to clear private_profiles too
-- ─────────────────────────────────────────────────────────────────
-- The ON DELETE CASCADE on private_profiles.user_id → auth.users
-- catches this for free, but be explicit to match the existing
-- pattern in 004_rpcs.sql (defense in depth + clearer audit trail).

CREATE OR REPLACE FUNCTION delete_my_account()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  uid UUID := auth.uid();
BEGIN
  IF uid IS NULL THEN
    RAISE EXCEPTION 'authentication required';
  END IF;

  DELETE FROM friendships WHERE sender_id = uid OR receiver_id = uid;
  DELETE FROM private_profiles WHERE user_id = uid;
  DELETE FROM public_profiles WHERE user_id = uid;

  DELETE FROM cloud_player                WHERE user_id = uid;
  DELETE FROM cloud_goals                 WHERE user_id = uid;
  DELETE FROM cloud_experience            WHERE user_id = uid;
  DELETE FROM cloud_schedule              WHERE user_id = uid;
  DELETE FROM cloud_notification_prefs    WHERE user_id = uid;
  DELETE FROM cloud_player_class          WHERE user_id = uid;
  DELETE FROM cloud_workouts              WHERE user_id = uid;
  DELETE FROM cloud_sets                  WHERE user_id = uid;
  DELETE FROM cloud_weight_logs           WHERE user_id = uid;
  DELETE FROM cloud_quests                WHERE user_id = uid;
  DELETE FROM cloud_muscle_ranks          WHERE user_id = uid;
  DELETE FROM cloud_streak                WHERE user_id = uid;
  DELETE FROM cloud_streak_freeze_events  WHERE user_id = uid;

  DELETE FROM auth.users WHERE id = uid;
END;
$$;

-- ─────────────────────────────────────────────────────────────────
-- 7. Drop the now-private columns from public_profiles
-- ─────────────────────────────────────────────────────────────────
-- This is the actual privacy fix — phone and phone_hash physically
-- leave the friend-readable table. Once these columns are gone, no
-- amount of misconfigured RLS or careless `SELECT *` can re-expose
-- them via public_profiles.

DROP INDEX IF EXISTS idx_public_profiles_phone_hash;
ALTER TABLE public_profiles DROP COLUMN IF EXISTS phone;
ALTER TABLE public_profiles DROP COLUMN IF EXISTS phone_hash;
