-- 004_rpcs.sql
-- RPC functions invoked from the Flutter app. All run as SECURITY
-- DEFINER (i.e. with elevated privileges that bypass RLS) but verify
-- the calling user's identity at the top via `auth.uid()` before doing
-- anything sensitive. The app cannot bypass these checks because
-- they're inside the function body, not in client code.
--
-- Functions defined here:
--   • check_username_available(text)        — does this username exist?
--   • find_users_by_phone_hashes(text[])    — contact-match
--   • search_users_by_username(text)        — handle search (typeahead)
--   • disconnect_socials()                  — purge profile + friendships, keep cloud_* data
--   • delete_my_account()                   — purge everything + auth row
--   • report_user(uuid, text)               — file an abuse report
--
-- All hot RPCs apply rate-limiting via the rpc_call_log table.

-- ─────────────────────────────────────────────────────────────────
-- Helper: rate-limit check (private)
-- ─────────────────────────────────────────────────────────────────
--
-- Returns TRUE if the caller has exceeded `max_calls` of `rpc` in the
-- last `window_seconds`. Side effect: writes the current call into
-- rpc_call_log. Cleans up rows older than 1 day on every call.

CREATE OR REPLACE FUNCTION _rpc_rate_limited(
  rpc TEXT,
  max_calls INT,
  window_seconds INT
) RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  recent_count INT;
BEGIN
  -- Reject anonymous callers.
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'authentication required';
  END IF;

  SELECT COUNT(*)
    INTO recent_count
    FROM rpc_call_log
   WHERE user_id = auth.uid()
     AND rpc_name = rpc
     AND called_at >= NOW() - make_interval(secs => window_seconds);

  -- Always log this call (even if it'll be rejected — so abuse shows
  -- up in the audit trail).
  INSERT INTO rpc_call_log(user_id, rpc_name) VALUES (auth.uid(), rpc);

  -- Opportunistic cleanup: drop log rows older than 1 day. Cheap on
  -- an index lookup; runs on every RPC call so the table stays small.
  DELETE FROM rpc_call_log WHERE called_at < NOW() - INTERVAL '1 day';

  RETURN recent_count >= max_calls;
END;
$$;

-- ─────────────────────────────────────────────────────────────────
-- check_username_available
-- ─────────────────────────────────────────────────────────────────
--
-- Used by the Pick Username screen for live availability checks.
-- Rate-limited (30 calls / minute / user) to prevent username
-- enumeration. Returns:
--   { available: bool, reason: text | null }
-- where `reason` is one of: 'reserved', 'taken', 'invalid_format'.

