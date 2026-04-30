-- 003_rls.sql
-- Row-Level Security policies. Postgres enforces these at the database
-- layer; clients cannot bypass them even if the anon key leaks.
--
-- Pattern:
--   • Owned-row tables (cloud_workouts, cloud_sets, etc.): user can
--     read/write only their own rows. Single template repeated.
--   • public_profiles: extra SELECT exception so accepted friends can
--     read each other's rows.
--   • friendships: insert as sender, accept/decline as receiver, block
--     either side.
--   • report_log: insert by reporter, server-only read.
--   • reserved_usernames: server-only.
--   • rpc_call_log: server-only (RPCs write into it via SECURITY DEFINER).

-- ─────────────────────────────────────────────────────────────────
-- Enable RLS on every table
-- ─────────────────────────────────────────────────────────────────

ALTER TABLE public_profiles            ENABLE ROW LEVEL SECURITY;
ALTER TABLE friendships                ENABLE ROW LEVEL SECURITY;
ALTER TABLE report_log                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE reserved_usernames         ENABLE ROW LEVEL SECURITY;
ALTER TABLE rpc_call_log               ENABLE ROW LEVEL SECURITY;

ALTER TABLE cloud_player               ENABLE ROW LEVEL SECURITY;
ALTER TABLE cloud_goals                ENABLE ROW LEVEL SECURITY;
ALTER TABLE cloud_experience           ENABLE ROW LEVEL SECURITY;
ALTER TABLE cloud_schedule             ENABLE ROW LEVEL SECURITY;
ALTER TABLE cloud_notification_prefs   ENABLE ROW LEVEL SECURITY;
ALTER TABLE cloud_player_class         ENABLE ROW LEVEL SECURITY;
ALTER TABLE cloud_workouts             ENABLE ROW LEVEL SECURITY;
ALTER TABLE cloud_sets                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE cloud_weight_logs          ENABLE ROW LEVEL SECURITY;
ALTER TABLE cloud_quests               ENABLE ROW LEVEL SECURITY;
ALTER TABLE cloud_muscle_ranks         ENABLE ROW LEVEL SECURITY;
ALTER TABLE cloud_streak               ENABLE ROW LEVEL SECURITY;
ALTER TABLE cloud_streak_freeze_events ENABLE ROW LEVEL SECURITY;

-- ─────────────────────────────────────────────────────────────────
-- public_profiles
-- ─────────────────────────────────────────────────────────────────

-- SELECT: own row OR profile of an accepted friend.
CREATE POLICY public_profiles_select
  ON public_profiles
  FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM friendships f
      WHERE f.status = 'accepted'
        AND ((f.sender_id = auth.uid() AND f.receiver_id = public_profiles.user_id)
          OR (f.receiver_id = auth.uid() AND f.sender_id = public_profiles.user_id))
    )
  );

CREATE POLICY public_profiles_insert
  ON public_profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY public_profiles_update
  ON public_profiles
  FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY public_profiles_delete
  ON public_profiles
  FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

-- ─────────────────────────────────────────────────────────────────
-- friendships
-- ─────────────────────────────────────────────────────────────────

CREATE POLICY friendships_select
  ON friendships
  FOR SELECT
  TO authenticated
  USING (sender_id = auth.uid() OR receiver_id = auth.uid());

-- INSERT: only as sender, must start as 'pending'.
CREATE POLICY friendships_insert
  ON friendships
  FOR INSERT
  TO authenticated
  WITH CHECK (
    sender_id = auth.uid()
    AND status = 'pending'
  );

-- UPDATE: receiver can flip pending → accepted/declined; either side
-- can set 'blocked'. Senders cannot self-accept.
CREATE POLICY friendships_update
  ON friendships
  FOR UPDATE
  TO authenticated
  USING (sender_id = auth.uid() OR receiver_id = auth.uid())
  WITH CHECK (
    -- Receiver flipping pending → accepted/declined.
    (receiver_id = auth.uid() AND status IN ('accepted', 'declined'))
    OR
    -- Either side can block.
    (status = 'blocked' AND (sender_id = auth.uid() OR receiver_id = auth.uid()))
  );

