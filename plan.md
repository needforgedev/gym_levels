# LEVEL UP IRL — Implementation Plan

**Companion to:** [PRD_GamifiedFitnessApp.md](PRD_GamifiedFitnessApp.md) (v1.2)
**Design system:** [DesignSystem_LevelUpIRL.md](DesignSystem_LevelUpIRL.md) (v1.0)
**Stack:** Flutter / Dart, **offline-first**, SQLite via **raw `sqflite`** (no ORM, no codegen) as source of truth.
**Last updated:** 2026-04-20

This plan maps the PRD scope to phased, checkbox-trackable work. Phases follow the roadmap in PRD §16. Each phase has explicit **exit criteria** — do not start the next phase until the current phase's exit criteria are met.

## Status legend

- `[x]` — done and merged
- `[~]` — in progress
- `[ ]` — not started
- `[!]` — blocked (annotate with reason)
- `[—]` — out of scope for this phase (deferred)

## Phase-at-a-glance

| Phase | Name | PRD roadmap | Window | Status |
|---|---|---|---|---|
| **0** | Foundation — design system + UI shell | (pre-v0.1) | done | `[x]` |
| **1** | v0.1 Internal Alpha — raw-sqflite data model + full onboarding | Wk 1–6 | `[~]` §1.1 data layer + §1.3 seed + §1.5 all 21 screens + §1.5i per-screen persistence + §1.6 PlayerState-over-service **done** ✓ — remaining: backup/restore (1.7), integration tests (1.8) |
| **2** | v0.5 Closed Beta — logger, XP, ranks, daily quests, paywall, push | Wk 7–12 | `[ ]` not started |
| **3** | v1.0 Public Launch — weekly/boss quests, celebrations, polish, store | Wk 13–16 | `[ ]` not started |
| **4** | v1.1+ Post-MVP — cloud sync, health integrations, social, AI, web | +6 wk → +6 mo | `[—]` deferred |

---

# Phase 0 — Foundation: design system + clickable UI shell

**Goal:** a tappable Flutter prototype that matches the design system pixel-for-pixel, with every screen routable. Zero real persistence; in-memory Provider state only. This is what the prior "Claude Design" HTML prototype produced, now ported to Flutter.

## 0.1 Project scaffold
- [x] `flutter create gym_levels` baseline with iOS + Android folders
- [x] pubspec dependencies: `google_fonts`, `go_router`, `provider`
- [x] `flutter analyze` clean
- [x] Smoke test in `test/widget_test.dart` (app boots to MaterialApp)

## 0.2 Design tokens — [lib/theme/](lib/theme/)
- [x] Palette (20+ named colors, incl. rank gradients)
- [x] Spacing grid (8-pt)
- [x] Radii (`sm`/`md`/`lg`/`xl`/`pill`)
- [x] Typography (Rajdhani / Inter / JetBrains Mono at 11 styles)
- [x] Glow helper (`GlowColor` + `AppGlow.shadow()`)
- [x] Dark `ThemeData`

## 0.3 Reusable widgets — [lib/widgets/](lib/widgets/)
- [x] `NeonCard` (pulsing glow, onTap, optional clip)
- [x] `PrimaryButton`, `SecondaryButton`, `GhostButton`
- [x] `ProgressHeader` (onboarding section header with bar)
- [x] `Bar` (gradient progress bar, glow optional)
- [x] `AppChip` + `AppChipGroup` (single/multi)
- [x] `SegmentedToggle`
- [x] `LevelPill`, `XPPill`, `StreakPill`
- [x] `RankBadge` (hex shield with gradient, animated optional)
- [x] `SystemHeader` (animated `● ● ● KICKER`)
- [x] `NumericStepper` (narrow-column-safe with FittedBox)
- [x] `XPRing` (CustomPaint arc)
- [x] `XPToast` (rising + fading)
- [x] `MuscleFigure` (body silhouette with highlight)
- [x] `BigFlame` (gradient path)
- [x] `PlaceholderBlock` (striped placeholder for key art)
- [x] `AppTabBar` (amber active state)
- [x] `QuestRow` (daily/weekly/boss variants)

## 0.4 Shell scaffolds
- [x] `ScreenBase`
- [x] `OnboardingScaffold` (progress header + back/continue)
- [x] `InAppShell` (header + tab bar)

## 0.5 Screens (UI-only, in-memory state)
- [x] Welcome
- [x] Calibrating (interstitial, auto-advance)
- [x] Objectives (multi-select chips)
- [x] Experience (radio list)
- [x] Attributes (numeric steppers + unit toggle)
- [x] Final Calibration (reuses Calibrating)
- [x] Home (greeting, pills, XP ring, protocol, quests, muscle rank row)
- [x] Workout Logger (pending/active/completed sets, rest timer, XP toast, Provider-backed XP)
- [x] Quests (Daily/Weekly/Boss tabs)
- [x] Boss Detail
- [x] Streak (flame hero, 30-day calendar, freeze card)
- [x] Profile (Iron Warrior class card, stat tiles, 10-muscle rank list)
- [x] Level Up celebration (rotating rays)
- [x] Streak Milestone celebration

## 0.6 Routing + state plumbing
- [x] `go_router` with 14 routes ([lib/router.dart](lib/router.dart))
- [x] `PlayerState` ChangeNotifier via `Provider` ([lib/state/player_state.dart](lib/state/player_state.dart))
- [x] `main.dart` wires theme + router + provider

## Phase 0 exit criteria
- [x] User can tap through every screen from Welcome → Home → (tabs) → celebrations
- [x] `flutter analyze` reports no issues
- [x] Smoke test passes
- [x] Renders on iPhone SE (small) and Pro Max (large) without overflow

