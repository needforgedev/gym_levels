# LEVEL UP IRL — Socials & Leaderboard Plan

**Companion to:** [plan.md](plan.md) (main implementation plan) + [PRD_GamifiedFitnessApp.md](PRD_GamifiedFitnessApp.md)
**Stack additions:** Supabase (Postgres + Auth + Realtime). No other backend.
**Sync scope:** **Scope B — full cloud sync** (locked 2026-04-29). Every domain table on the device mirrors to Supabase; device switch restores 100% of state.
**Last updated:** 2026-04-30

**Implementation progress:**

- **S0 — Backend setup:** ✓ done (8 SQL migrations applied to Supabase project `vhlmogzajbugcpqossbs`, Mumbai region). End-to-end smoke-tested 2026-04-29 — sign up, claim handle, save phone, walk onboarding to Home, all four columns populated correctly on `public_profiles`.
- **S1 — Auth screens:** ✓ done + smoke-tested. Deep-link URL-scheme registration on native side still pending (see S1 sub-bullet).
- **S2 — Username + phone:** ✓ done + smoke-tested. Live availability check round-trips to Supabase and reflects taken/reserved/available correctly; phone hashing into `phone_hash` confirmed via SQL inspection.
- **S3 — Cloud sync engine:** ✓ push side complete (S3.0–S3.3, 2026-04-30). Local schema migrated to v2 with `cloud_id`/`cloud_updated_at`/`cloud_deleted_at` on every cloud-mirrored table + new `sync_outbox` + `sync_state` tables. Outbox CRUD with attempt-aware exponential backoff (60s → 16m, dead-letter at 5). SyncEngine drains FIFO under a mutex; SyncLifecycle drains on app foreground + every 30s while foregrounded. 13 production push handlers translate local-row JSON → Supabase upsert/soft-delete (singletons conflict on `user_id`, append-only on `cloud_id`, muscle_ranks on `(user_id, muscle)`, weight_logs on `(user_id, logged_on)`). Sets pre-resolve their parent workout's cloud_id at enqueue time. Sign-out clears the outbox + resets sync state so a different user can't push the previous one's pending rows.
- **S3b — Initial-sync UX:** ✓ done (2026-04-30). 13 pull handlers mirror the push handlers in reverse, paginating Supabase fetches (200 rows per page) and writing into local sqflite idempotently (lookup-by-cloud_id then UPDATE-or-INSERT for append-only; REPLACE-by-natural-key for singletons + composite-keyed). `InitialSync` orchestrator pulls in priority order — profile + onboarding answers first (so onboarding is skipped on the new device), then ranks/streak/class (so Home renders), then workouts → sets → quests → freeze events → weight logs (the bulk). Resumable cursor in `sync_state` (`initial_sync_table` + `initial_sync_offset`) survives mid-sync kills. Welcome-back screen drives the orchestrator with a progress bar + per-table label + retry/skip CTAs. Sign-in branches: first-time device → `/welcome-back`, returning device → straight to `/home`. After hydration, the global `isOnboardedNotifier` is refreshed from the pulled `player.onboarded_at` so the router's redirect respects the new state.
- **S3c — Incremental pull (cross-device delta propagation, added 2026-04-30 after smoke testing):** ✓ done (2026-04-30). Added `pullSince(since)` to `PullHandler`; `_CloudPullHandler` implementation calls `.gt('updated_at', sinceIso).order('updated_at').limit(500)` and branches per-row on `deleted_at` (delete-by-cloud-id vs upsert). New [`IncrementalPull`](lib/data/sync/incremental_pull.dart) orchestrator runs after every push drain (foreground + 30s) — snapshots `cutoff = now()` *before* fetching, walks tables in [`kPullPriorityOrder`](lib/data/sync/pull_handler.dart) using `state.lastFullSyncAt` as the `since` cursor, and on full success advances the cursor to `cutoff`. Failure mid-pass leaves the cursor untouched so the next tick retries the missed range. Wired into [`SyncEngine.drainOnce`](lib/data/sync/sync_engine.dart) — push first, then incremental pull, both inside the engine's mutex. Closes the multi-device gap: two devices on the same account now converge within ~30s without a manual sign-out / sign-in. **Smoke-tested 2026-04-30** — workouts logged offline on phone surfaced on simulator within seconds of phone reconnecting + simulator foregrounding.
- **S4 — Contact-match flow:** ✓ done (2026-04-30). flutter_contacts + share_plus deps added. Native permissions wired: Android `READ_CONTACTS`, iOS `NSContactsUsageDescription`. [`ContactMatchService.scanAndMatch`](lib/data/services/contact_match_service.dart) reads contacts → strips non-digit chars → requires explicit `+` country code (skips ambiguous numbers; counts skipped) → SHA-256-hashes with server salt → batches up to 1000 hashes per RPC call to `find_users_by_phone_hashes` → de-dups matches by user_id. [`FriendService.sendRequest`](lib/data/services/friend_service.dart) inserts a `friendships` row with `status='pending'` (defaults applied server-side); idempotent against the unique-pair index → returns `alreadyExists: true` on duplicate. [`ContactsPermissionScreen`](lib/screens/auth/contacts_permission_screen.dart) shows a 3-row privacy explainer (numbers stay on device, names+emails stay private, hashes deleted after match) before triggering the OS prompt. [`FriendsFoundScreen`](lib/screens/auth/friends_found_screen.dart) renders three states: list of matches with per-row Add button (idle → sending → sent / error), zero-matches empty state with `Share.share` invite link, error banner when scan/RPC failed. Inserted into the post-paywall flow: `/loader-pre-home` now routes to `/contacts-permission` instead of `/home`. Settings hub entry deferred to S7.
- S5–S10: not started.

**Dev-only configuration currently in effect** (revert before launch):

- **Email verification turned OFF** in Supabase Auth → Settings. Reason: default redirect target is `localhost:3000`, which fails when clicked from an email on a real device. To re-enable: configure Site URL + Redirect URLs to `levelupirl://email-confirmed` *and* register the URL scheme in `Info.plist` + `AndroidManifest.xml` (S1 follow-up). Until then, signups skip the verify-email screen and land directly on `/register`.

This document tracks the **social tier** — the opt-in feature set that adds an account, friends, contact discovery, a leaderboard, and **full cloud sync of all gameplay data** on top of the offline-first local engine. It corresponds to a **v1.1 release** in the main `plan.md` Phase 4 roadmap, pulled forward and broken into shippable milestones here.

## Status legend

Same as [plan.md](plan.md):

