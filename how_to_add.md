# How to add content — LEVEL UP IRL

A reference for extending the app's content (exercises, quests, milestones, etc.) without touching the engines. Each section lists **the file(s) to edit**, **the shape of an entry**, and **gotchas** that will trip you up.

**Last updated:** 2026-04-25

---

## 1. New exercises (the catalog)

**Single file to edit:** [lib/data/seed/exercise_catalog.dart](lib/data/seed/exercise_catalog.dart) — a `const exerciseCatalog = <Exercise>[ ... ]` list of 80 entries.

Each entry takes:

```dart
Exercise(
  name: 'Bulgarian Split Squat',         // unique
  primaryMuscle: 'quads',                 // one of the canonical 10
  secondaryMuscles: ['glutes', 'hamstrings'],
  equipment: ['dumbbell', 'bodyweight'],  // canonical equipment keys
  baseXp: 5,                              // 5 = compound, 3 = accessory
  cueText: 'Front knee tracks toes; back knee kisses floor.',
)
```

### Constraints / gotchas

- `primaryMuscle` must be one of the 10 tracked muscles in [lib/game/rank_engine.dart:36](lib/game/rank_engine.dart#L36): `chest, back, shoulders, biceps, triceps, core, quads, hamstrings, glutes, calves`. Anything else won't surface in muscle ranks or the plan generator.
- `equipment` keys must match the values in [lib/screens/equipment_screen.dart:48](lib/screens/equipment_screen.dart#L48): `barbell, dumbbell, kettlebell, resistance_band, pullup_bar, cable_machine, bench, squat_rack, bodyweight`. Adding a new key requires also adding it to that screen's option list AND to PlanGenerator's `_equipmentOk` filter.
- `baseXp = 5` means "compound" — the plan generator prefers these as the primary pick per muscle. `baseXp = 3` accessories fill the second slot.
- Re-seed is idempotent: `AppDb.init()` only seeds when the catalog table is empty, and `insertBatch` uses `ConflictAlgorithm.ignore` on the unique `name` constraint — so adding new entries is safe, but **renaming an existing entry creates a new row** rather than updating. To replace, change `name` plus delete the old row by hand (or bump schema version and migrate).
- For the plan generator to actually pick a new exercise, the user's equipment + the focus muscles must overlap. A new "barbell quad" exercise won't appear for a bodyweight-only user.

---

## 2. New daily quests

**Single file to edit:** [lib/game/quest_engine.dart:20](lib/game/quest_engine.dart#L20) — the `dailyPool` list.

Each entry:

```dart
DailyQuestTemplate(
  kindKey: 'volume_goal',           // *must* be one of the handled cases
  title: 'HIT 1000 KG OF VOLUME',
  target: 1000,
  xp: 60,
)
```

### The catch — `kindKey` must have an `_incrementFor` case

In the same file ([quest_engine.dart:121](lib/game/quest_engine.dart#L121)), 4 kinds are handled today:

- `complete_workout` — +1 per finished workout
- `sets_logged` — +N per workout where N = sets in the session
- `volume_goal` — +volumeKg per workout
- `compound_lift` — +1 if the workout included any baseXp ≥ 5 exercise

### Adding a new quest with one of the existing kinds

= 1-line append to `dailyPool`. Done.

### Adding a new quest with a new kind

= 3 steps:

1. Add the template to `dailyPool` with a new `kindKey` (e.g. `'pr_set'`).
2. Add a case to `_incrementFor` that derives the increment from the workout/sets data passed in. The function signature today is `({kindKey, workout, setsInWorkout, maxBaseXpInWorkout})` — if you need data not in that tuple (e.g. number of PRs in the session), extend the signature and adjust the call site in [game_handlers.dart:44](lib/game/game_handlers.dart#L44).
3. Optional: add a unit test in `test/game/`.

### Rotation behavior

`rotateDailyIfNeeded` picks 3 from the pool seeded by day-of-year, so adding more templates spreads the rotation out automatically (each shows up roughly `pool.length / 3` days per cycle).

---

## 3. New weekly / boss quests

These are **not implemented** today — they're §3.1 / §3.2 in the plan and currently render as locked placeholders. To wire them up you'd need:

- A `WeeklyQuestTemplate` analogous to `DailyQuestTemplate`, with a `weeklyPool` list and a `rotateWeeklyIfNeeded()` that resets every Monday 00:00 local.
- A new `_incrementFor` (likely accumulating across all workouts in the week, not per-workout).
- Schema-wise: nothing new — `quests.type = 'weekly'` already works, just needs `expiresAt` set to next Monday.
- Boss quests are larger structural work (multi-week, themed art, permanent buffs).

So if your goal is just **more daily-style content**, stay with §2. Weekly is a Phase 3 build-out.

---

## 4. Onboarding / profile content

These are static option lists in the screens themselves:

| What | File | Shape |
|---|---|---|
| Body types | [body_type_screen.dart:39](lib/screens/body_type_screen.dart#L39) | `_options = [(key, label), ...]` — also wire reps/sets in [plan_generator.dart `_setsReps`](lib/game/plan_generator.dart) |
| Priority muscles | [priority_muscles_screen.dart](lib/screens/priority_muscles_screen.dart) — chip options | Must match the 10 tracked muscles |
| Reward style | [reward_style_screen.dart](lib/screens/reward_style_screen.dart) | Currently cosmetic — not consumed by any engine yet |
| Tenure | [tenure_screen.dart](lib/screens/tenure_screen.dart) | Currently cosmetic |
| Equipment | [equipment_screen.dart:39](lib/screens/equipment_screen.dart#L39) | Adding a new key requires updating exercise catalog + PlanGenerator filter |
| Limitations | [limitations_screen.dart](lib/screens/limitations_screen.dart) | Adding a key requires adding it to PlanGenerator's `_limitationToAvoid` map |
| Training styles | [training_styles_screen.dart](lib/screens/training_styles_screen.dart) | Currently cosmetic |
| Session length | [session_minutes_screen.dart:39](lib/screens/session_minutes_screen.dart#L39) | Drives PlanGenerator exercise cap |

"Currently cosmetic" = persisted to SQLite but no engine reads it back. If you want one of those to influence the plan or quests, you'd extend the relevant engine.

---

## 5. New plan-generator splits / focuses

**File:** [lib/game/plan_generator.dart](lib/game/plan_generator.dart)

Two const maps drive everything:

- `_splitByDays` — for each day count (2..7), a list of focus tags by day position. Add a new day count or change the rotation here.
- `_muscleGroupsByFocus` — what muscles each focus tag includes. Add new focuses here (e.g. `'arms'`, `'posterior_chain'`).

`_focusLabel` formats the tag for the UI. Sets/reps come from `_setsReps(bodyType)`.

---

## 6. Streak milestones

**File:** [lib/game/streak_engine.dart:20](lib/game/streak_engine.dart#L20) — `_milestones = [7, 14, 30, 60, 90, 180, 365]`.

Add a number to the list and it's automatically detected; the streak screen and milestone screen both read from this same list, so the "Next milestone" countdown updates for free.

Add a new label to `_titleFor` / `_subtitleFor` in [streak_milestone_screen.dart](lib/screens/streak_milestone_screen.dart) if you want a unique celebration headline.

---

## 7. Muscle ranks — tier thresholds

**File:** [lib/game/rank_engine.dart:27-32](lib/game/rank_engine.dart#L27-L32).

The Bronze/Silver/Gold/Platinum/Diamond/Master `Max` constants are the thresholds. Sub-ranks (I/II/III) are computed via `_thirds()` automatically.

To add a new tier, extend:

- `assign()` and `progressInTier()` in [rank_engine.dart](lib/game/rank_engine.dart)
- The `Rank` enum in [widgets/rank_badge.dart](lib/widgets/rank_badge.dart)
- Gradient colors in [theme/tokens.dart](lib/theme/tokens.dart)

---

## TL;DR — the easy wins

If you want to **expand content without touching engines**:

1. **More exercises** → append to `exercise_catalog.dart`. Lowest effort, biggest effect.
2. **More daily quests using the 4 existing kinds** → append to `dailyPool`. One line each.
3. **More streak milestones** → append numbers to `_milestones`.

If you want to **expand mechanics** (new quest kinds, new equipment categories, new tier structure), each requires both a data-side and an engine-side change — touch points are listed in each section above.