-- DELETE: either side, used for "remove friend".
CREATE POLICY friendships_delete
  ON friendships
  FOR DELETE
  TO authenticated
  USING (sender_id = auth.uid() OR receiver_id = auth.uid());

-- ─────────────────────────────────────────────────────────────────
-- report_log
-- ─────────────────────────────────────────────────────────────────

-- No SELECT policy on purpose — server-side review only via service
-- role (which bypasses RLS entirely).
CREATE POLICY report_log_insert
  ON report_log
  FOR INSERT
  TO authenticated
  WITH CHECK (reporter_id = auth.uid());

-- ─────────────────────────────────────────────────────────────────
-- reserved_usernames + rpc_call_log
-- ─────────────────────────────────────────────────────────────────

-- These tables have NO policies for `authenticated`. RLS is enabled, so
-- without a permissive policy the client gets nothing. Server-side
-- code (RPCs running as SECURITY DEFINER) can still read/write.
-- Apps SELECT against these only via dedicated RPCs (e.g.
-- check_username_available) defined in 004_rpcs.sql.

-- ─────────────────────────────────────────────────────────────────
-- Owned-row tables — same template applied to every cloud_* table
-- ─────────────────────────────────────────────────────────────────
--
-- For each cloud_* table: a user can SELECT, INSERT, UPDATE, DELETE
-- only rows where user_id = auth.uid(). Bulk macro via DO block to
-- keep the migration short.

DO $$
DECLARE
  t TEXT;
  tables TEXT[] := ARRAY[
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
      CREATE POLICY %I_select ON %I
        FOR SELECT TO authenticated
        USING (user_id = auth.uid())
    $f$, t, t);

    EXECUTE format($f$
      CREATE POLICY %I_insert ON %I
        FOR INSERT TO authenticated
        WITH CHECK (user_id = auth.uid())
    $f$, t, t);

    EXECUTE format($f$
      CREATE POLICY %I_update ON %I
        FOR UPDATE TO authenticated
        USING (user_id = auth.uid())
        WITH CHECK (user_id = auth.uid())
    $f$, t, t);

    EXECUTE format($f$
      CREATE POLICY %I_delete ON %I
        FOR DELETE TO authenticated
        USING (user_id = auth.uid())
    $f$, t, t);
  END LOOP;
END$$;

-- ─────────────────────────────────────────────────────────────────
-- Anonymous role: no access at all
-- ─────────────────────────────────────────────────────────────────
--
-- The `anon` role is what an unauthenticated client hits. We explicitly
-- revoke it on every table so the only way to interact with any data
-- is to be authenticated (i.e. signed up + email-verified). Public
-- access (e.g. a future invite-link landing page) goes through a
-- dedicated SECURITY DEFINER RPC if needed.

REVOKE ALL ON public_profiles            FROM anon;
REVOKE ALL ON friendships                FROM anon;
REVOKE ALL ON report_log                 FROM anon;
REVOKE ALL ON reserved_usernames         FROM anon;
REVOKE ALL ON rpc_call_log               FROM anon;
REVOKE ALL ON cloud_player               FROM anon;
REVOKE ALL ON cloud_goals                FROM anon;
REVOKE ALL ON cloud_experience           FROM anon;
REVOKE ALL ON cloud_schedule             FROM anon;
REVOKE ALL ON cloud_notification_prefs   FROM anon;
REVOKE ALL ON cloud_player_class         FROM anon;
REVOKE ALL ON cloud_workouts             FROM anon;
REVOKE ALL ON cloud_sets                 FROM anon;
REVOKE ALL ON cloud_weight_logs          FROM anon;
REVOKE ALL ON cloud_quests               FROM anon;
REVOKE ALL ON cloud_muscle_ranks         FROM anon;
REVOKE ALL ON cloud_streak               FROM anon;
REVOKE ALL ON cloud_streak_freeze_events FROM anon;
