-- 002_schema.sql
-- Cloud-mirrored tables for LEVEL UP IRL socials + Scope B sync.
-- Each user-data table follows the same shape:
--   cloud_id UUID PK (matches the local `cloud_id` column on the device)
--   user_id UUID FK auth.users
--   updated_at, deleted_at, schema_version, created_at
--   table-specific data columns mirroring the local sqflite schema
--
-- Mutable singletons (one row per user) use UNIQUE (user_id) instead of
-- relying on cloud_id. Append-only history tables (workouts, sets, etc.)
-- rely on cloud_id for deduplication on re-push.

-- ─────────────────────────────────────────────────────────────────
-- Custom types
-- ─────────────────────────────────────────────────────────────────

CREATE TYPE friendship_status AS ENUM (
  'pending',
  'accepted',
  'declined',
  'blocked'
);

-- ─────────────────────────────────────────────────────────────────
-- public_profiles — driver of leaderboard + contact match
-- ─────────────────────────────────────────────────────────────────

CREATE TABLE public_profiles (
  user_id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username         CITEXT UNIQUE NOT NULL CHECK (username ~ '^[a-z0-9_]{3,20}$'),
  display_name     TEXT NOT NULL,
  avatar_key       TEXT,
  -- Phone stored plain. RLS restricts SELECT to the owning user
  -- (auth.uid() = user_id); Supabase Postgres handles disk-level
  -- encryption at rest as part of the managed service. The matchable
  -- form is `phone_hash` (SHA-256 with server salt).
  phone            TEXT,
  phone_hash       TEXT,
  level            INT NOT NULL DEFAULT 1,
  total_xp         INT NOT NULL DEFAULT 0,
  weekly_xp        INT NOT NULL DEFAULT 0,
  current_streak   INT NOT NULL DEFAULT 0,
  longest_streak   INT NOT NULL DEFAULT 0,
  last_active_at   TIMESTAMPTZ,
  username_locked_until TIMESTAMPTZ,
  schema_version   INT NOT NULL DEFAULT 1,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at       TIMESTAMPTZ
);

CREATE INDEX idx_public_profiles_phone_hash
  ON public_profiles(phone_hash)
  WHERE phone_hash IS NOT NULL AND deleted_at IS NULL;

CREATE INDEX idx_public_profiles_username_lower
  ON public_profiles(LOWER(username))
  WHERE deleted_at IS NULL;

CREATE INDEX idx_public_profiles_weekly_xp
  ON public_profiles(weekly_xp DESC)
  WHERE deleted_at IS NULL;

-- ─────────────────────────────────────────────────────────────────
-- friendships — the friend graph
-- ─────────────────────────────────────────────────────────────────

CREATE TABLE friendships (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  sender_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  receiver_id   UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status        friendship_status NOT NULL DEFAULT 'pending',
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (sender_id <> receiver_id)
);

-- A given pair has at most one row regardless of who initiated.
-- Use LEAST/GREATEST so (A, B) and (B, A) collide on the same key.
CREATE UNIQUE INDEX idx_friendships_unique_pair
  ON friendships(LEAST(sender_id, receiver_id), GREATEST(sender_id, receiver_id));

CREATE INDEX idx_friendships_sender   ON friendships(sender_id, status);
CREATE INDEX idx_friendships_receiver ON friendships(receiver_id, status);

-- ─────────────────────────────────────────────────────────────────
-- report_log — abuse reports (server-readable only)
-- ─────────────────────────────────────────────────────────────────

CREATE TABLE report_log (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  reporter_id  UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  reported_id  UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  reason       TEXT NOT NULL CHECK (length(reason) BETWEEN 1 AND 500),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (reporter_id <> reported_id)
);

CREATE INDEX idx_report_log_reported ON report_log(reported_id, created_at DESC);

-- ─────────────────────────────────────────────────────────────────
-- reserved_usernames — blocklist consulted at signup
-- ─────────────────────────────────────────────────────────────────

CREATE TABLE reserved_usernames (
  username CITEXT PRIMARY KEY
);

-- ─────────────────────────────────────────────────────────────────
-- rpc_call_log — rate-limit ledger for hot RPCs
-- ─────────────────────────────────────────────────────────────────