---

# Phase 1 — v0.1 Internal Alpha (PRD roadmap: Wk 1–6)

**Goal:** make the app **truly offline-first**. Replace the in-memory prototype state with a minimal SQLite data layer, complete the full onboarding flow (all 21 screens), and seed the exercise catalog. Exit this phase with a single-user, persistent, fully navigable app that survives app kills and airplane mode.

**PRD references:** §6.1 (scope), §11.0–11.8 (architecture + DDL + layout), §8 (onboarding spec).

**Design posture (v1.2 revision):** raw `sqflite` + **static service classes** + plain-Dart models. **Zero codegen. Zero encryption in v1.0** (SQLCipher deferred — see §1.2). Three dependencies only: `sqflite`, `path`, `path_provider`. Plus `sqflite_common_ffi` as a dev dep for in-memory test DBs. The DAO pattern stays; the implementation is just simpler.

## 1.1 Persistence layer (raw sqflite)

- [x] Add dependencies to `pubspec.yaml`: `sqflite`, `path`, `path_provider`
- [x] Dev dependencies: `sqflite_common_ffi` (in-memory DB for unit tests)
- [x] [lib/data/schema.dart](lib/data/schema.dart) — column name constants + 20 `CREATE TABLE` statements + indexes as const strings. All references to columns go through these constants (typos caught at analyze time).
- [x] [lib/data/app_db.dart](lib/data/app_db.dart) — `class AppDb` with static singleton, `init()`, `instance`, `close()`, `reset()`, `overrideForTesting()`. Uses `getApplicationDocumentsDirectory()` for DB path. `onConfigure` enables `PRAGMA foreign_keys = ON`. `onCreate` executes the statements from `schema.dart` + inserts v1 into `schema_version`. `onUpgrade` logs every version bump.
- [x] Hot-restart safe: `close()` nulls the singleton; next `instance` call re-opens.

### 1.1a Plain-Dart models — `lib/data/models/` (one file per table)

Each model is immutable: final fields + const constructor + `factory fromRow(Map<String, Object?>)` + `Map<String, Object?> toRow()` + optional `copyWith`. JSON-array columns are encoded/decoded inside `fromRow` / `toRow` via shared helpers in `_json_list.dart`. No `json_serializable`, no `freezed`, no codegen.

- [x] `player.dart`
- [x] `goal.dart`
- [x] `experience_row.dart` (named `ExperienceRow` to keep the class name noun-free)
- [x] `schedule_row.dart`
- [x] `notification_prefs.dart`
- [x] `player_class_row.dart`
- [x] `exercise.dart`
- [x] `workout.dart`
- [x] `workout_set.dart` (avoids `Set` conflict with `dart:core`)
- [x] `workout_override.dart`
- [x] `exercise_swap.dart`
- [x] `muscle_rank.dart`
- [x] `quest.dart`
- [x] `streak.dart`
- [x] `streak_freeze_event.dart`
- [x] `weight_log.dart`
- [x] `subscription.dart`
- [x] `analytics_event.dart`
- [x] `crash_report.dart`
- [x] `schema_version_row.dart`

### 1.1b Static services — `lib/data/services/` (one file per table)

Each service exposes only `static` methods. No instances, no DI, no Provider wiring needed. Screens call `PlayerService.setDisplayName('Kael')` directly. All methods go through `AppDb.instance`.

Contract: services are the **only** place that touches `sqflite`. Screens never write raw SQL.

- [x] `player_service.dart` — getPlayer, ensurePlayer, setDisplayName, upsert, completeOnboarding, deleteAll
- [x] `goals_service.dart` — get, upsert
- [x] `experience_service.dart` — get, upsert
- [x] `schedule_service.dart` — get, upsert
- [x] `notification_prefs_service.dart` — get, upsert
- [x] `player_class_service.dart` — get, assign (with evolution history audit)
- [x] `exercise_service.dart` — getAll, byId, byPrimaryMuscle, count, insertBatch (idempotent seed via IGNORE)
- [x] `workout_service.dart` — start, finish, byId, recent, totalFinished
- [x] `sets_service.dart` — insertSet, forWorkout, bestFor (PR detection seam), volumeFor
- [x] `muscle_rank_service.dart` — getAll, forMuscle, upsert
- [x] `quest_service.dart` — insert, active, all, updateProgress, complete
- [x] `streak_service.dart` — get, ensure, upsert, logFreezeUsed
- [x] `weight_log_service.dart` — all, latest, upsertForDay (UNIQUE per day via REPLACE)
- [x] `subscription_service.dart` — get, upsert, isProCached
- [x] `analytics_service.dart` — log, pending, markUploaded, purgeStale (30-day TTL)
- [x] `crash_report_service.dart` — log, pending, markUploaded

### 1.1c Reactivity — minimum viable

No reactive DB streams (that's drift's job, not ours). Two approaches where needed:

- [ ] For values rendered app-wide (`player`, `streak`, `subscription`): after each write, call `notifyListeners()` on a matching `ChangeNotifier` in `lib/state/` that holds the latest snapshot. Existing `PlayerState` becomes a thin cache over `PlayerService`.  _(deferred to §1.6 — screen rewiring)_
- [ ] For per-screen reads: use `FutureBuilder` + a `setState()` refresh after writes. Simple, boring, obvious.  _(applied per-screen in §1.6)_

Revisit if ergonomics get annoying in Phase 2.

### 1.1d Acceptance tests (Phase 1.1 — landed with [test/db/db_smoke_test.dart](test/db/db_smoke_test.dart))

