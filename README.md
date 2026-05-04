# LEVEL UP IRL

A gamified fitness app — train IRL, earn XP, level up, climb friend leaderboards.
Flutter mobile app (iOS + Android), offline-first sqflite, Supabase cloud sync.

## Stack

- **Flutter** — single codebase for iOS + Android
- **sqflite** — local source-of-truth (works offline; cloud is a mirror)
- **Supabase** — Postgres + Auth + Realtime, Mumbai region (India-first launch)
- **provider** — app state
- **go_router** — routing with redirect-based onboarding gate

## Run locally

Prereqs: Flutter SDK ≥3.5, Xcode (iOS), Android Studio + SDK (Android), GNU Make.

```bash
# 1. Clone + install deps
flutter pub get

# 2. Add the Supabase credentials this app expects
cp .env.example .env
# Edit .env — paste your Supabase project URL, publishable key, and
# phone-hash salt. (Provision a project + apply migrations per
# supabase/README.md.)

# 3. Run
make run                                              # default simulator/device
make run DEVICE=F0A7DCBB-1891-41E2-8F89-7EE9142C87D7  # specific device
```

`make run` reads `.env` and translates each `KEY=VAL` line into a
`--dart-define=KEY=VAL` flag passed to `flutter run`. The `.env` file
is gitignored AND no longer bundled as a Flutter asset (P0-2), so
credentials cannot leak into a release APK / IPA.

If you don't have `.env` set up, `make run` still works — the app
launches in offline-only mode (no socials, no leaderboard). All
local-first features (workouts, XP, streak, ranks) work fine.

Want to run with the production app icon + bundle ID? `make run-prod`
uses the `prod` flavor (Android bundle ID `com.example.gym_levels`,
label `Level Up IRL`) instead of the `dev` flavor (`.dev` suffix,
label `Level Up Dev`) — both can install side-by-side.

## Build a release

```bash
make build-apk        # Android — release APK, prod flavor
make build-ipa        # iOS — release IPA, requires signing
```

These wrap `flutter build` with the `--flavor prod` and `--dart-define`
flags from `.env`. In CI, skip the Makefile and pass `--dart-define`
values directly from your secret store:

```bash
flutter build apk --release --flavor prod \
  --dart-define=PROJECT_URL=$PROJECT_URL \
  --dart-define=PUBLISHABLE_KEY=$PUBLISHABLE_KEY \
  --dart-define=PHONE_HASH_SALT=$PHONE_HASH_SALT
```

## Project layout

```
lib/
  data/        — sqflite schema, services, models, sync engine, Supabase client
  game/        — XP / rank / quest / streak / plan generator engines
  screens/     — every screen (auth, onboarding, home, workout, leaderboard, …)
  state/       — provider notifiers (PlayerState, OnboardingFlag)
  theme/       — design tokens (palette, type, spacing, motion)
  widgets/     — reusable UI (tab bar, pills, cards, founder badge, …)
  router.dart  — go_router config + redirect logic
  main.dart    — bootstrap, Supabase init, sync lifecycle, app root

supabase/
  migrations/  — schema, RLS, RPCs, triggers, cron — applied in numerical order
  README.md    — provisioning steps for the Supabase project

assets/        — images (hero art, body silhouettes, muscle panels)
test/          — unit + widget tests
```

## Key documents

- [PRD_GamifiedFitnessApp.md](PRD_GamifiedFitnessApp.md) — product requirements
- [DesignSystem_LevelUpIRL.md](DesignSystem_LevelUpIRL.md) — design tokens, motion, copy voice
- [plan.md](plan.md) — phase-by-phase implementation plan
- [socials_plan.md](socials_plan.md) — social tier + cloud sync (Scope B) plan
- [supabase/README.md](supabase/README.md) — backend provisioning + security baseline
- [how_to_add.md](how_to_add.md) — content authoring guide (exercises, quests)

## Tests + analysis

```bash
make analyze          # flutter analyze (clean expected on every commit)
make test             # all unit + widget tests (no .env required)
make clean            # flutter clean + iOS Pods wipe
```

## Architectural rules of thumb

- **Local-first.** Every user-visible write hits sqflite synchronously, *then* enqueues a cloud push. The UI never waits on the network.
- **Schema-versioned.** Bumping a sqflite column = a numbered migration in `lib/data/app_db.dart`. Bumping a Supabase column = a new file in `supabase/migrations/`. No untracked DDL.
- **RLS at the database, not in app code.** The Flutter client uses the anon key; every read/write is gated by Postgres RLS so a leaked key can't bypass authorization.
- **Anti-cheat lives server-side.** Per-row caps + delta caps + monotonicity checks are Postgres triggers. The app cannot push past them by editing local sqflite.