CREATE OR REPLACE FUNCTION check_username_available(candidate TEXT)
RETURNS TABLE (available BOOLEAN, reason TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF _rpc_rate_limited('check_username_available', 30, 60) THEN
    RAISE EXCEPTION 'rate_limit_exceeded' USING ERRCODE = 'P0001';
  END IF;

  -- Format check (matches the CHECK constraint on public_profiles.username).
  IF candidate !~ '^[a-z0-9_]{3,20}$' THEN
    RETURN QUERY SELECT FALSE, 'invalid_format'::TEXT;
    RETURN;
  END IF;

  -- Reserved blocklist.
  IF EXISTS (SELECT 1 FROM reserved_usernames WHERE username = candidate::CITEXT) THEN
    RETURN QUERY SELECT FALSE, 'reserved'::TEXT;
    RETURN;
  END IF;

  -- Already taken (citext UNIQUE handles case-insensitive collision).
  IF EXISTS (
    SELECT 1 FROM public_profiles
     WHERE username = candidate::CITEXT
       AND deleted_at IS NULL
  ) THEN
    RETURN QUERY SELECT FALSE, 'taken'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT TRUE, NULL::TEXT;
END;
$$;

-- ─────────────────────────────────────────────────────────────────
-- find_users_by_phone_hashes
-- ─────────────────────────────────────────────────────────────────
--
-- Contact-match. App sends an array of SHA-256 hashes (already salted
-- on-device using the same salt the server uses). Server returns the
-- matching user_ids + the small subset of profile fields the matched-
-- friends screen needs.
--
-- Rate-limited 5 calls / hour / user. Each call is bounded to 5000
-- hashes (typical address book has 100-300 contacts).

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

  -- Don't include yourself in the matches.
  RETURN QUERY
    SELECT
      pp.user_id,
      pp.username,
      pp.display_name,
      pp.avatar_key,
      pp.level,
      pp.current_streak
    FROM public_profiles pp
    WHERE pp.phone_hash = ANY(hashes)
      AND pp.user_id <> auth.uid()
      AND pp.deleted_at IS NULL
    LIMIT 200;
END;
$$;

-- ─────────────────────────────────────────────────────────────────
-- search_users_by_username
-- ─────────────────────────────────────────────────────────────────
--
-- Handle search. Prefix match on the first 3+ characters. Rate-limited
-- 30 calls / minute / user.

CREATE OR REPLACE FUNCTION search_users_by_username(prefix TEXT)
RETURNS TABLE (
  user_id        UUID,
  username       CITEXT,
  display_name   TEXT,
  avatar_key     TEXT,
  level          INT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF _rpc_rate_limited('search_users_by_username', 30, 60) THEN
    RAISE EXCEPTION 'rate_limit_exceeded' USING ERRCODE = 'P0001';
  END IF;

  IF length(prefix) < 3 THEN
    RAISE EXCEPTION 'prefix_too_short' USING ERRCODE = 'P0001';
  END IF;

  RETURN QUERY
    SELECT
      pp.user_id,
      pp.username,
      pp.display_name,
      pp.avatar_key,
      pp.level
    FROM public_profiles pp
    WHERE pp.username ILIKE (prefix || '%')
      AND pp.user_id <> auth.uid()
      AND pp.deleted_at IS NULL
    ORDER BY pp.username
    LIMIT 20;
END;
$$;

-- ─────────────────────────────────────────────────────────────────
-- disconnect_socials
-- ─────────────────────────────────────────────────────────────────
--
-- User taps "Disconnect socials" in Settings. Wipes their friend graph
-- and public profile so they vanish from leaderboards / contact match,
-- but KEEPS their cloud_* gameplay data so re-enabling later restores
-- everything cleanly. To wipe everything use delete_my_account.

CREATE OR REPLACE FUNCTION disconnect_socials()
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

  -- Drop every friendship involving this user (both directions).
  DELETE FROM friendships
   WHERE sender_id = uid OR receiver_id = uid;

  -- Drop the public profile row. (Cloud gameplay data stays.)
  DELETE FROM public_profiles WHERE user_id = uid;
END;
$$;

-- ─────────────────────────────────────────────────────────────────
-- delete_my_account
-- ─────────────────────────────────────────────────────────────────
--
-- Hard delete everything for App Store compliance. Purges every
-- cloud_* row, every friendship, the public profile, and finally the
-- auth.users row itself. The CASCADE on the FK does most of the work
-- once auth.users is dropped, but we explicitly wipe socials tables
-- first to avoid leaving orphaned friend rows visible to other users
-- in the brief window between the public_profiles delete and the
-- auth.users delete.

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
  DELETE FROM public_profiles WHERE user_id = uid;

  -- Cloud data tables. ON DELETE CASCADE on the user_id FK to
  -- auth.users will catch anything we miss, but be explicit.
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

  -- Finally, drop the auth row. Triggers token revocation across all
  -- devices on next refresh.
  DELETE FROM auth.users WHERE id = uid;
END;
$$;

-- ─────────────────────────────────────────────────────────────────
-- report_user
-- ─────────────────────────────────────────────────────────────────
--
-- File an abuse report. Rate-limited so a single user can't flood the
-- queue (10 reports / hour).

CREATE OR REPLACE FUNCTION report_user(target UUID, the_reason TEXT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF _rpc_rate_limited('report_user', 10, 3600) THEN
    RAISE EXCEPTION 'rate_limit_exceeded' USING ERRCODE = 'P0001';
  END IF;

  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'authentication required';
  END IF;

  IF target = auth.uid() THEN
    RAISE EXCEPTION 'cannot report yourself' USING ERRCODE = 'P0001';
  END IF;

  IF the_reason IS NULL OR length(trim(the_reason)) = 0 THEN
    RAISE EXCEPTION 'reason required' USING ERRCODE = 'P0001';
  END IF;

  INSERT INTO report_log(reporter_id, reported_id, reason)
  VALUES (auth.uid(), target, trim(the_reason));
END;
$$;

-- ─────────────────────────────────────────────────────────────────
-- Grant EXECUTE on the public RPCs to authenticated users
-- ─────────────────────────────────────────────────────────────────

GRANT EXECUTE ON FUNCTION check_username_available(TEXT)        TO authenticated;
GRANT EXECUTE ON FUNCTION find_users_by_phone_hashes(TEXT[])    TO authenticated;
GRANT EXECUTE ON FUNCTION search_users_by_username(TEXT)        TO authenticated;
GRANT EXECUTE ON FUNCTION disconnect_socials()                  TO authenticated;
GRANT EXECUTE ON FUNCTION delete_my_account()                   TO authenticated;
GRANT EXECUTE ON FUNCTION report_user(UUID, TEXT)               TO authenticated;

-- _rpc_rate_limited is internal; revoke EXECUTE from public.
REVOKE EXECUTE ON FUNCTION _rpc_rate_limited(TEXT, INT, INT) FROM PUBLIC;
