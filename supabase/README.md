# Supabase backend — LEVEL UP IRL socials + Scope B sync

This directory contains the database schema, RLS policies, RPCs, and anti-cheat triggers
for the v1.x.0 social tier. Implements [socials_plan.md](../socials_plan.md) S0.

The Flutter app talks to a real Supabase project (Postgres + Auth + Realtime). Local sqflite
remains the read path on every device; Supabase mirrors every domain table for cross-device
restore and friend leaderboards.

## Directory layout

```
supabase/
  migrations/
    001_extensions.sql           -- citext, pgcrypto, uuid-ossp
    002_schema.sql               -- the ~13 cloud-mirrored tables + friendships + reports
    003_rls.sql                  -- Row-Level Security policies
    004_rpcs.sql                 -- find_users_by_phone_hashes / delete_my_account / disconnect_socials
    005_triggers.sql             -- anti-cheat caps + updated_at auto-bump
    006_seed.sql                 -- reserved-usernames blocklist
    007_cron.sql                 -- nightly purge of soft-deleted rows + Monday weekly_xp rollover
    008_phone_column_fix.sql     -- swaps placeholder phone_encrypted BYTEA for plain phone TEXT
    009_friend_graph_rpc.sql     -- list_my_friend_graph RPC for FriendsScreen
    010_username_check_public.sql -- grants check_username_available to anon (pre-auth lookup)
    011_monthly_xp.sql           -- adds monthly_xp column + delta-cap trigger + 1st-of-month cron
  README.md                      -- this file
```

## What you (the human) need to do once

These steps are **manual** — they touch the Supabase project, which only you can administer.
Run them once, then never again until the next schema migration.

### 1. Create the project

- Go to https://supabase.com → Sign up (free).
- New Project → name `level-up-irl-prod` (and a separate `level-up-irl-dev` for testing if you want).
- **Region:** Mumbai (`ap-south-1`) for India-first launch.
- **Database password:** generate a strong one, store in 1Password / your password manager.
- Wait ~2 minutes for the project to provision.

### 2. Apply the migrations in order

Easiest path (no Supabase CLI install required):

- In the Supabase dashboard → **SQL Editor** → New query.
- Open `migrations/001_extensions.sql`, paste, click `Run`.
- Repeat for every migration file in numerical order — `002_schema.sql` through `011_monthly_xp.sql`. Strictly in order.
- After each, check the Table Editor / Database → Functions / Database → Triggers to confirm objects appeared.

Faster path (Supabase CLI):

```bash
brew install supabase/tap/supabase           # one-time
supabase login                                # one-time
supabase link --project-ref <your-ref>        # one-time
supabase db push                              # applies all pending migrations
```

### 3. Configure auth

In the dashboard:

- **Authentication → Providers → Email**: enable. Confirm email required = ON.
- **Authentication → Settings**:
  - Site URL: `https://levelup-irl.app` (or your eventual domain — placeholder is fine for dev).
  - Redirect URLs: add `levelupirl://reset-password` (for the in-app password reset deep link).
  - JWT expiry: 3600 (default — 1 hour access tokens, refresh tokens last 30 days).
- **Authentication → Email Templates**: customize the `Confirm signup` and `Reset password` emails when you have time. Defaults are fine for v1.x.0 dev.

### 4. Generate the phone-hash server salt

The salt is what makes phone-hashing not-trivially-reversible. It must:
- Be ≥ 32 random bytes.
- Live ONLY on the server. Never check it into git. Never put it in app config.

In **Project Settings → Vault → Secrets**, create a secret named `PHONE_HASH_SALT` with value:

```bash
# Generate it locally with:
openssl rand -hex 32
# Paste the resulting hex string into Supabase Vault.
```

The `find_users_by_phone_hashes` RPC reads this from the Vault at runtime via `vault.read_secret('PHONE_HASH_SALT')`.

### 5. Grab the project URL and anon key

- **Project Settings → API**:
  - **Project URL** (`https://<project-ref>.supabase.co`)
  - **anon / public key** (long JWT)

Both go into a **`.env` file at the Flutter repo root** (gitignored, never committed):

```env
SUPABASE_URL=https://abcdefgh.supabase.co
SUPABASE_ANON_KEY=eyJ...long-jwt...
```

The Flutter app will load this via `flutter_dotenv` on cold launch (Phase S1 work).

### 6. Service-role key — do NOT put in the app

Project Settings → API also shows a **service_role key**. This bypasses RLS and is for migrations only.
- Add it as `SUPABASE_SERVICE_ROLE_KEY` to a **separate** `.env.migrations` file used only by CI / local migration scripts.
- **Never** put it in the Flutter app's `.env`. Anyone with this key can read/write every user's data.

## Security baseline (what these migrations enforce)

The migrations enforce, at the **database** layer (i.e. the Flutter app cannot bypass these
even if its anon key is leaked):

- **RLS on every user-data table.** A user can read/write their own rows only. `public_profiles` has a special exception: friends with `accepted` status can read each other's profile rows.
- **Phone hashed with a server-side salt** stored in Vault. App never sees the salt.
- **Phone column encrypted at rest** with `pgcrypto`. DB dump leak doesn't expose raw numbers.
- **Per-row anti-cheat caps:** `weight_kg × reps ≤ 5000` per set, `xp_earned ≤ 1500` per workout, `weekly_xp` delta ≤ 1500 per push, `monthly_xp` delta ≤ 6000 per push, `current_streak` increment ≤ 1 per local day, `total_xp` monotonically increasing.
- **Rate-limits on hot RPCs:** contact-match 5/hour/user, friend-request 50/day/user, username search 30/min/user.
- **Idempotent UPSERT** on every push (keyed by `cloud_id` UUID), so re-pushes don't duplicate.
- **Soft-delete + 30-day cron purge** so rows can be undeleted within a window.
- **Username blocklist** (`admin`, `support`, `levelupirl`, etc.) seeded into a `reserved_usernames` table.

If any of this seems off, flag before applying the migrations to a real project — easier to
fix the SQL than to re-baseline a populated database.

## Migration-rollback policy

Every numbered migration applies forward only. To roll back:

- For schema changes: write a new `00N_revert_*.sql` that explicitly drops the columns/tables/policies the broken migration added. Never edit a migration that's already been applied to prod.
- For data corruption: restore from the daily Supabase backup (free tier: 7-day retention; paid tier: longer + point-in-time recovery).

## What's next (after S0 — these aren't done in this directory)

- **S1** — Auth screens in the Flutter app (`lib/screens/socials/sign_up_screen.dart` etc.) talking to `supabase.auth.signUp(...)` / `signInWithPassword(...)`.
- **S2** — Username + phone collection screens, push to `public_profiles` UPSERT.
- **S3** — `SyncEngine` service in `lib/data/sync/` that drains the `sync_outbox` and pushes to Supabase.
- **S3b** — Initial-sync UX on new-device sign-in.
- See [socials_plan.md §3](../socials_plan.md) for the full phase breakdown.