- [x] Player round-trip (create → rename → `completeOnboarding`)
- [x] JSON list converters symmetric on `goals.priority_muscles`
- [x] Exercise catalog seed is idempotent (re-running doesn't duplicate)
- [x] `weight_logs` UNIQUE(user_id, logged_on) enforced via `upsertForDay`
- [x] Analytics outbox: insert → `pending()` returns N → `markUploaded()` drops them
- [x] `Subscription.isProCached` respects tier + status + `renews_at` clock
- [x] `StreakService.ensure()` creates singleton with sensible defaults
- [x] `DELETE FROM player` cascades every dependent row (the "Delete my data" guarantee)

## 1.2 Encryption — DEFERRED to v1.0.1+

**Decision (2026-04-20):** SQLCipher is out of v1.0 scope. iOS and Android app sandboxing already block casual access to `gym_levels.db`. The PRD §17 risk "SQLCipher key lost on factory reset" disappears when there's no key to lose. Re-evaluate when:
- We have real user data worth encrypting, or
- An App Store review flags data-at-rest, or
- A user credibly asks for it.

- [—] Swap `sqflite` for `sqflite_sqlcipher` — deferred
- [—] 32-byte key in `flutter_secure_storage` — deferred
- [—] Recovery-code mnemonic flow — deferred (only needed when encryption is on)
- [—] Raw-SQLite-viewer unreadability acceptance test — deferred
- [x] **Do not block v1.0 on encryption.** Ship when the feature loop is solid; add encryption as a patch release.

## 1.3 Seed data — exercise catalog

**Format decision (2026-04-20):** Dart file, not SQL asset. Matches the zero-codegen posture — we already have the `Exercise` model with a `toRow()` that encodes JSON arrays correctly, so seeding is a one-liner `ExerciseService.insertBatch(exerciseCatalog)`. No asset parsing, no `pubspec.yaml` registration, no double-encoding JSON in SQL.

- [x] Author [lib/data/seed/exercise_catalog.dart](lib/data/seed/exercise_catalog.dart) — `const exerciseCatalog = <Exercise>[ … ]`, 80 entries per PRD Appendix A breakdown:
  - Chest (12), Back (12), Shoulders (8), Biceps (6), Triceps (6), Core (8), Quads (10), Hamstrings (6), Glutes (6), Calves (6) — counts verified in [test/db/seed_test.dart](test/db/seed_test.dart)
- [x] Each entry sets: `name`, `primaryMuscle`, `secondaryMuscles` (used by plan generator), `equipment` (filtered against `experience.equipment`), `baseXp` (5 for compound lifts, 3 for accessories per PRD §12), `cueText` for key lifts
- [x] `demoVideoUrl` stays null for the offline build (PRD §11.6: no runtime asset fetches)
- [x] `AppDb.init()` auto-seeds on first launch — if `ExerciseService.count() == 0`, invoke `insertBatch(exerciseCatalog)`. Idempotent via `ConflictAlgorithm.ignore` on the UNIQUE `name` constraint.
- [x] Tests opt out of seeding via `AppDb.init(seed: false)` to keep fixture DBs small; seed-specific tests live in `test/db/seed_test.dart`.

## 1.4 Schema versioning & migrations
- [x] `schema_version` audit table created + seeded on first run ([lib/data/app_db.dart](lib/data/app_db.dart) `onCreate`)
- [x] `onUpgrade` hook wired — every version bump logs a row into `schema_version` for audit
- [ ] Pre-migration backup to `gym_levels.db.pre-migration`; auto-rollback on throw (PRD §17) — land on first real schema bump (v2)
- [ ] Unit tests: migration round-trip from every prior schema version in `test/db/` — land with v2 migration

## 1.5 Complete the onboarding flow (21 screens per PRD §8)

**State (2026-04-20):** All 21 screens built + 2 shared widgets (`BigSlider`, `OnboardingRadioTile`). Flow is reachable end-to-end from `/` → `/home`. Screens hold local state only; SQLite persistence lands with §1.6 screen rewire.

Shared additions:
- [x] [lib/widgets/big_slider.dart](lib/widgets/big_slider.dart) — big mono readout + themed Material `Slider` (for age / height / weight / body fat / target weight).
- [x] [lib/widgets/onboarding_radio_tile.dart](lib/widgets/onboarding_radio_tile.dart) — reusable themed radio row used across tenure / reward style / weight direction / session minutes.
- [x] Retired the placeholder `attributes_screen.dart` / `objectives_screen.dart` / `experience_screen.dart`; those features are now split across purpose-built screens matching the PRD numbering.

### 1.5a Intro hype slides (pre-quiz)
- [x] Slide 1 — Muscle Ranks hype — [lib/screens/ranks_hype_screen.dart](lib/screens/ranks_hype_screen.dart) (route `/hype/ranks`)
- [x] Slide 2 — Progression System hype — [lib/screens/progression_hype_screen.dart](lib/screens/progression_hype_screen.dart) (route `/hype/progression`)

### 1.5b Section 1 — Player Registration (teal, 0–10%)
- [x] Screen 3 — Display name text input — [lib/screens/registration_screen.dart](lib/screens/registration_screen.dart)
- [x] Screen 4 — Age slider 16–80 — [lib/screens/age_screen.dart](lib/screens/age_screen.dart)
- [x] Screen 5 — Height slider + CM / FT-IN toggle — [lib/screens/height_screen.dart](lib/screens/height_screen.dart)

### 1.5c Section 2 — Mission Objectives (purple, 15–25%)
- [x] Screen 6 — Body type 2×2 cards — [lib/screens/body_type_screen.dart](lib/screens/body_type_screen.dart)
- [x] Screen 7 — Priority muscle chips (cap 3) — [lib/screens/priority_muscles_screen.dart](lib/screens/priority_muscles_screen.dart)
- [x] Screen 8 — Reward style radio — [lib/screens/reward_style_screen.dart](lib/screens/reward_style_screen.dart)

### 1.5d Section 3 — Combat Experience (yellow, 32–45%)
- [x] Screen 9 — Tenure radio — [lib/screens/tenure_screen.dart](lib/screens/tenure_screen.dart)
- [x] Screen 10 — Equipment multi-chip — [lib/screens/equipment_screen.dart](lib/screens/equipment_screen.dart)
- [x] Screen 11 — Limitations multi-chip (`None` exclusive) — [lib/screens/limitations_screen.dart](lib/screens/limitations_screen.dart)
- [x] Screen 12 — Training styles multi-chip — [lib/screens/training_styles_screen.dart](lib/screens/training_styles_screen.dart)

### 1.5e Section 4 — Physical Attributes (teal, 50–57%)
- [x] Screen 13 — Weight slider + KG / LBS — [lib/screens/weight_screen.dart](lib/screens/weight_screen.dart)
- [x] Screen 14 — Weight direction radio (Gain / Lose / Maintain) — [lib/screens/weight_direction_screen.dart](lib/screens/weight_direction_screen.dart)
- [x] Screen 15 — Target weight with ≥2 kg delta validation — [lib/screens/target_weight_screen.dart](lib/screens/target_weight_screen.dart); router skips it when direction = Maintain
- [x] Screen 16 — Body-fat estimate slider — [lib/screens/body_fat_screen.dart](lib/screens/body_fat_screen.dart). Morphing avatar rendered as themed `PlaceholderBlock` for MVP; commissioned avatars deferred to the Phase 3 art pass.

### 1.5f Section 5 — Daily Operations (green, 65–70%)
- [x] Screen 17 — Training days presets + 7 toggles (≥2 required) — [lib/screens/training_days_screen.dart](lib/screens/training_days_screen.dart)
- [x] Screen 18 — Session minutes radio — [lib/screens/session_minutes_screen.dart](lib/screens/session_minutes_screen.dart)

### 1.5g Section 6 — System Settings (white, 87%)
- [x] Screen 19 — Notification toggles (3) — [lib/screens/notification_prefs_screen.dart](lib/screens/notification_prefs_screen.dart). OS permission prompt lands with Phase 2.5's `NotificationsService`.

### 1.5h Outro + monetization
- [x] Screen 20 — Challenge System hype — [lib/screens/challenge_system_screen.dart](lib/screens/challenge_system_screen.dart)
- [x] Screen 21 — Paywall (3 tiers, Best Value preselected, Skip in header) — [lib/screens/paywall_screen.dart](lib/screens/paywall_screen.dart). IAP wiring deferred to §2.6.

### 1.5i Onboarding persistence
- [x] Each screen's CONTINUE persists its block to SQLite (writes land before nav) — every onboarding screen now calls `*Service.patch(...)` on CONTINUE before navigation. Services return before `context.go`.
- [x] Per-screen resume: each onboarding screen seeds its initial value from the relevant service (`PlayerService.getPlayer`, `GoalsService.get`, `ExperienceService.get`, `ScheduleService.get`, `NotificationPrefsService.get`). Re-entering a screen shows the previously saved choice.
- [x] `onboarding_completed` event fires on first Home render — [home_screen.dart](lib/screens/home_screen.dart) `initState` → `PlayerService.completeOnboarding()` + `AnalyticsService.log('onboarding_completed', {...})` when `player.onboardedAt` is null. Idempotent; only runs once.
- [x] Route-level resume: if `player.onboardedAt != null` on cold launch, go_router's `redirect` sends `/` → `/home` so returning users skip the whole 21-screen flow. Backed by [lib/state/onboarding_flag.dart](lib/state/onboarding_flag.dart) — a `ValueNotifier<bool>` seeded from `PlayerService.getPlayer()` in [main.dart](lib/main.dart) and flipped to `true` by Home's first-render completion trigger.

### 1.5j Router wiring
- [x] Full flow in [lib/router.dart](lib/router.dart): `/` → 2 hype slides → 3 registration screens → `/calibrating/1` → 3 objectives screens → `/calibrating/2` → 4 experience screens → `/calibrating/3` → 4 attributes screens (target-weight conditionally skipped) → `/calibrating/4` → 2 operations screens → `/calibrating/5` → 1 settings screen → `/calibrating/6` → 2 outro screens → `/loader-pre-home` → `/home`.

## 1.6 Local-only profile

- [x] No email / Apple / Google sign-in in v1.0 (PRD §6.1) — the app bootstraps the singleton `player` row without any auth step.
- [x] `player` row is created on first write via `PlayerService.ensurePlayer`; onboarding overwrites. Schema has `CHECK (id = 1)` so there's always at most one player.
- [x] `PlayerState` refactored to a thin cache over `PlayerService`: [lib/state/player_state.dart](lib/state/player_state.dart). Loads from `PlayerService.getPlayer()` at app start (via `..refresh()` in main.dart), exposes `player`, `isOnboarded`, `playerName`, and a `refresh()` method that screens call after every write.
- [x] `copyWith` added to `Goal`, `ExperienceRow`, `ScheduleRow`, `NotificationPrefs` so services can offer patch semantics without replaying whole rows.
- [x] `patch(…)` helper added to `PlayerService`, `GoalsService`, `ExperienceService`, `ScheduleService` — fetch existing row, overlay non-null args, upsert.
- [x] All 21 onboarding screens wired: each reads existing value on mount, each persists on CONTINUE before navigating.
- [ ] Post-onboarding screens (Home / Profile / Streak etc.) still read demo scalars for `level` / `streak` / `xpCurrent` / `xpMax` — those come from Phase 2 services (XP, Streak). Player display name on Home already flows through PlayerState and reflects the onboarded value.

## 1.7 Backup / restore (v1.0 multi-device story)
- [ ] Settings action: Export → copies the SQLite file to a share sheet (Files / Drive / email)
- [ ] Settings action: Import → confirm dialog, schema-version check, atomic replace
- [ ] "Delete my data" — wired to `PlayerService.deleteAll()` (`DELETE FROM player WHERE id=1` cascades every dependent row)

## 1.8 Tests (Phase 1)
- [x] Unit: all 16 services — round-trip + edge cases ([test/db/db_smoke_test.dart](test/db/db_smoke_test.dart), 8 scenarios, landed with §1.1d)
- [ ] Unit: migration round-trips — land alongside v2 schema bump (§1.4)
- [ ] Widget: full onboarding flow from Welcome → Home with airplane mode on
- [ ] Integration: kill the app mid-onboarding, relaunch — user resumes at the correct screen

## Phase 1 exit criteria
- [ ] Fresh install in airplane mode completes full onboarding without error
- [ ] Kill + relaunch at any point preserves all data in SQLite
- [—] `gym_levels.db` is unreadable with a vanilla SQLite viewer — **deferred per §1.2**; not a v1.0 blocker
- [ ] Exercise catalog seed loads on first launch (80 rows verified)
- [ ] All Phase 0 screens read their data from SQLite via services, not from hard-coded constants
- [ ] CI runs `flutter analyze` + `flutter test` — all pass (no codegen step needed)
- [ ] Migration round-trip tests pass for every schema version shipped so far

---

# Phase 2 — v0.5 Closed Beta (PRD roadmap: Wk 7–12)

**Goal:** the gameplay loop. Workout logger writes real sets; XP + ranks recompute; daily quests rotate; streaks respond; local notifications fire; paywall gates premium; analytics events queue locally.

**PRD references:** §9 features, §11.2 where server-ish logic runs, §12 gamification rules, §13 monetization, §14 notifications, §15 analytics.

## 2.1 Gameplay services layer — [lib/game/](lib/game/)

Distinct from the per-table persistence services under `lib/data/services/`. Gameplay services orchestrate: they call the data services, apply game rules (XP math, rank thresholds, quest rotation), and emit side effects (notifications, analytics events).

### 2.1a XP engine (`lib/game/xp_engine.dart`)
- [ ] Formula: `xp_per_set = base_xp × rpe_multiplier × pr_bonus` (PRD §12)
- [ ] `rpe_multiplier` lookup: 0.6 at RPE 5 → 1.0 at RPE 8 → 1.3 at RPE 10 (interpolated)
- [ ] `pr_bonus`: +25 XP when set is a weight-for-reps PR (compare against historical `sets` for that exercise)
- [ ] Level curve: `xp_to_next(level) = round(100 × level^1.45)`, cap 99
- [ ] Unit tests for every boundary (RPE 5/8/10, PR yes/no, level 1/10/99)

### 2.1b Rank engine (`lib/game/rank_engine.dart`)
- [ ] Per-muscle rank from rolling 4-week `(max_volume × max_weight × frequency)` → map via thresholds in §9A.4
- [ ] Tier names: Bronze I/II/III, Silver I/II/III, Gold I/II/III, Platinum I/II/III, Diamond I/II/III, Master, Grandmaster
- [ ] Overall Rank = weighted median across 10 muscles (priority muscles × 1.5)
- [ ] Recompute triggers: on workout save (synchronous, cheap) + nightly via `workmanager` (full rolling recalc)
- [ ] Emit `rank_changed` analytics event on tier change

### 2.1c Quest engine (`lib/game/quest_engine.dart`)
- [ ] Daily quest rotation at 04:00 local (PRD §9.4) via `workmanager`
- [ ] Daily pool: "Complete today's workout", "Hit 3 sets at RPE 8+", "Finish under 45 min", "10,000 steps" (stub steps for now), "Log RPE on every set", etc.
- [ ] Catch-up: if `workmanager` missed a rotation, catch up on next launch
- [ ] Progress updates on set save, workout finish, or step count change
- [ ] Completion emits `+XP` toast + analytics + local notification
- [ ] Player Class biases selection (Mass Builder → more volume quests, etc. — PRD §12)

### 2.1d Streak engine (`lib/game/streak_engine.dart`)
- [ ] Increment once per scheduled day (`schedule.days`) with ≥1 set logged at RPE ≥6
- [ ] Missed scheduled day → auto-consume 1 freeze if `freezes_remaining > 0`
- [ ] Second miss → reset streak
- [ ] Freeze replenishment: free 1/week, Pro 2/week (toggle by `subscriptions.tier`)
- [ ] Clock-skew guard (PRD §17): if device clock rewinds >24h, freeze streak increments for 24h + log `clock_anomaly`
- [ ] Streak milestone trigger → navigate to `/streak-milestone` celebration

### 2.1e Plan generator (`lib/game/plan_generator.dart`)
Implements PRD Appendix B in Dart.
- [ ] Input: profile + goals + experience + schedule
- [ ] `pick_split(days_per_week, priority_muscles)` — 2d full-body / 3d PPL / 4d U-L×2 / 5-6d bro-split or PPLUL
- [ ] Filter by `experience.equipment`, swap around `experience.limitations`
- [ ] Volume multiplier by tenure: {beginner 0.8, starting 1.0, some 1.1, experienced 1.2}
- [ ] Per session: 1–2 compounds + 3–4 accessories
- [ ] Sets × reps by `goal.body_type` (hypertrophy / strength / endurance mix)
- [ ] Regenerates on goal/equipment/schedule edits

## 2.2 Workout logger — wire to real persistence
Phase 0 has the UI + a Provider-backed XP bump. Now replace with real:

- [ ] `WorkoutSession` state in SQLite (`workouts` row created on session start, `sets` rows inserted on each completeSet)
- [ ] XP calculated by `XpService`, written to `sets.xp_earned` and rolled up into `workouts.xp_earned`
- [ ] Muscle rank recomputed on save (`RankService.recomputeFor(muscles)`)
- [ ] PR detection emits `[System]` in-app banner (PRD §14)
- [ ] Active quest progress updated on save
- [ ] Session summary modal on finish: duration, total volume, XP earned, sets completed, new PRs, rank changes
- [ ] `+Add Set`, `+Add Exercise`, Swap sheet wired up
- [ ] Rest timer persists across backgrounding (don't lose the countdown if user leaves app mid-rest)
- [ ] Haptics: light on set complete, success on level-up

## 2.3 Today's Workout screen (new, not in Phase 0)
Per PRD §9A.2.
- [ ] Route `/home/todays-workout`
- [ ] Session summary chip-row (category / duration / exercises count)
- [ ] Muscle split % tags color-coded by recency
- [ ] "Why this workout?" expandable (System-voice rationale)
- [ ] Exercise cards with Swap (sheet of 3 alternates by muscle + equipment + limitations)
- [ ] Edit mode (drag handle + delete icon, Add exercise) writing to `workout_overrides`

## 2.4 Muscle Rankings drill-down (new)
Per PRD §9A.4.
- [ ] Route `/profile/ranks` (list) + `/profile/ranks/:muscle` (drill-down)
- [ ] Anime body with Lottie pulse rate proportional to rank
- [ ] Overall rank badge + tier explainer sheet
- [ ] Drill-down: rank progress bar, XP to next tier, PR history, recent volume chart

## 2.5 Local notifications — `notifications_service.dart`
PRD §14 — 100% local, zero APNs/FCM.
- [ ] `flutter_local_notifications` setup (iOS + Android permission prompts)
- [ ] Schedule workout reminders from `schedule.days` (1h before typical log time)
- [ ] Streak warnings at 19:00 local on scheduled days with no log
- [ ] Weekly progress report at Sunday 20:00 local
- [ ] Immediate in-app banners: PR alert, quest complete
- [ ] iOS: rolling 14-day window, re-fill at each launch (64-slot cap)
- [ ] Android 12+: exact-alarm fallback via `workmanager` + `AlarmManager`
- [ ] Reboot survival test
- [ ] DST-safe (test clock rolling forward + back)

## 2.6 Paywall + in-app purchases — `purchase_service.dart`
PRD §13.
- [ ] Add `in_app_purchase` dependency
- [ ] Build Paywall screen (§8 screen 21 full build-out): 3 tiers, Best Value preselected, "ACTIVATE PRO" button, skip in header
- [ ] Surfaces (PRD §13 triggers): end of onboarding, after 4th workout/week cap, locked boss tap, Day 3 streak milestone
- [ ] Cache pricing on last online fetch; show cached when offline
- [ ] On purchase: validate receipt, write to `subscriptions` table, cache `receipt_data`
- [ ] 7-day grace period — do not downgrade Pro → Free on 1 failed online check
- [ ] Re-validate opportunistically in background
- [ ] Pro-gated features read `SubscriptionService.isPro()` (returns true while grace window valid)
- [ ] Offline-tapped "Upgrade" shows `[System] Connection required to activate. Your streak is safe.`

## 2.7 Analytics — `analytics_service.dart`
PRD §15.
- [ ] All events write synchronously to `analytics_events` table
- [ ] Event schema (12 events + `app_opened_offline`, `analytics_upload_flushed`)
- [ ] Auto-tag every event with `user_level`, `user_tenure_days`, `sub_status`, `captured_offline`
- [ ] Anonymous `install_id` in `shared_preferences`; no PII
- [ ] Background `workmanager` job flushes batches to PostHog on Wi-Fi + opt-in
- [ ] Events older than 30 days get purged (`uploaded_at` set or row deleted)
- [ ] Settings → Clear analytics (user wipe of outbox)

## 2.8 Crash reporting
- [ ] `sentry_flutter` integration with local ring buffer write before network
- [ ] Crashes land in `crash_reports` table; flush opportunistically next launch
- [ ] Never block startup on Sentry

## 2.9 Tests (Phase 2)
- [ ] Unit: XP formula (every RPE × PR × level boundary)
- [ ] Unit: rank thresholds (every Bronze/Silver/.../Grandmaster boundary; tie-break with priority muscle)
- [ ] Unit: quest rotation (04:00 local; catch-up after missed rotation; timezone changes)
- [ ] Unit: streak (scheduled-day increment; missed day freeze auto-consume; clock skew detection)
- [ ] Unit: plan generator (2d/3d/4d/5d/6d splits; all body types; limitation-driven swaps)
- [ ] Integration: log a workout in airplane mode → XP + rank + streak + quest progress all update in SQLite within 2s
- [ ] Integration: purchase-flow happy path + grace period (mock network outage after cache)

## Phase 2 exit criteria
- [ ] Full loop works in airplane mode: log a workout → XP awarded → rank recomputed → quest progresses → streak updates → PR banner fires (if applicable)
- [ ] Local notifications fire at correct local times, survive reboot, survive DST
- [ ] Paywall reachable from all 4 surfaces in PRD §13
- [ ] Pro entitlement cached and honored offline through `renews_at`
- [ ] Analytics events persist locally when offline and flush when online
- [ ] Crash reports persist locally when offline and flush on next online launch
- [ ] Rank + XP update within 2s of set save (PRD §19)

---

# Phase 3 — v1.0 Public Launch (PRD roadmap: Wk 13–16)

**Goal:** weekly + boss quests, celebrations wired to real events, settings, data export/import, Pro-gated advanced analytics, full §19 acceptance pass, store submission.

## 3.1 Weekly quests
PRD §9.4.
- [ ] Pool: "Train 4 days", "Beat a PR", "Log RPE on every set", "Add 5kg on any lift", etc.
- [ ] Reset Monday 00:00 local via `workmanager`
- [ ] 200–500 XP range
- [ ] Pro-gated (free tier sees locked state + paywall surface)

## 3.2 Boss quests
PRD §9.4 + §9A detail.
- [ ] Curated pool for MVP (e.g. "Deadlift bodyweight × 2", "Add 10% to bench e1RM in 6 weeks")
- [ ] Multi-week objectives with 2000+ XP payout
- [ ] Themed boss art bundled in `assets/art/`
- [ ] Boss Detail screen (already built in Phase 0 — now wires to real progress)
- [ ] On complete → Boss Completion celebration screen + permanent buff (e.g. "Iron Heart: +10% XP on compounds for 7 days")

## 3.3 Celebration flows — wired to events (not demo nav)
Phase 0 has the UI; now wire the triggers.
- [ ] Level Up: triggered when `xpCurrent ≥ xpMax` during set-save flow; animates, increments level, resets XP bar
- [ ] Streak Milestone: triggered by `StreakService` on 7 / 14 / 30 / 60 / 90 / 180 / 365 days
- [ ] Boss Completion: new celebration screen — class-specific buff granted

## 3.4 Settings screens
PRD §9.6.
- [ ] `/profile/settings` hub
- [ ] Edit onboarding answers (opens the same 21 screens in `edit` mode, writes diff to SQLite)
- [ ] Units toggle (metric/imperial) — live-flips all readouts
- [ ] Notification prefs toggles (3)
- [ ] Subscription management (current plan, renewal date, Manage → store sheet)
- [ ] Export data (CSV + SQLite file) — see 3.5
- [ ] Delete account (confirm dialog → cascade delete + key wipe)
- [ ] About: version, PRD/DS links

## 3.5 Data export + import
PRD §6.1 + §11.7 backup/restore.
- [ ] Export → human-readable CSV of (workouts, sets, weight_logs, streaks) + raw SQLite file
- [ ] Share sheet to Files / Drive / email
- [ ] Import: confirm dialog → schema-version check → atomic replace
- [ ] Both openable on desktop (acceptance test)

## 3.6 Advanced analytics screens (Pro-gated)
- [ ] e1RM graph per lift (Pro)
- [ ] Volume-per-muscle bar chart, 4-week rolling (Pro)
- [ ] Cosmetic rank-badge skins (Pro; cosmetic only, no gameplay effect)
- [ ] Custom plan regeneration (Pro; regenerates the 4-week plan)

## 3.7 Weight Tracker screen
PRD §9A.6 — present in scope but missing from Phase 0.
- [ ] Route `/profile/weight`
- [ ] Current weight card (number + delta + target chip)
- [ ] Segmented tab: Start / Current / Target
- [ ] 30D / 90D / 1Y line chart with teal-violet gradient + ember particles
- [ ] Log weight modal (numeric + unit toggle + optional note; UNIQUE per day)

## 3.8 Player Class details sheet (new)
PRD §9A.7.
- [ ] Bottom sheet from Profile's Player Class card
- [ ] Class buffs, recommended quest types, evolution options
- [ ] Class reassignment flow (every 30 days)
- [ ] Derivation matrix applied on onboarding completion (§9A.7 rules)

## 3.9 Accessibility pass (cross-cutting, land here)
PRD design-system §10.
- [ ] Contrast audit: 4.5:1 body / 3:1 display across every screen
- [ ] Every glow-colored status also has a label or icon
- [ ] Dynamic type 85%–135% (display caps 135%, body scales freely)
- [ ] Semantic labels on every `InkWell` / `GestureDetector`
- [ ] VoiceOver / TalkBack pass (every screen traversable)
- [ ] Motion-reduction setting honored (disable pulses, shimmers, XP toast rise)
- [ ] Min touch target 44×44 verified via widget tests

## 3.10 Localization scaffolding
- [ ] `intl` + `.arb` files, base `en`
- [ ] Extract all hard-coded strings (design brand words like "LEVEL UP IRL" stay English)
- [ ] India/SEA launch geos: queue Hindi + Indonesian translations for v1.0 or v1.1 (decision point)

## 3.11 Performance
- [ ] Cold launch on airplane mode ≤2s to Home (PRD §19)
- [ ] 60fps scroll on Profile muscle-ranks list (10 rows with animated badges)
- [ ] Bundle size budget: <50MB APK / <80MB IPA (incl. Lottie + art)

## 3.12 Acceptance criteria (full PRD §19 pass) — BLOCKING for launch

### 3.12a Rendering & flows
- [ ] All 21 onboarding + 7 post-registration screens render on iPhone SE → Pro Max + Android 360dp → 480dp with no clipping
- [ ] Paywall reachable from all 4 triggers in §13
- [ ] Push notifications fire at correct local times across DST

### 3.12b Offline-first (PRD §19 — blocking)
- [ ] Airplane-mode smoke test: install fresh → onboard → log workout → complete daily quest → hit streak milestone → edit profile → export data — zero network errors shown
- [ ] Cold launch on airplane mode ≤2s, reaches Home with no network-contingent spinner
- [ ] Every user-visible write hits SQLite synchronously before UI advances (instrumentation test: `kill -9` after every `completeSet()` → set persisted on relaunch)
- [ ] Onboarding state survives app kill
- [ ] Workout saves update Home's "total workouts" count within 500ms
- [ ] XP + rank update within 2s of set save
- [ ] Streak calendar populates from SQLite only — zero network calls
- [ ] Export produces valid SQLite file + human-readable CSV
- [ ] Delete my data wipes all SQLite rows + SQLCipher key
- [ ] 30-day migration round-trip passes for every schema version
- [ ] Pro entitlement honored for full `renews_at` window with permanently disabled network

### 3.12c Reliability & security
- [—] SQLCipher ON by default; raw SQLite viewer cannot open DB — **deferred to v1.0.1+ per §1.2 decision**
- [ ] Crash-free sessions ≥99.5% over 7 days of beta
- [ ] Store listings (screenshots, preview video) approved in both stores
- [ ] Network-interception test: zero user data egress except (a) anonymised analytics with `install_id`, (b) store-billing receipts

## 3.13 Store submission
- [ ] App Store Connect listing + screenshots (iPhone SE, Pro Max, iPad optional)
- [ ] Play Console listing + screenshots
- [ ] Privacy policy linked (declare: local-only user data; analytics opt-in; no PII)
- [ ] Age rating + content declaration (fitness; body-fat estimate labeled "estimate only, not medical advice" — PRD §17)
- [ ] Localized ₹ pricing configured in App Store Connect + Play Console
- [ ] TestFlight / Internal Testing beta ≥7 days before public launch

## Phase 3 exit criteria
- [ ] All boxes in 3.12 checked
- [ ] Builds submitted to both stores; both approved
- [ ] Beta cohort (target 200 installs) meets onboarding completion ≥65% (PRD §5)
- [ ] No critical or blocking bug open in issue tracker

---

# Phase 4 — v1.1+ Post-MVP (deferred)

Not built in MVP. Listed for planning visibility only; do not start until v1.0 is stable for ≥4 weeks post-launch.

## 4.1 v1.1 (+6 wk) — sync & integrations
- [—] Cloud sync (introduces the first real backend; likely Supabase or Firestore)
- [—] Apple Health / Google Fit import (steps, body weight, heart rate)
- [—] Social feed (basic, opt-in)
- [—] Server-side receipt validation (replace client-only IAP check)

## 4.2 v1.2 (+10 wk)
- [—] AI form-check (upload video → feedback)
- [—] Pro theme toggle (PRD §17 risk mitigation: "gimmicky for general audience")

## 4.3 v1.3 (+14 wk)
- [—] Guilds / leaderboards
- [—] Friend challenges

## 4.4 v2.0 (+6 mo)
- [—] Web app
- [—] Custom program editor
- [—] Nutrition / calorie tracking

---

# Cross-cutting tracks (present in every phase)

## CI / CD
- [ ] GitHub Actions: `flutter analyze` + `flutter test` on every PR (no codegen step required)
- [ ] Fastlane lanes for iOS + Android release builds
- [ ] Version bump + changelog generation
- [ ] Automated screenshot capture for store listings (via integration tests)

## Quality gates per PR
- [ ] Analyzer clean
- [ ] All tests pass
- [ ] Coverage ≥70% on `services/` and `data/` layers
- [ ] No added dependencies without updating this plan's dep table
- [ ] Golden tests updated when UI changes

## Documentation
- [x] PRD ([PRD_GamifiedFitnessApp.md](PRD_GamifiedFitnessApp.md))
- [x] Design system ([DesignSystem_LevelUpIRL.md](DesignSystem_LevelUpIRL.md))
- [x] This plan
- [ ] CLAUDE.md / AGENTS.md for Claude-assisted workflows (optional)
- [ ] Readme with run instructions

---

# Dependencies & unblock-order

```
Phase 0 (done) ✓
    ↓
Phase 1.1 (sqflite + services) ✓ done
    ↓
Phase 1.3 (exercise seed)  ─────────┐
Phase 1.5 remaining onboarding ─────┤ screens persist via services
Phase 1.6 PlayerState over services ┘
    ↓
Phase 1 complete
    ↓
Phase 2.1 game engines ─────────────┐ (call data services)
    ↓                               │
Phase 2.2 logger wiring ────────────┤ (needs xp/rank engines)
    ↓                               │
Phase 2.5 notifications ────────────┤ (needs ScheduleService)
    ↓                               │
Phase 2.6 paywall + IAP ────────────┘ (needs SubscriptionService)
    ↓
Phase 3 polish + launch
```

**Current critical path:** Phase 1.3 (seed) + Phase 1.6 (rewire screens onto services). Until 1.6 lands, screens still read hard-coded constants — the persistence layer is plumbed but unused by the UI.

---

# Metrics targets (PRD §5) — track quarterly post-launch

| Metric | Target | Where measured |
|---|---|---|
| Onboarding completion rate | ≥65% | `onboarding_completed` / `onboarding_started` |
| D7 retention | ≥35% | PostHog cohort |
| D30 retention | ≥18% | PostHog cohort |
| Median workouts/week per DAU | ≥3 | `workout_finished` events |
| Sessions completing ≥1 quest | ≥55% | `quest_completed` / active session |
| Free → paid | ≥4% | `paywall_converted` / unique paywall views |
| Trial → paid | ≥40% | Store billing reports |
| Crash-free sessions | ≥99.5% | Sentry |

**North-star:** weekly active loggers who complete ≥1 quest.

---

**End of plan.**
