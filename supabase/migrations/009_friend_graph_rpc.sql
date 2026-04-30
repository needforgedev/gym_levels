-- 009_friend_graph_rpc.sql
-- list_my_friend_graph RPC — single-call read of the caller's full
-- friend graph with denormalized public_profiles fields baked in.
--
-- Why an RPC and not a direct SELECT: the public_profiles SELECT RLS
-- policy (003_rls.sql) only allows reading rows where an *accepted*
-- friendship exists. That's correct for browse-style access (e.g.
-- leaderboard) but breaks the pending-request UI: the receiver of a
-- request needs to see who's asking, even before accepting. Rather
-- than loosening the RLS policy (which would also leak profiles to
-- declined / blocked counterparties), this RPC runs with SECURITY
-- DEFINER and joins both tables atomically, returning only the
-- counterparty's profile fields the UI needs to render the row.
--
-- Excludes:
--   • Declined rows — declined requests are dismissed, not surfaced.
--   • Soft-deleted profiles — counterparty deleted their account.
--
-- Direction column lets the client place each row in the right UI
-- section without recomputing locally:
--   'incoming' — pending, current user is the receiver.
--   'outgoing' — pending, current user is the sender.
--   'mutual'   — accepted or blocked (symmetric).

CREATE OR REPLACE FUNCTION list_my_friend_graph()
RETURNS TABLE (
  friendship_id   UUID,
  other_user_id   UUID,
  username        CITEXT,
  display_name    TEXT,
  avatar_key      TEXT,
  level           INT,
  current_streak  INT,
  status          friendship_status,
  direction       TEXT,
  created_at      TIMESTAMPTZ,
  updated_at      TIMESTAMPTZ
)
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

  RETURN QUERY
    SELECT
      f.id AS friendship_id,
      CASE WHEN f.sender_id = uid THEN f.receiver_id ELSE f.sender_id END
        AS other_user_id,
      pp.username,
      pp.display_name,
      pp.avatar_key,
      pp.level,
      pp.current_streak,
      f.status,
      CASE
        WHEN f.status = 'pending' AND f.receiver_id = uid THEN 'incoming'
        WHEN f.status = 'pending' AND f.sender_id   = uid THEN 'outgoing'
        ELSE 'mutual'
      END AS direction,
      f.created_at,
      f.updated_at
    FROM friendships f
    JOIN public_profiles pp
      ON pp.user_id = (
        CASE WHEN f.sender_id = uid THEN f.receiver_id ELSE f.sender_id END
      )
    WHERE (f.sender_id = uid OR f.receiver_id = uid)
      AND f.status <> 'declined'
      AND pp.deleted_at IS NULL
    ORDER BY
      -- Pending incoming first (newest at top), then accepted, then
      -- outgoing, then blocked. Mirrors the screen layout so the
      -- client can render in-order without resorting.
      CASE
        WHEN f.status = 'pending' AND f.receiver_id = uid THEN 1
        WHEN f.status = 'accepted'                        THEN 2
        WHEN f.status = 'pending' AND f.sender_id   = uid THEN 3
        WHEN f.status = 'blocked'                         THEN 4
        ELSE 5
      END,
      f.updated_at DESC;
END;
$$;

GRANT EXECUTE ON FUNCTION list_my_friend_graph() TO authenticated;