- `[x]` — done and merged
- `[~]` — in progress
- `[ ]` — not started
- `[!]` — blocked (annotate with reason)
- `[—]` — out of scope for this release (deferred)

## Goal in one sentence

Let users sign up, find friends already on the app via their phone contacts, and compete on a friend-only leaderboard tracking weekly XP, current streak, and all-time XP — while **every workout, set, weight log, quest, muscle rank, and onboarding answer mirrors to Supabase** so device switches restore the full app state, all without breaking the offline-first guarantee for any user-visible action.

---

# 1. Architecture

## 1.1 Two-layer model (the load-bearing invariant)

| Layer | What lives here | Network behaviour |
|---|---|---|
| **Layer 1 — Local sqflite (unchanged on the read path)** | Every domain table. App reads exclusively from sqflite. Cold launch, all gameplay, all reads — zero network hops. | Identical to today's app. Workouts log, ranks recompute, quests progress, leaderboard caches — all from local rows. |
| **Layer 2 — Supabase mirror (new, opt-in)** | A 1:1 cloud mirror of every Layer 1 table for users who've signed up + opted in. Source of truth on device-switch / reinstall. | Pushes opportunistically after every local write; retries via outbox queue when offline. Pulls only on first-time sign-in (initial hydration) and Realtime subscriptions for the leaderboard. |

**Critical property — offline-first preserved:** the app **never blocks on a network call**. Every gameplay write commits to local sqflite first; the cloud push is a fire-and-forget side effect that queues if offline. Layer 1 has zero dependency on Layer 2. If Supabase is down, the app keeps working; pushes accumulate in the outbox and drain when the connection returns.

**If the user opts out of socials**, Layer 2 is dormant — no auth, no network, no behavioural difference from today's app.

## 1.2 What syncs vs. what stays local (Scope B)

**Cloud-mirrored (Layer 2):** every table that represents user data.

| Table | Local | Cloud | Notes |
|---|---|---|---|
| `auth.users` (email + password + verified flag) | — | ✓ | Supabase Auth managed |
| `public_profiles` (username, display_name, avatar, level, total_xp, weekly_xp, current_streak, longest_streak, last_active_at, phone, phone_hash) | local mirror | ✓ | Drives leaderboard reads + contact match. RLS clamps reads to friends; raw `phone` only readable by the row owner. |
| `workouts` | ✓ | ✓ | Append-only history |
| `sets` | ✓ | ✓ | Append-only |
| `weight_logs` | ✓ | ✓ | Append-only |
| `quests` (current + historical) | ✓ | ✓ | Includes daily/weekly/boss progress |
| `muscle_ranks` | ✓ | ✓ | Per-muscle XP totals |
| `streak` + `streak_freeze_events` | ✓ | ✓ | |
| `goals` (body type, priority muscles, target weight, etc.) | ✓ | ✓ | Onboarding answers — Section 2 |
| `experience` (equipment, limitations, training styles, tenure) | ✓ | ✓ | Onboarding answers — Section 3 |
| `schedule` (training days, session minutes) | ✓ | ✓ | Onboarding answers — Section 5 |
| `notification_prefs` | ✓ | ✓ | Onboarding answers — Section 6 |
| `player` (display name, age, height, weight, body fat) | ✓ | ✓ | PII — RLS-clamped to owner; Supabase managed disk-level encryption at rest |
| `player_class_row` (class assignment + evolution history + buffs) | ✓ | ✓ | |
| `friendships` | local cache | ✓ (source) | Friend graph |
| `report_log` | — | ✓ | Server-only abuse log |

**Local-only (never leaves device):**

| Item | Why |
|---|---|
| `exercise_catalog` (80-row seed) | Identical across all devices; seeded from `exercise_catalog.dart`. No need to sync. |
| `sync_outbox` (new local table) | Pending push queue. Drains to Supabase, then deleted locally. |
| `analytics_events` outbox | Phase 2.7 work — separate flush path to PostHog, not via Supabase. |
| Schema-version tracking rows | Per-device migration state. |

**Pattern:** the device is an **offline cache + write buffer**; Supabase is the **source of truth** on device-switch. Reads always hit sqflite (no Supabase round-trip on the hot path). Writes commit to sqflite synchronously, then enqueue a cloud push via the outbox. On a fresh install + sign-in, the app pulls every table down once from Supabase, hydrates local sqflite, and resumes normal operation.

## 1.3 Identity strategy — global IDs without a local schema migration

Every locally-synced table gets a new nullable `cloud_id UUID` column. On first sync, the device generates a UUID for each row that hasn't been pushed yet and writes it back locally + to Supabase. From then on:

- **Local PK** stays as today's auto-increment int — no app refactor needed.
- **Cloud PK** is the `cloud_id` UUID — globally unique across users + devices.
- **Cross-device row identity** is the `cloud_id`. When the new device pulls down the user's data, it generates fresh local int PKs and stores the same `cloud_id` from Supabase; future local writes reference the local int.

This avoids the massive intrusive change of switching every local PK to a UUID, while still giving us a globally unique identifier for sync.

## 1.4 Auth choice: email + password (unchanged from Scope A locked decision)

- Cheapest infrastructure: no SMS provider, no Apple Developer config, no DLT registration in India.
- Forgot-password flow built into Supabase, free, works out of the box.
- Cross-platform (iOS, Android, eventually web).
- Trade-off: email is a slightly weaker identifier than phone or Apple ID. Acceptable.

Phone number is **collected separately, after auth, without OTP verification** — used purely as a contact-match key, not as a credential.

## 1.5 Friend discovery: contact-match primary, invite link in same release (unchanged)

- **Contact-match (primary):** address book → SHA-256 hashes with server salt → Supabase RPC returns matching `user_id`s.
- **Invite link (mandatory companion):** unique deep link, shared via WhatsApp / iMessage / etc.
- **Username search (small companion):** `@kael_irl` handle lookup.
- **QR code:** deferred to v1.x.1 polish.
- **Friend-of-friend suggestions:** deferred to v1.x.2+.

## 1.6 Conflict resolution

- **Append-only tables** (`workouts`, `sets`, `weight_logs`, completed `quests`, `streak_freeze_events`, `player_class.evolution_history`): rows are immutable once written. The `cloud_id` deduplicates across re-pushes. No conflict possible.
- **Mutable tables** (`public_profiles`, `goals`, `experience`, `schedule`, `notification_prefs`, `player`, `muscle_ranks`, current-cycle `quests`, `streak`): last-write-wins via `updated_at` timestamp. Server rejects pushes with stale `updated_at`; client retries with the server's row, locally re-applies, re-pushes.
- **Two-device race** (same user signed in on two devices, edits the same mutable row simultaneously): whichever push the server processes second wins. We accept this — it's vanishingly rare for the relevant rows (no one edits their goals from two devices at the same time).