CREATE TABLE rpc_call_log (
  id          BIGSERIAL PRIMARY KEY,
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  rpc_name    TEXT NOT NULL,
  called_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_rpc_call_log_user_rpc_time
  ON rpc_call_log(user_id, rpc_name, called_at DESC);

-- ─────────────────────────────────────────────────────────────────
-- cloud_player — singleton-per-user (mirror of local `player`)
-- ─────────────────────────────────────────────────────────────────

CREATE TABLE cloud_player (
  cloud_id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id           UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name      TEXT NOT NULL,
  age               INT NOT NULL DEFAULT 0,
  height_cm         REAL NOT NULL DEFAULT 0,
  weight_kg         REAL NOT NULL DEFAULT 0,
  body_fat_estimate TEXT,
  units_pref        TEXT NOT NULL DEFAULT 'metric',
  onboarded_at      TIMESTAMPTZ,
  schema_version    INT NOT NULL DEFAULT 1,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at        TIMESTAMPTZ
);

-- ─────────────────────────────────────────────────────────────────
-- cloud_goals — singleton-per-user (mirror of local `goals`)
-- ─────────────────────────────────────────────────────────────────

CREATE TABLE cloud_goals (
  cloud_id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id           UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  body_type         TEXT,
  priority_muscles  TEXT[] NOT NULL DEFAULT '{}',
  reward_style      TEXT,
  weight_direction  TEXT,
  target_weight_kg  REAL,
  schema_version    INT NOT NULL DEFAULT 1,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at        TIMESTAMPTZ
);

-- ─────────────────────────────────────────────────────────────────
-- cloud_experience — singleton-per-user (mirror of local `experience`)
-- ─────────────────────────────────────────────────────────────────

CREATE TABLE cloud_experience (
  cloud_id        UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  tenure          TEXT,
  equipment       TEXT[] NOT NULL DEFAULT '{}',
  limitations     TEXT[] NOT NULL DEFAULT '{}',
  styles          TEXT[] NOT NULL DEFAULT '{}',
  schema_version  INT NOT NULL DEFAULT 1,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at      TIMESTAMPTZ
);

-- ─────────────────────────────────────────────────────────────────
-- cloud_schedule — singleton-per-user (mirror of local `schedule`)
-- ─────────────────────────────────────────────────────────────────

CREATE TABLE cloud_schedule (
  cloud_id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id          UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  days             INT[] NOT NULL DEFAULT '{}',
  session_minutes  INT,
  schema_version   INT NOT NULL DEFAULT 1,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at       TIMESTAMPTZ
);

-- ─────────────────────────────────────────────────────────────────
-- cloud_notification_prefs — singleton-per-user
-- ─────────────────────────────────────────────────────────────────

CREATE TABLE cloud_notification_prefs (
  cloud_id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id            UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  workout_reminders  BOOLEAN NOT NULL DEFAULT TRUE,
  streak_warnings    BOOLEAN NOT NULL DEFAULT TRUE,
  weekly_reports     BOOLEAN NOT NULL DEFAULT TRUE,
  schema_version     INT NOT NULL DEFAULT 1,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at         TIMESTAMPTZ
);

-- ─────────────────────────────────────────────────────────────────
-- cloud_player_class — singleton-per-user
-- ─────────────────────────────────────────────────────────────────

CREATE TABLE cloud_player_class (
  cloud_id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id            UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  class_key          TEXT NOT NULL,
  assigned_at        TIMESTAMPTZ NOT NULL,
  last_changed_at    TIMESTAMPTZ NOT NULL,
  evolution_history  TEXT[] NOT NULL DEFAULT '{}',
  schema_version     INT NOT NULL DEFAULT 1,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at         TIMESTAMPTZ
);

-- ─────────────────────────────────────────────────────────────────
-- cloud_workouts — append-only workout history
-- ─────────────────────────────────────────────────────────────────

CREATE TABLE cloud_workouts (
  cloud_id        UUID PRIMARY KEY,
  user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  started_at      TIMESTAMPTZ NOT NULL,
  ended_at        TIMESTAMPTZ,
  xp_earned       INT NOT NULL DEFAULT 0 CHECK (xp_earned BETWEEN 0 AND 1500),
  volume_kg       REAL NOT NULL DEFAULT 0 CHECK (volume_kg BETWEEN 0 AND 100000),
  note            TEXT,
  schema_version  INT NOT NULL DEFAULT 1,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at      TIMESTAMPTZ
);

CREATE INDEX idx_cloud_workouts_user_started
  ON cloud_workouts(user_id, started_at DESC)
  WHERE deleted_at IS NULL;

-- ─────────────────────────────────────────────────────────────────
-- cloud_sets — append-only per-set history
-- ─────────────────────────────────────────────────────────────────

CREATE TABLE cloud_sets (
  cloud_id        UUID PRIMARY KEY,
  user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  workout_id      UUID NOT NULL REFERENCES cloud_workouts(cloud_id) ON DELETE CASCADE,
  -- exercise_id refs the deterministic local catalog id; the catalog is
  -- seeded the same way on every device so this is safe cross-device.
  exercise_id     INT NOT NULL,
  set_number      INT NOT NULL CHECK (set_number BETWEEN 1 AND 50),
  weight_kg       REAL CHECK (weight_kg IS NULL OR weight_kg BETWEEN 0 AND 500),
  reps            INT NOT NULL CHECK (reps BETWEEN 0 AND 200),
  rpe             INT CHECK (rpe IS NULL OR rpe BETWEEN 1 AND 10),
  is_pr           BOOLEAN NOT NULL DEFAULT FALSE,
  xp_earned       INT NOT NULL DEFAULT 0 CHECK (xp_earned BETWEEN 0 AND 200),
  completed_at    TIMESTAMPTZ NOT NULL,
  schema_version  INT NOT NULL DEFAULT 1,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at      TIMESTAMPTZ,
  -- Anti-cheat at the row level: no human moves >5000 kg of work in
  -- a single set. See triggers in 005_triggers.sql for additional
  -- per-workout caps.
  CHECK (COALESCE(weight_kg, 0) * reps <= 5000)
);

CREATE INDEX idx_cloud_sets_workout ON cloud_sets(workout_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_cloud_sets_user_completed
  ON cloud_sets(user_id, completed_at DESC)
  WHERE deleted_at IS NULL;
CREATE INDEX idx_cloud_sets_exercise ON cloud_sets(exercise_id);

-- ─────────────────────────────────────────────────────────────────
-- cloud_weight_logs — at most one log per user per day
-- ─────────────────────────────────────────────────────────────────

CREATE TABLE cloud_weight_logs (
  cloud_id        UUID PRIMARY KEY,
  user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  logged_on       DATE NOT NULL,
  weight_kg       REAL NOT NULL CHECK (weight_kg BETWEEN 20 AND 500),
  note            TEXT,
  schema_version  INT NOT NULL DEFAULT 1,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at      TIMESTAMPTZ,
  UNIQUE (user_id, logged_on)
);

CREATE INDEX idx_cloud_weight_logs_user_date
  ON cloud_weight_logs(user_id, logged_on DESC)
  WHERE deleted_at IS NULL;

-- ─────────────────────────────────────────────────────────────────
-- cloud_quests — daily / weekly / boss progress
-- ─────────────────────────────────────────────────────────────────

CREATE TABLE cloud_quests (
  cloud_id        UUID PRIMARY KEY,
  user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type            TEXT NOT NULL CHECK (type IN ('daily', 'weekly', 'boss')),
  title           TEXT NOT NULL,
  description     TEXT,
  target          INT NOT NULL CHECK (target > 0),
  progress        INT NOT NULL DEFAULT 0 CHECK (progress >= 0),
  xp_reward       INT NOT NULL CHECK (xp_reward BETWEEN 0 AND 5000),
  issued_at       TIMESTAMPTZ NOT NULL,
  expires_at      TIMESTAMPTZ,
  completed_at    TIMESTAMPTZ,
  locked          BOOLEAN NOT NULL DEFAULT FALSE,
  schema_version  INT NOT NULL DEFAULT 1,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at      TIMESTAMPTZ
);

CREATE INDEX idx_cloud_quests_user_active
  ON cloud_quests(user_id, type, completed_at, expires_at)
  WHERE deleted_at IS NULL;

-- ─────────────────────────────────────────────────────────────────
-- cloud_muscle_ranks — composite-key per-muscle XP totals
-- ─────────────────────────────────────────────────────────────────

CREATE TABLE cloud_muscle_ranks (
  cloud_id        UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  muscle          TEXT NOT NULL,
  rank            TEXT NOT NULL,
  sub_rank        TEXT,
  rank_xp         INT NOT NULL DEFAULT 0 CHECK (rank_xp >= 0),
  schema_version  INT NOT NULL DEFAULT 1,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at      TIMESTAMPTZ,
  UNIQUE (user_id, muscle)
);

-- ─────────────────────────────────────────────────────────────────
-- cloud_streak — singleton-per-user
-- ─────────────────────────────────────────────────────────────────

CREATE TABLE cloud_streak (
  cloud_id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id               UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  current               INT NOT NULL DEFAULT 0 CHECK (current >= 0),
  longest               INT NOT NULL DEFAULT 0 CHECK (longest >= 0),
  last_active_date      DATE,
  freezes_remaining     INT NOT NULL DEFAULT 1 CHECK (freezes_remaining BETWEEN 0 AND 10),
  freezes_period_start  DATE NOT NULL,
  schema_version        INT NOT NULL DEFAULT 1,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at            TIMESTAMPTZ,
  CHECK (longest >= current)
);

-- ─────────────────────────────────────────────────────────────────
-- cloud_streak_freeze_events — append-only freeze audit
-- ─────────────────────────────────────────────────────────────────

CREATE TABLE cloud_streak_freeze_events (
  cloud_id        UUID PRIMARY KEY,
  user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  used_on         DATE NOT NULL,
  reason          TEXT,
  schema_version  INT NOT NULL DEFAULT 1,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at      TIMESTAMPTZ
);

CREATE INDEX idx_cloud_streak_freezes_user
  ON cloud_streak_freeze_events(user_id, used_on DESC)
  WHERE deleted_at IS NULL;

-- ─────────────────────────────────────────────────────────────────
-- Realtime publication — subscribe to public_profiles updates
-- ─────────────────────────────────────────────────────────────────

-- Supabase Realtime listens on the `supabase_realtime` publication.
-- We add only public_profiles since that's the table the leaderboard
-- subscribes to. Other tables don't need real-time replication for v1.x.0.
ALTER PUBLICATION supabase_realtime ADD TABLE public_profiles;
