-- 001_extensions.sql
-- Postgres extensions required by the LEVEL UP IRL socials backend.
-- Apply once, in order, before anything else.

-- citext: case-insensitive text type, used for usernames so `Kael` / `kael` /
-- `KAEL` collide on the UNIQUE constraint instead of becoming three rows.
CREATE EXTENSION IF NOT EXISTS citext;

-- pgcrypto: provides `digest(...)` for SHA-256 phone hashing inside the
-- `find_users_by_phone_hashes` RPC, plus encryption helpers we use to
-- store raw phone numbers encrypted at rest.
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- uuid-ossp: `uuid_generate_v4()` for cloud_id defaults across every
-- mirrored table. Note: Supabase's gen_random_uuid() (from pgcrypto)
-- works equally well; we use uuid-ossp for naming clarity and to keep
-- the migration explicit.
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- pg_cron: schedules the nightly purge of soft-deleted rows older than
-- 30 days. See 007_cron.sql.
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- supabase_vault: stores the PHONE_HASH_SALT secret out of the database
-- proper. Read via `vault.read_secret(...)` from RPCs.
CREATE EXTENSION IF NOT EXISTS supabase_vault;