## 1.7 Initial-sync UX (new-device hydration)

When a returning user signs in on a fresh install, the app pulls down every cloud-mirrored table for that user. For a heavy user (~1000 workouts, ~10K sets, ~500 weight logs), this is ~MBs of data and may take 10-30 seconds on a slow connection. UX:

- **Welcome-back screen** with progress bar: "Restoring your training history… 47%".
- **Pull tables in priority order:** `public_profiles` + `goals`/`experience`/`schedule` first (so onboarding can be skipped), then `muscle_ranks` + `streak` + `player_class` (so Home renders correctly), then `workouts` + `sets` (the bulk).
- **Pages of 200 rows** for the heavy tables to keep memory bounded.
- **Resumable** — if the user kills the app mid-sync, on next launch we pick up from the last successfully-fetched page.

---

# 2. Data model

## 2.1 Tables — Supabase

For every table mirrored from Layer 1, the Supabase row carries:

- `cloud_id` UUID PRIMARY KEY (matches the local `cloud_id` column on the device)
- `user_id` UUID FK to `auth.users` — the row's owner
- `updated_at` timestamptz — for conflict resolution
- `deleted_at` timestamptz NULLABLE — soft-delete flag (so cross-device delete is propagated; rows are physically purged after 30 days by a cron job)
- `schema_version` int — forward-compat
- `created_at` timestamptz

