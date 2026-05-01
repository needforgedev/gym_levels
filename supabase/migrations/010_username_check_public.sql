-- 010_username_check_public.sql
-- Make `check_username_available` callable pre-auth.
--
-- Why: identity collection moved from a post-auth `/username` screen
-- into the Join Now form on the auth screen itself. The form runs the
-- live availability check while the user is still anonymous (no
-- `auth.uid()`), so the RPC must accept anon callers.
--
-- The original definition called `_rpc_rate_limited` which RAISEs
-- 'authentication required' for anon — that's why the client saw a
-- "not_authenticated" reason string. The new definition drops the
-- rate-limit helper (anon can't be keyed off `auth.uid()`) and is
-- granted EXECUTE on the `anon` role.
--
-- Security note: usernames are designed to be public-facing handles.
-- Allowing anon to enumerate "is this username taken?" is no worse
-- than allowing post-auth enumeration via `search_users_by_username`,
-- and the actual server-side INSERT into `public_profiles` still
-- enforces the UNIQUE + NOT NULL + format-CHECK constraints. Loss of
-- per-user rate limiting is acceptable; if abuse becomes real, swap
-- in a Supabase Edge Function with IP-based limiting.

CREATE OR REPLACE FUNCTION check_username_available(candidate TEXT)
RETURNS TABLE (available BOOLEAN, reason TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
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

GRANT EXECUTE ON FUNCTION check_username_available(TEXT) TO anon, authenticated;