…plus the table-specific columns (mirroring the local table's schema 1:1).

**Tables mirrored (~13):**

- `public_profiles` — same schema as Scope A. Driving table for leaderboard + contact match.
- `cloud_workouts` — id, user_id, started_at, ended_at, xp_earned, volume_kg, plus sync columns
- `cloud_sets` — id, workout_id (FK to cloud_workouts.cloud_id), user_id, exercise_id (refs deterministic local catalog id), set_number, weight_kg, reps, rpe, is_pr, xp_earned, completed_at, sync columns
- `cloud_weight_logs` — id, user_id, logged_on, weight_kg, note, sync columns
- `cloud_quests` — id, user_id, type, kind_key, title, target, progress, xp_reward, issued_at, expires_at, completed_at, sync columns
- `cloud_muscle_ranks` — id, user_id, muscle, rank, sub_rank, rank_xp, updated_at
- `cloud_streak` — singleton-per-user; current, longest, last_workout_on, freezes_available, freezes_used, schedule_match_count
- `cloud_streak_freeze_events` — append-only; id, user_id, used_on, reason
- `cloud_goals` — singleton-per-user; body_type, priority_muscles[], target_weight_kg, weight_direction
- `cloud_experience` — singleton-per-user; tenure, equipment[], limitations[], training_styles[]
- `cloud_schedule` — singleton-per-user; days[], session_minutes
- `cloud_notification_prefs` — singleton-per-user; workout_reminders, streak_warnings, weekly_report
- `cloud_player` — singleton-per-user (mirror of local `player`); display_name, age, height_cm, weight_kg, body_fat_estimate, onboarded_at — PII, RLS-clamped to the owning user (Supabase managed disk-level encryption at rest)
- `cloud_player_class` — singleton-per-user; class_key, assigned_at, last_changed_at, evolution_history[]
- `friendships` — sender_id, receiver_id, status, created_at, updated_at
- `report_log` — reporter_id, reported_id, reason, created_at

(Singleton-per-user tables enforce uniqueness via `UNIQUE (user_id)`.)

## 2.2 RLS policies

Postgres-enforced — clients cannot bypass these regardless of what the app sends.

**Owned-row tables** (`cloud_workouts`, `cloud_sets`, `cloud_weight_logs`, `cloud_quests`, `cloud_muscle_ranks`, `cloud_streak`, `cloud_streak_freeze_events`, `cloud_goals`, `cloud_experience`, `cloud_schedule`, `cloud_notification_prefs`, `cloud_player`, `cloud_player_class`):

- SELECT, INSERT, UPDATE, DELETE: **only if `user_id = auth.uid()`**. Single policy, applied to every owned-row table.
- No friend or anyone-else access — workout history, weights, body data are strictly per-user.

**`public_profiles`** (special — friend-readable):

- SELECT: own row OR rows where `friendships` has an `accepted` row between viewer and the row's `user_id`.
- INSERT/UPDATE/DELETE: only on own row.

**`friendships`:**

- SELECT: visible if `auth.uid() = sender_id` or `auth.uid() = receiver_id`.
- INSERT: only with `sender_id = auth.uid()`. New rows must start `status = 'pending'`.
- UPDATE: only `receiver_id = auth.uid()` for accept/decline. Either side can transition to `'blocked'`.
- DELETE: either side, "remove friend".

**`report_log`:**

- SELECT: server-only.
- INSERT: only `reporter_id = auth.uid()`.

## 2.3 Server-side anti-cheat

**RPC functions:**

- `find_users_by_phone_hashes(hashes text[])` → `user_id[]`. Rate-limited 5/hour/user.
- `delete_my_account()` — atomic purge of every cloud row owned by the user + the auth row.
- `disconnect_socials()` — purges `public_profiles` + `friendships` only; keeps the rest of the user's cloud data so they can re-enable socials later without losing history.

**Triggers (anti-cheat at the row level):**

- **`enforce_set_caps`** on `cloud_sets` INSERT — rejects sets where `weight_kg × reps > 5000` (anti-cheat against client-side volume forging — no human deadlifts 500kg×10).
- **`enforce_workout_xp_cap`** on `cloud_workouts` INSERT — caps `xp_earned` at 1500 per row.
- **`enforce_weekly_xp_delta`** on `public_profiles` UPDATE — caps `weekly_xp` increase at 1500 per push.
- **`enforce_streak_increment`** on `public_profiles` UPDATE — `current_streak` can only increment by 1 per local day per user.
- **`enforce_total_xp_monotonic`** on `public_profiles` UPDATE — `total_xp` cannot decrease (except via `delete_my_account`).

---

# 3. Phased milestones

Each milestone is independently shippable for review; the full release ships when S0–S10 are all green. S11 (onboarding-answer sync) from the prior Scope A plan is now **absorbed into S3** since onboarding answers are just one of many tables that get synced. S12 (QR + friend-of-friend) remains post-launch polish.

## S0 — Backend setup ✓ done (2026-04-29)

- [x] Create Supabase project (Mumbai region, project `vhlmogzajbugcpqossbs`).
- [x] Generate the server salt for phone hashing. **Action item for the user:** store `PHONE_HASH_SALT` in both Supabase Vault and the local `.env` (same value).
- [x] Apply schema for all ~13 cloud tables — [supabase/migrations/002_schema.sql](supabase/migrations/002_schema.sql). Indexes on `phone_hash`, `username`, `(user_id, completed_at)` on cloud_sets, etc.
- [x] Apply RLS policies — [supabase/migrations/003_rls.sql](supabase/migrations/003_rls.sql). Owned-row template applied to all 13 cloud tables via DO block; bespoke policies on `public_profiles`, `friendships`, `report_log`.
- [x] Implement RPC functions — [supabase/migrations/004_rpcs.sql](supabase/migrations/004_rpcs.sql): `check_username_available`, `find_users_by_phone_hashes`, `search_users_by_username`, `disconnect_socials`, `delete_my_account`, `report_user`.
- [x] Implement anti-cheat triggers — [supabase/migrations/005_triggers.sql](supabase/migrations/005_triggers.sql): `weekly_xp_delta`, `total_xp_monotonic`, `streak_increment_cap`, `username_lock`, `updated_at` auto-bump.
- [x] Configure email auth via Supabase dashboard.
- [x] Configure cron job — [supabase/migrations/007_cron.sql](supabase/migrations/007_cron.sql): nightly soft-delete purge, daily rpc_call_log cleanup, Monday 00:00 UTC weekly_xp rollover.
- [x] **Schema fix-up** — [supabase/migrations/008_phone_column_fix.sql](supabase/migrations/008_phone_column_fix.sql) (2026-04-29). Drops the `phone_encrypted BYTEA` column declared but never wired by 002, replaces with plain `phone TEXT`. Required because PostgREST returned "Could not find the 'phone' column" during smoke testing. RLS already keeps the raw value owner-only; Supabase managed disk-level encryption covers the at-rest story.
- [x] **End-to-end smoke test passed** (2026-04-29) — created user via app, walked sign up → handle → phone → home, confirmed via SQL inspection that `auth.users` + `public_profiles` rows landed correctly with username, display_name, phone (E.164), and phone_hash all populated. Cross-user RLS denial tests + friendship-gated SELECT will land alongside S3 wire-up so they exercise the full sync path.

## S1 — Auth screens ✓ done (2026-04-29)

- [x] Sign Up screen — [lib/screens/auth/sign_up_screen.dart](lib/screens/auth/sign_up_screen.dart). Email + password + password-strength meter + terms-of-service checkbox.
- [x] Sign In screen — [lib/screens/auth/sign_in_screen.dart](lib/screens/auth/sign_in_screen.dart). Email + password + "Forgot password?" link.
- [x] Email verification gate — [lib/screens/auth/verify_email_screen.dart](lib/screens/auth/verify_email_screen.dart). "Check your email" + Resend (60s cooldown) + "I've verified — continue" + Skip-for-now. Auto-detects via `authStateChanges` stream when the deep link lands.
- [x] Forgot-password flow — [lib/screens/auth/forgot_password_screen.dart](lib/screens/auth/forgot_password_screen.dart) sends Supabase's reset email; [lib/screens/auth/reset_password_screen.dart](lib/screens/auth/reset_password_screen.dart) is the deep-link landing for the new-password form.
- [x] All auth state managed via [lib/data/services/auth_service.dart](lib/data/services/auth_service.dart) — thin wrapper over `Supabase.instance.client.auth` returning `(bool ok, String? errorMessage)` records.
- [ ] **Logout button in Settings** — deferred to S7 (Settings + opt-out + delete) since the Settings screen surface lands together. `AuthService.signOut()` is built; the UI button isn't.
- [ ] **Deep-link URL-scheme registration** (iOS Info.plist + Android AndroidManifest) for `levelupirl://email-confirmed` and `levelupirl://reset-password`. Currently the user must manually return to the app and tap "I've verified" after clicking the email link. ~30 min of native config — flag for a quick follow-up.

## S2 — Username + phone collection ✓ done (2026-04-29)

- [x] Pick Username screen — [lib/screens/auth/username_screen.dart](lib/screens/auth/username_screen.dart). Live availability check via `check_username_available` RPC (320ms debounce), inline status icon + label, `[a-z0-9_]` input filter, 30-day rename lock enforced server-side via the `username_lock` trigger.
- [x] Phone Number screen — [lib/screens/auth/phone_screen.dart](lib/screens/auth/phone_screen.dart). E.164 input with 30-country picker (India default), privacy disclosure card, "Save Phone" + "Skip for now" CTAs with consequence message.
- [x] On submit: pushes `phone` (raw) + `phone_hash` (SHA-256 with server salt via [lib/data/supabase/phone_hasher.dart](lib/data/supabase/phone_hasher.dart)) to `public_profiles` via [lib/data/services/public_profile_service.dart](lib/data/services/public_profile_service.dart).
- [ ] **Settings screen entry to update phone later** — deferred to S7 (Settings hub lands together).

## S3 — Cloud sync engine — full coverage (~6-8 days, was 2)

This is the heart of Scope B. A generic, table-agnostic sync engine plus per-table push/pull handlers.

**Push side (S3.0–S3.3) — done 2026-04-30. Pull side (S3.4) folded into S3b.**

- [x] **S3.0 — Local schema migration** ([lib/data/schema.dart](lib/data/schema.dart) v1→v2; [lib/data/app_db.dart](lib/data/app_db.dart) `_migrateV1toV2`). Adds nullable `cloud_id TEXT` + `cloud_updated_at INTEGER` + `cloud_deleted_at INTEGER` to all 13 cloud-mirrored tables via idempotent `ALTER TABLE ADD COLUMN`. Creates `sync_outbox` (FIFO push queue with 2 partial indexes for fast pending/pruned lookups) + `sync_state` singleton (drives initial-sync resumability + drain telemetry).
- [x] **S3.1 — SyncEngine skeleton.**
  - [x] [lib/data/services/sync_outbox_service.dart](lib/data/services/sync_outbox_service.dart) — outbox CRUD with attempt-aware backoff filter on `nextBatch`. Exponential backoff: 60s, 2m, 4m, 8m, 16m. Dead-letter at `kMaxAttempts = 5`.
  - [x] [lib/data/services/sync_state_service.dart](lib/data/services/sync_state_service.dart) — singleton CRUD: `get()`, `save()`, `recordDrainAttempt()`, `setInitialSyncProgress()`, `markFullSyncComplete()`, `reset()`.
  - [x] [lib/data/sync/push_handler.dart](lib/data/sync/push_handler.dart) — `PushHandler` interface + `PushHandlerRegistry` with `.skeleton()` (no-op stubs) and a `.production()` extension factory.
  - [x] [lib/data/sync/sync_engine.dart](lib/data/sync/sync_engine.dart) — drain loop with in-process mutex, auth gate (no-op when signed out), per-row dispatch, `DrainReport` telemetry. Stamps `last_outbox_drain_at` and prunes pushed rows after every pass.
  - [x] [lib/data/sync/sync_lifecycle.dart](lib/data/sync/sync_lifecycle.dart) — `WidgetsBindingObserver`. Drains on `AppLifecycleState.resumed` + every 30s while foregrounded; pauses the timer on `paused`/`detached` to save battery.
  - [x] Wired into [lib/main.dart](lib/main.dart) after Supabase init.
  - [x] [`AuthService.signOut()`](lib/data/services/auth_service.dart) clears the outbox + resets sync_state so a different user can't push the previous one's pending operations.
- [x] **S3.2 — Per-table push handlers** ([lib/data/sync/cloud_push_handlers.dart](lib/data/sync/cloud_push_handlers.dart)) — 13 concrete handlers grouped by shape:
  - **Singletons** (`onConflict: 'user_id'`, soft-delete by `user_id`): `PlayerHandler`, `GoalsHandler`, `ExperienceHandler`, `ScheduleHandler`, `NotificationPrefsHandler`, `PlayerClassHandler`, `StreakHandler`.
  - **Append-only** (`onConflict: 'cloud_id'`, soft-delete by `cloud_id`): `WorkoutsHandler`, `SetsHandler`, `QuestsHandler`, `StreakFreezeEventsHandler`.
  - **Composite-keyed** (`onConflict: 'user_id,muscle'`): `MuscleRanksHandler`.
  - **UNIQUE pair** (`onConflict: 'user_id,logged_on'`): `WeightLogsHandler`.
  - `SetsHandler` does an async local lookup to translate `workout_id` (local int PK) → parent's `cloud_id` UUID with a clear error message when the workout hasn't been pushed yet (engine catches → backoff retry).
  - Conversion utilities in [lib/data/sync/cloud_payload.dart](lib/data/sync/cloud_payload.dart): unix-seconds → ISO-8601 / DATE, JSON-encoded TEXT array → `List<String>` / `List<int>`, 0/1 INT → BOOLEAN. Honours post-mortem 8.2 — every handler upserts the *full* local row, never a partial column set.
- [x] **S3.3 — Wire pushes into existing services** ([lib/data/sync/outbox_enqueuer.dart](lib/data/sync/outbox_enqueuer.dart) + 10 service edits). Generic enqueue helper handles `cloud_id` ensure + JSON snapshot + outbox insert. Convenience wrappers: `upsertPlayer()`, `upsertSingletonByUserId(table)`, `upsertAutoinc(table:, id:, extraPayload:)`, `upsertMuscleRank(muscle)`. All 13 cloud-mirrored services now enqueue on every write:
  - Singletons: `PlayerService.{ensurePlayer, setDisplayName, upsert, completeOnboarding}`, `GoalsService.upsert`, `ExperienceService.upsert`, `ScheduleService.upsert`, `NotificationPrefsService.upsert`, `PlayerClassService.{assign, appendEvolutionEntry}`, `StreakService.{ensure, upsert}`.
  - Append-only: `WorkoutService.{start, finish, addXp, delete}` (delete enqueues a soft-delete carrying the cloud_id forward), `SetsService.insertSet` (pre-resolves `workout_cloud_id` via local DB so the push handler doesn't need an extra round-trip), `WeightLogService.upsertForDay`, `QuestService.{insert, updateProgress, complete}`, `StreakService.logFreezeUsed`, `MuscleRankService.upsert`.
  - **Race-safety:** workouts enqueue at `start()` time, so their `cloud_id` exists locally before any set is logged against them.
- [x] **Outbox flush triggers** — app foreground (immediate), every 30s while foregrounded (timer in [SyncLifecycle](lib/data/sync/sync_lifecycle.dart)), engine no-op when signed out. Network-reconnect trigger is implicit (the next periodic tick or foreground will retry).
- [ ] **Schema-version tagged on every push** — cloud schema declares `schema_version INT NOT NULL DEFAULT 1` for every table, so writes are tagged via Postgres default. Explicit client-side tagging deferred until v2 of the cloud schema lands.
- [ ] **Conflict-resolution path**: server returns 409 with current row → client merges (last-write-wins via `updated_at`) → re-pushes. Deferred to S10 — current handlers always push the full local row, so conflicts manifest as "your version overwrites theirs" on the singleton tables and as no-op upserts on the append-only ones.

## S3b — Initial-sync UX ✓ done (2026-04-30)

- [x] **Welcome-back screen** post-sign-in with progress bar: "Restoring your history… 47%". [lib/screens/auth/welcome_back_screen.dart](lib/screens/auth/welcome_back_screen.dart). Per-table label, step counter, retry on error, skip-to-home for impatient users.
- [x] **Pull tables in priority order** per §1.7: profile + onboarding tables first, then muscle ranks + streak + player class, then workouts → sets → quests → freeze events → weight logs (the bulk). Order encoded in [`kPullPriorityOrder`](lib/data/sync/pull_handler.dart).
- [x] **Paginated fetch** (200 rows per request) — [lib/data/sync/cloud_pull_handlers.dart](lib/data/sync/cloud_pull_handlers.dart) `_CloudPullHandler.pullPage` uses `.range(offset, offset + pageSize - 1)` against PostgREST.
- [x] **Resumable**: [`InitialSync.run`](lib/data/sync/initial_sync.dart) reads `sync_state.initial_sync_table` + `initial_sync_offset` to find the resume point and persists progress after every page. A kill mid-sync resumes cleanly on next launch.
- [x] **First-sync vs ongoing-sync branching**: [`InitialSync.needed()`](lib/data/sync/initial_sync.dart) returns `true` iff authenticated AND `last_full_sync_at IS NULL`. [Sign-in screen](lib/screens/auth/sign_in_screen.dart) routes to `/welcome-back` only on first sign-in per device; subsequent sign-ins skip straight to `/home`.
- [x] **Idempotent re-runs**: each handler looks up by `cloud_id` then UPDATE-or-INSERT (append-only) or REPLACE-by-natural-key (singletons / composite-keyed). Replaying a page is a no-op.
- [x] **Cross-table FK resolution**: [`SetsPullHandler`](lib/data/sync/cloud_pull_handlers.dart) translates cloud `workout_id` UUID → local int PK by looking up the workouts table's `cloud_id`. Workouts are pulled before sets (priority order), so the lookup is reliable; orphaned sets are skipped and re-tried on the next pass.
- [x] **Soft-deleted rows are skipped**: handlers filter `deleted_at IS NULL` server-side, so soft-deleted cloud rows don't pollute the local DB.

## S3c — Incremental pull ✓ done (2026-04-30)

Not in the original plan — added when end-to-end smoke testing on two devices revealed that push-only sync gave us "device A → cloud" but no "cloud → device A". `InitialSync` runs once per device; without an incremental counterpart, deltas pushed by device B never appeared on device A. S3c closes the gap with periodic delta pulls.

- [x] **`PullHandler.pullSince(since)`** — fetches rows where `updated_at > since` (no `deleted_at` filter) and applies each: upsert if alive, delete-by-cloud-id if soft-deleted. Limit 500 rows per pass per table; in steady state most ticks fetch zero.
- [x] **`IncrementalPull` orchestrator** ([lib/data/sync/incremental_pull.dart](lib/data/sync/incremental_pull.dart)) — snapshots `cutoff = now()` before fetching (so rows landing mid-pass aren't lost on the next cursor advance), walks `kPullPriorityOrder`, and on full success persists `cutoff` as the new `last_full_sync_at`. Failure → cursor untouched, next pass retries.
- [x] **`SyncEngine.drainOnce` wiring** — push then pull, both gated by the engine's mutex. Lifecycle hooks (foreground + 30s) drive both halves on the same tick.
- [x] **Cursor reuse**: `sync_state.last_full_sync_at` repurposed from "last full sync timestamp" to "high-water mark of cloud `updated_at` we've hydrated locally." Stays NULL until `InitialSync` completes; bumped forward on every successful incremental pass. `InitialSync.needed()` semantic ("is this null?") is unchanged.

## S4 — Contact-match flow ✓ done (2026-04-30)

- [x] Contacts permission screen with privacy disclosure — [lib/screens/auth/contacts_permission_screen.dart](lib/screens/auth/contacts_permission_screen.dart). 3-row explainer (hashed-on-device, names+emails stay private, hashes deleted after match) + Allow / Skip CTAs. Triggers the OS prompt via `FlutterContacts.requestPermission(readonly: true)`. Inserted between `/loader-pre-home` and `/home` so fresh sign-ups land on it once at end of onboarding. Settings → "Find friends" button deferred to S7.
- [x] On grant: read address book → strip non-digit chars → require explicit `+` country code (skip ambiguous numbers; count skipped) → SHA-256-hash with server salt → batch up to 1000 hashes per RPC call to `find_users_by_phone_hashes` → de-dup matches by user_id. [lib/data/services/contact_match_service.dart](lib/data/services/contact_match_service.dart).
- [x] "Friends found" screen — matched users with avatar (initial badge), display name, `@username`, level, current streak, `ADD` button. [lib/screens/auth/friends_found_screen.dart](lib/screens/auth/friends_found_screen.dart). Per-row state machine: idle → sending (spinner) → sent (green ✓) / error (red retry). [lib/data/services/friend_service.dart](lib/data/services/friend_service.dart) handles the INSERT; idempotent on the unique-pair index.
- [x] Empty-state ("0 found") routes prominently to the invite-link share sheet via `Share.share` (share_plus). Real deep-link generation deferred to S5; current placeholder URL is `https://levelup-irl.app/invite/<emailLocalPart>`.

## S5 — Friend graph (~3-4 days)

- [ ] Send friend request — INSERT into `friendships` with `status='pending'`.
- [ ] Accept / decline incoming requests — UPDATE on receiver's side.
- [ ] Block user — sets status='blocked' on either side; both sides become invisible to each other on leaderboards.
- [ ] Remove friend — DELETE on `friendships` row.
- [ ] Friends tab inside Leaderboard screen — accepted friends + pending requests + blocked users (collapsed).
- [ ] Username search — type `@kael_irl`, Supabase query, render result with `Add Friend`.
- [ ] Invite link generation — `levelup-irl.app/invite/<short_code>` deep link, tappable from any messaging app, opens app pre-filled with friend request.

## S6 — Leaderboard screen (~4 days)

- [ ] Three tabs: Weekly XP (default), Current Streak, All-time XP.
- [ ] Single Postgres query per tab, filtered by friend list, sorted descending. Reads `public_profiles` only — no need to touch the per-user gameplay tables (RLS would block it anyway).
- [ ] User's own row highlighted; sticky-to-top when scrolled out of view.
- [ ] Realtime subscription via Supabase Realtime — listens for `public_profiles` UPDATEs on friend rows, re-sorts the list, fires "Maya passed you · #2 → #3" toast.
- [ ] Local cache (last-known leaderboard snapshot in sqflite) so the tab shows yesterday's standings while offline.
- [ ] New bottom-tab item "Leaderboard" added to `InAppShell` — visible only when socials is opted in.

## S7 — Settings + opt-out + delete (~2-3 days, was 2)

- [ ] **"Disconnect socials"** toggle — calls `disconnect_socials()` RPC. Purges `public_profiles` + `friendships` server-side. **Keeps `cloud_*` data tables** so the user can re-enable socials later without losing their history.
- [ ] **"Delete account"** button — calls `delete_my_account()` RPC. Purges everything cloud-side including `cloud_*` tables, friendships, and the auth row. Cannot be undone. Strong confirmation dialog.
- [ ] **"Wipe local data"** button — clears local sqflite. Server data untouched; signing back in re-hydrates from the cloud.
- [ ] **"Update phone number"** — re-hashes on update.
- [ ] **"Update username"** — rate-limited to once per 30 days.
- [ ] **"Update password"** — Supabase Auth method.
- [ ] **"Pause sync"** toggle — keeps the user signed in but stops outbox flushing. For users on metered connections.
- [ ] Privacy granularity (deferred to v1.x.1): per-metric "share with friends" toggles. v1.x.0 is all-or-nothing on socials visibility.

## S8 — Anti-cheat + RLS hardening (~2-3 days, was 1-2)

- [ ] Per-row triggers per §2.3 (`enforce_set_caps`, `enforce_workout_xp_cap`, `enforce_weekly_xp_delta`, `enforce_streak_increment`, `enforce_total_xp_monotonic`).
- [ ] Rate-limits on `find_users_by_phone_hashes` (5/hour/user) and friend-request INSERT (50/day/user).
- [ ] **Bulk-push throttle**: cap `cloud_sets` INSERT to 200 rows per RPC call (prevents flood attacks).
- [ ] RLS policy review — manually attempt to read another user's data without friendship; should fail.
- [ ] Adversarial test: edit local sqflite to inflate a workout's xp_earned → push → server should clamp to 1500.
- [ ] Adversarial test: try to insert a `cloud_sets` row with someone else's user_id → RLS should reject.

## S9 — Privacy policy + App Store labels (~2-3 days direct, +1-2 weeks calendar buffer)

- [ ] Update privacy policy to disclose: account email, phone number storage, **full workout history storage**, contact-hash upload, data retention, deletion mechanism.
- [ ] App Store nutrition labels: Contacts (Linked to user), Email (Linked to user), Phone (Linked to user), **Health & Fitness data** (workouts, weights, body composition — Linked to user, App Functionality, not used for tracking).
- [ ] In-app disclosures: just-in-time prompts before each permission, with plain-language explanation.
- [ ] **Cloud storage disclosure** in the socials onboarding flow: "Your workouts and weights are backed up to our servers so they survive device changes. You can delete them any time."
- [ ] Submit to App Store review. Budget ~1-2 weeks of back-and-forth on first submission. Health-data storage gets stricter scrutiny than just contacts/email — plan for it.

## S10 — Edge cases + testing (~4-5 days, was 2-3)

- [ ] **Workout logged offline** → sync_outbox queues every set + the workout row → on reconnect, drains in FIFO order. Verify in airplane-mode test.
- [ ] **Friend request sent offline** → queues → fires on reconnect.
- [ ] **Conflict on a mutable row**: edit `goals.priority_muscles` on device A and device B, both online — last write wins, no data corruption.
- [ ] **Two-device race on `current_streak`**: rare but possible — server's `enforce_streak_increment` trigger ensures only one increment per day regardless of how many devices push.
- [ ] **Initial-sync killed mid-fetch** → on next launch resumes from last successful page.
- [ ] **Initial-sync with 10K sets** — perf test, verify <60s on a typical connection, progress bar accurate.
- [ ] **Outbox grows unbounded while offline for weeks** — verify drain handles 1000+ pending operations without OOM.
- [ ] **Blocked user attempts to send a friend request** → server rejects.
- [ ] **Reinstall on same device** → sign in → cloud sync hydrates everything → contacts permission needs re-granting.
- [ ] **User deletes account** → all server data purged → friends' leaderboards no longer show them.
- [ ] **User logs out** → local sqflite intact (so they can keep training offline), session token destroyed, can sign back in any time.
- [ ] **User wipes local data + signs back in** → cloud rehydrates everything cleanly.
- [ ] **Adversarial: user logs same workout twice via re-push** → idempotent because of `cloud_id` (UPSERT rather than INSERT).

## S11 — Onboarding answer sync — **absorbed into S3**

In Scope A this was a separate ~half-day phase. Under Scope B, `cloud_goals` / `cloud_experience` / `cloud_schedule` / `cloud_notification_prefs` / `cloud_player` are full-fledged synced tables, so the second-device onboarding-skip behaviour falls out of S3 + S3b's initial-sync hydration. **No separate phase needed.**

## S12 — Post-launch polish (deferred to v1.x.1+)

- [—] QR code friend-add (in-person gym buddies)
- [—] Friend-of-friend suggestions
- [—] Per-metric "share with friends" privacy toggles
- [—] Phone OTP verification (when contact-match abuse becomes real)
- [—] Branded SES email instead of Supabase default SMTP
- [—] Push notifications for new friend requests + leaderboard milestones (via local notifications + Supabase webhook)
- [—] Multi-device live sync (real-time replication while both devices are online — Scope B currently uses opportunistic push, not real-time mirroring)

---

# 4. The two flows, end-to-end

## 4.1 First device — first-time install

1. Install the app, open it.
2. Splash → 2 hype slides → tap CTA.
3. **Sign Up** screen (S1) — email + password. Backend sends verification email.
4. **Email verification gate** (S1) — tap link or skip-for-now.
5. **Pick Username** (S2) — `@kael_irl`, locked for 30 days.
6. **Phone Number** (S2) — E.164, stored + hashed.
7. **17-screen local onboarding** — display name, age, height, body type, priority muscles, equipment, limitations, training styles, weight, weight direction, target weight, body fat, training days, session minutes, notification prefs, challenge system intro, paywall. Each screen writes its answer to local sqflite (as today) **and** pushes to the corresponding `cloud_*` table via the sync outbox.
8. Calibrating loader.
9. **Contacts permission** (S4) — "find friends already on the app" → on grant, hash + match.
10. **Friends Found** screen (S4) — matched users with `Add Friend` buttons. Empty-state shows invite link prominently (S5).
11. **Home** — bottom-tab Leaderboard now visible.
12. Daily use: every workout finish writes to local sqflite synchronously; sync outbox enqueues pushes for the new `cloud_workouts` row + every new `cloud_sets` row + the updated `public_profiles` summary. Outbox drains opportunistically. **The user never waits for the network**; they see the Workout Complete screen immediately.

## 4.2 Second device — same user reinstalls

1. Install the app, open it.
2. Splash → hype slides → "Already have an account? Sign in" path.
3. **Sign In** (S1) — email + password. Supabase returns the same `user_id`.
4. **Welcome-back + initial sync** (S3b) — "Restoring your training history… X%". Pulls in priority order: profile + onboarding tables → muscle ranks + streak + player class → workouts + sets in pages of 200.
5. Once profile + onboarding tables are in (~2-5 seconds), shows: **"Welcome back, Kael · Level 12 · 47-day streak · ranked #2 this week"**. Workouts continue hydrating in the background.
6. **17-screen onboarding is skipped entirely** — every answer was already in `cloud_goals` / `cloud_experience` / `cloud_schedule` / etc. and seeded local sqflite during initial sync.
7. **Re-grant contacts permission** (S4) — OS forgets the previous grant per-install. Re-runs hash + match using the on-file phone (no re-entry needed). "3 new friends since you were here last."
8. Lands on Home with leaderboard pre-populated and **all gameplay state restored** — Profile → Workouts shows the full history, weight-log trend renders, per-muscle ranks intact, current quest progress preserved, streak-freeze events restored.
9. **Nothing is missing.** Identical state to the previous device, modulo the cosmetic "this device's first launch" splash and the contacts re-grant.

---

# 5. Effort estimate

| Phase | Days |
|---|---|
| S0 — Backend setup (13 cloud tables + RLS + RPCs + triggers + cron) | 4-5 |
| S1 — Auth screens | 2 |
| S2 — Username + phone | 2 |
| S3 — Cloud sync engine (outbox + per-table push/pull + wire-up to ~10 services) | 6-8 |
| S3b — Initial-sync UX (welcome-back + paginated hydration + resumable) | 2 |
| S4 — Contact-match | 2-3 |
| S5 — Friend graph + invite link | 3-4 |
| S6 — Leaderboard | 4 |
| S7 — Settings + opt-out + delete + pause-sync | 2-3 |
| S8 — Anti-cheat + RLS hardening (per-row triggers + adversarial tests) | 2-3 |
| S9 — Privacy + App Store labels (broader scope: health-data disclosure) | 2-3 dev + 1-2 wk calendar |
| S10 — Edge cases + testing (sync conflict resolution + initial-sync stress + bulk-push throttle) | 4-5 |
| **Total dev** | **~36-44 days** |
| **Plus App Store review buffer** | **+1-2 weeks calendar** |

**Realistic ship window from start:** **~8-10 weeks to v1.x.0**. Scope B is a real ~3-week scope-up over Scope A's 5-6 weeks, exactly as flagged in the trade-off conversation.

---

# 6. Decisions locked

- **Auth:** email + password via Supabase Auth. **Locked.** Sign-in-with-Apple deferred to v1.x.1 if account-recovery complaints surface.
- **Phone collection:** unverified (no OTP) in v1.x.0. **Locked.** Add OTP verification only if contact-match abuse becomes a real problem.
- **Friend discovery:** contact-match + invite link + username search ship together. QR + friend-of-friend deferred. **Locked.**
- **Sync scope:** **Scope B — full cloud sync of every domain table.** Workout history, weight logs, quest progress, muscle ranks, onboarding answers, player class, streak data — everything mirrors to Supabase. Device switch restores 100% of state. **Locked 2026-04-29** (was Scope A through 2026-04-29 morning; expanded to Scope B same day).
- **Backend:** Supabase. **Locked.**
- **Onboarding flow:** signup happens at install (Path A), not deferred. Every user gets a cloud account on day one. **Locked.**
- **Identity strategy:** add `cloud_id UUID` column to each synced local table; keep local int PKs. No mass migration. **Locked.**
- **Conflict resolution:** append-only tables are immutable post-write; mutable singletons use last-write-wins via `updated_at`. **Locked.**

# 7. Decisions still open

- **Email provider:** Supabase default SMTP for v1.x.0; branded SES (or Resend) when volume justifies it.
- **Server salt rotation:** start with one salt forever; revisit if security review demands a rotation strategy.
- **Push notifications:** out of scope for v1.x.0. Defer to v1.x.1+ alongside plan.md §2.5 local notifications work.
- **Localization of socials copy:** deferred to plan.md §3.10.
- **Web/desktop access:** Supabase supports it natively. Out of scope until plan.md §4.4.
- **Supabase tier upgrade timing:** free tier is 500MB DB + 50K MAU. Average user with 1 year of training history ≈ 200KB. Free tier covers ~2.5K active users. Pro tier ($25/mo + linear storage) handles 50K+ users at ~$50-100/mo total. Plan to upgrade when monthly DB growth crosses 350MB or active users exceed 2K.
- **Multi-device real-time mirroring:** v1.x.0 ships opportunistic-push sync (eventual consistency, ~seconds to minutes for cross-device propagation). Real-time mirroring (instant device-to-device replication) is a v1.x.1+ enhancement if users complain.

---

# 8. Post-mortems — bugs caught during S0–S2 smoke testing (2026-04-29)

Two bugs surfaced during the first end-to-end test pass; both resolved same day. Recording them here so the same shapes aren't repeated in S3+.

## 8.1 PostgREST schema cache miss on `phone` column

**Symptom:** Tapping `Save Phone` returned `"Could not find the 'phone' column of 'public_profiles' in the schema cache"`.

**Root cause:** [002_schema.sql](supabase/migrations/002_schema.sql) declared `phone_encrypted BYTEA` with a comment promising a "transparent encrypt/decrypt via pgcrypto" trigger that was never written. Meanwhile the Dart side ([public_profile_service.dart](lib/data/services/public_profile_service.dart)) pushed the column as plain `phone`. Schema and code disagreed.

**Fix:** [008_phone_column_fix.sql](supabase/migrations/008_phone_column_fix.sql) drops the bytea column and adds `phone TEXT`. 002 also updated so future fresh-installs declare the right shape directly.

**Lesson for S3+:** when adding new cloud columns, grep the Dart side for the column name before claiming a phase done. The schema and code must stay in lockstep — comments aren't contracts.

## 8.2 PostgREST `.upsert()` clobbering on partial payload

**Symptom:** After 8.1 was fixed, `Save Phone` then failed with `"null value in column 'username' violates not-null constraint"` even though a row with the username already existed (created during `/username` step).

**Root cause:** `.upsert(payload)` with the supabase-flutter SDK does an `INSERT ... ON CONFLICT (user_id) DO UPDATE` where the UPDATE half includes every column in the payload. When `/phone` calls upsert with only `{user_id, phone, phone_hash}`, the SDK's behaviour effectively cleared `username` and `display_name` from the existing row's UPDATE — tripping the `NOT NULL` constraint.

**Fix:** Replaced blanket `.upsert()` with explicit `SELECT user_id` first, then either `UPDATE` (preserves untouched columns) or `INSERT` (requires all NOT NULL fields). One extra round-trip but bulletproof against PostgREST UPSERT semantics quirks. See `PublicProfileService.upsertProfile` in [lib/data/services/public_profile_service.dart](lib/data/services/public_profile_service.dart).

**Lesson for S3+:** the sync engine should never use `.upsert()` for partial column updates. Pattern is "branch on existence, do the right thing." This cost ~2 lines per push handler but eliminates a whole class of bug.

---

# 9. Cross-references back to plan.md

This work is the v1.1 release that plan.md §4.1 references. Once shipped, this becomes part of the main implementation history. Until then, **this file is the source of truth** for the social tier — main `plan.md` should reference this document rather than duplicate the breakdown.

The earlier "Scope B as a separate v1.2 milestone" entry in plan.md §4.1c is now obsolete — Scope B is v1.x.0.

---

**End of socials plan.**
