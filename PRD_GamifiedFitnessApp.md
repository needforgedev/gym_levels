# Product Requirements Document
## Working title: **LEVEL UP IRL** — The Gamified Fitness System

**Author:** Product
**Status:** Draft v1.2
**Last updated:** 2026-04-20
**Changelog v1.2:** Re-platformed to **Flutter / Dart**. **Offline-first architecture** — all user-visible activities (onboarding, workout logging, quests, XP, muscle ranks, streaks, weight logs, profile edits, data export) run entirely on-device without network. **SQLite (via `sqflite` + `drift`) is the single source of truth**; no backend for MVP. §11 Technical Architecture, §11.1 Data Model (now SQLite DDL), §11.2 Repo Layout, §13 Monetization, §14 Notifications, §15 Analytics, §17 Risks, and §19 Acceptance Criteria rewritten to reflect offline-first posture.
**Changelog v1.1:** Added §9A (In-App Screens After Registration) with detailed specs for Home, Today's Workout, Workout Logger, Muscle Rankings, Streak, Weight Tracker, and Profile/Player Class screens. Updated §10 design system with in-app theme + tab bar. Updated §11.1 data model for `player_class`, `streak_freezes`, `weight_logs`, `body_stats`. Updated §12 rank tiers to match in-app Bronze/Silver naming. Added Player Class archetype to gamification rules.
**Platforms:** iOS, Android (**Flutter / Dart**, single codebase)
**Connectivity:** **Offline-first.** App is fully functional with airplane mode on. Network is only touched when the user explicitly initiates an online action (App/Play Store purchase validation, optional anonymous analytics upload — both deferrable).

---

## 1. Executive Summary

LEVEL UP IRL turns workouts into an RPG. Users are "Players" inside a "System" (Solo-Leveling-inspired UI) that ranks every muscle E → S, awards XP for lifts, issues daily/weekly/boss quests, and gates premium features behind a subscription. The flagship experience is a fully themed onboarding quiz that calibrates the Player, followed by a workout/quest loop and a muscle-rank progression dashboard.

The MVP ships the onboarding, the personalized plan that falls out of it, a workout logger that awards XP, daily/weekly/boss challenges, the muscle-rank dashboard, and a paywall. Social features and AI coaching come in v2.

**Offline-first posture (v1.2).** Gyms have notoriously bad reception. The MVP is built so every user-facing action — signing up, editing profile, logging a workout, earning XP, completing a quest, checking ranks, logging body weight, exporting data — works with no internet at all. A single on-device **SQLite** database (via Flutter's `sqflite` + `drift`) is the source of truth. There is no MVP backend: the app ships as a self-contained artifact. The only network touch-points are (a) store purchase validation when the user taps Upgrade, and (b) an optional, deferrable anonymous analytics upload — both are permitted to fail silently without blocking the user.

---

## 2. Problem & Opportunity

Fitness apps have two long-standing problems:

1. **Retention cliffs** — ~70% of fitness-app users churn within 30 days because logging feels like a chore, not a reward.
2. **Abstract progress** — "you lifted X kg" tells you nothing. Users want to *feel* progression.

The generation that grew up with RPGs, gacha games, and Solo Leveling already understands XP, tiers, quests, and bosses. Port those mechanics directly onto strength training and you get a loop people already know how to care about.

**Opportunity:** Intersection of fitness-tracking + mobile gaming + anime aesthetic — currently underserved. Closest peers (Zombies Run, Habitica, Finch) are either narrow-niche or non-fitness.

---

## 3. Vision & Principles

**Vision:** "Your workouts, but scored."

**Principles:**
1. **Every action is scored** — reps, sets, streaks, PRs, consistency all yield XP or rank movement.
2. **The UI is the game** — no "game mode" toggle; the entire app is themed (System voice, neon cards, calibrating loaders).
3. **Progression must be visible in 5 seconds** — a glance at the home screen shows XP bar, current rank, today's quests.
4. **Gate power, not progress** — free users can log and rank up; premium unlocks boss challenges, advanced analytics, AI form-check, and cosmetic skins.
5. **Honest calibration** — gamification is the wrapper; programming underneath is evidence-based (RPE, progressive overload, deload weeks).
6. **Offline-first, always.** The gym is the primary setting and most gyms have bad reception. Every feature MUST work in airplane mode. The loading state for a user action never says "waiting for network". SQLite is the source of truth; any future sync is an optimistic, background, last-write-wins overlay — never a blocker. No screen may show a spinner that is contingent on network.

---

## 4. Target Users

**Primary persona — "Aarav, 22, aspirational lifter"**
- Watches anime, plays mobile games, follows gym-fluencers.
- Has lifted on-and-off for a year, never stuck to a program for 8 weeks.
- Motivated by ranks, streaks, and showing off. Intimidated by spreadsheets.

**Secondary persona — "Sana, 28, returning athlete"**
- Trained seriously through college, life got in the way.
- Wants a structured plan without thinking. Enjoys the narrative of being an "adventurer."

**Non-goal persona:** competitive powerlifters, bodybuilders with coaches, elderly first-timers.

**Geos for launch:** India + SEA first (₹ pricing visible in video), then US/UK.

---

## 5. Goals & Success Metrics

| Goal | Metric | MVP target (90 days post-launch) |
|---|---|---|
| Onboard users deeply | Onboarding completion rate | ≥ 65% |
| Retain | D7 retention | ≥ 35% |
| Retain | D30 retention | ≥ 18% |
| Log workouts | Median workouts/week per DAU | ≥ 3 |
| Engage with gamification | % of sessions that complete ≥1 quest | ≥ 55% |
| Monetize | Free → paid conversion | ≥ 4% |
| Monetize | Trial → paid | ≥ 40% |
| Health | Crash-free sessions | ≥ 99.5% |

North-star metric: **weekly active loggers who complete ≥1 quest.**

---

## 6. Scope

### 6.1 In scope — MVP (v1.0)
- **Fully offline operation** — every feature below works with no internet, no account, no server.
- **On-device SQLite database** as single source of truth; seeded with exercise catalog on first run.
- Themed onboarding quiz (22 screens mapped below)
- Personalized weekly plan generation (runs entirely on-device)
- Workout logger with XP awards, offline-safe saves
- Muscle-rank dashboard (Bronze → Grandmaster per muscle group)
- Daily / Weekly / Boss challenges (rotation logic runs locally on a timestamp clock)
- Streak system + streak warnings (local notifications only)
- Local push notifications (reminders, streak warnings, weekly reports) — scheduled via `flutter_local_notifications`, never server-triggered
- Paywall (weekly / annual / best-value) — purchase validation is the single online call; cached entitlement works offline after
- **Local-only profile** — no email/Apple/Google sign-in required to use the app; a device-local `player` row replaces cloud auth
- Data export to on-device CSV file (share sheet to Files / Drive / email — user's choice; no server involved)
- **Local crash log + event buffer** — opportunistic upload when network is available; app never blocks on this

### 6.2 Out of scope — v1.0 (deferred to v1.1+)
- Cloud sync / multi-device (first restore will be via export/import of SQLite DB file)
- Cloud accounts (email, Apple, Google sign-in) — only needed for sync, which is v1.1
- Social features (friends, guilds, leaderboards)
- AI form-check from video
- Wearable integration (Apple Health, Google Fit, Garmin)
- Nutrition / calorie tracking
- Custom program editor
- Web app

### 6.3 Explicitly *not* building
- In-app currency / gacha pulls (retention-hostile; brand risk)
- Ads (conflicts with premium positioning)
- Server-side user data (no user row ever leaves the device in v1.0; compliance win as a side effect)

---

## 7. Information Architecture

```
Root (authenticated)
├── Home (today's dashboard)
│   ├── Active quests
│   ├── XP bar + current rank
│   └── Start workout CTA
├── Workouts
│   ├── Today's session
│   ├── Exercise logger
│   └── History
├── Ranks (muscle-by-muscle E→S board)
├── Quests (daily / weekly / boss tabs)
└── Profile
    ├── Stats & progress graphs
    ├── Settings (notifications, units, theme)
    └── Subscription

Pre-auth
├── Intro hype slides
├── Onboarding quiz (6 sections)
└── Paywall
```

---

## 8. Onboarding Flow — Full Screen Spec

The onboarding is the product's hook. Each section has its own neon accent color, an italic "System" subtitle ("*Scanning biological data…*"), a top progress bar, and a card with glowing border.

**Section color map**
- Player Registration → **Teal** (#19E3E3)
- Mission Objectives → **Purple** (#8B5CF6)
- Combat Experience → **Yellow** (#F5D742)
- Physical Attributes → **Teal** (#19E3E3)
- Daily Operations → **Green** (#22E06B)
- System Settings → **White** (#E6EEF5)

**Pre-quiz: Intro hype slides (swipeable carousel, 2 slides)**

| # | Screen | Purpose | Key elements |
|---|---|---|---|
| 1 | Muscle Ranks | Sell the rank system | Anime hero key art, E D C B A S tier chips, "TRACK EVERY GAIN" title, CONTINUE |
| 2 | Progression System | Sell the XP loop | Explosion art with rank coins, STRENGTH/ENDURANCE/POWER +XP list, "LEVEL UP IRL", CONTINUE |

**Interstitial: Calibrating loader** — reappears between each section, ~1.2s, animated progress 0→100%, "SYS • NET • DB • GPU" status chips that flip to green.

### Section 1 — Player Registration (teal, 0–10%)
| # | Title | Input | Validation | Saves to |
|---|---|---|---|---|
| 3 | "What shall the System call you, Player?" | Text, max 20 char | non-empty, 2–20 char | `profile.display_name` |
| 4 | "Current age detected:" | Slider 16–80 | required | `profile.age` |
| 5 | "Height measurement:" | Slider + CM/FT-IN toggle | required | `profile.height_cm` |

### Section 2 — Mission Objectives (purple, 15–25%)
| # | Title | Input | Rules | Saves to |
|---|---|---|---|---|
| 6 | "Which body type represents your goal?" | 4 anime avatar cards: Lean & Toned / Muscular & Defined / Strong & Powerful / Balanced & Functional | single-select, required | `goals.body_type` |
| 7 | "Select up to 3 muscle groups to prioritize:" | 10 chips (Chest, Back, Shoulders, Biceps, Triceps, Core/Abs, Quads, Hamstrings, Glutes, Calves) | multi-select max 3 | `goals.priority_muscles[]` |
| 8 | "What type of rewards excite you most?" | 4 radio: Achievements & Badges / Leveling Up & Ranks / Daily Streaks / Completing Challenges | single-select | `goals.reward_style` — used to tune notification copy |

### Section 3 — Combat Experience (yellow, 32–45%)
| # | Title | Input | Rules | Saves to |
|---|---|---|---|---|
| 9 | "How long have you been training?" | 4 radio cards: Complete Beginner / Just Starting Out / Some Experience / Experienced (1–3 yrs) | single-select | `experience.tenure` |
| 10 | "Select all equipment you have access to:" | 9 chips (Barbell & Plates, Dumbbells, Kettlebells, Resistance Bands, Pull-up Bar, Cable Machine, Bench, Squat Rack, Bodyweight Only) | multi-select ≥1 | `experience.equipment[]` |
| 11 | "Do you have any injuries or limitations?" | "None" + 8 chips (Lower Back, Knee, Shoulder, Wrist/Elbow, Hip, Neck, Other Joint, Chronic Condition) | multi-select; "None" is exclusive | `experience.limitations[]` |
| 12 | "What training styles have you tried before?" | 6 chips (Weightlifting, Powerlifting, CrossFit, Calisthenics, HIIT/Cardio, Never trained formally) | multi-select | `experience.styles[]` |

### Section 4 — Physical Attributes (teal, 50–57%)
| # | Title | Input | Rules | Saves to |
|---|---|---|---|---|
| 13 | "Current body weight:" | Slider 30–250 + KG/LBS toggle | required | `profile.weight_kg` |
| 14 | "Do you have a target weight goal?" | 3 radio: Gain / Lose / Maintain | single-select | `goals.weight_direction` |
| 15 | "Target body weight:" *(skipped if maintain)* | Slider + unit toggle | must differ from current by ≥2kg in chosen direction | `goals.target_weight_kg` |
| 16 | "Estimate your current body fat level:" | Slider with morphing avatar (Very Lean / Lean / Average / Above Average) | required | `profile.body_fat_estimate` |

### Section 5 — Daily Operations (green, 65–70%)
| # | Title | Input | Rules | Saves to |
|---|---|---|---|---|
| 17 | "Which days can you train?" | 3 presets (3 Days / 5 Days / Every Day) + 7 day-toggles | ≥2 days selected; presets auto-tick toggles | `schedule.days[]` |
| 18 | "How long are your typical workouts?" | 4 radio: 15–30 / 30–45 / 45–60 / 60–90 min | single-select | `schedule.session_minutes` |

### Section 6 — System Settings (white, 87%)
| # | Title | Input | Rules | Saves to |
|---|---|---|---|---|
| 19 | "Which notifications would you like?" | 3 toggles: Workout Reminders / Streak Warnings / Weekly Progress Reports | all default ON | `notifications.*` — triggers OS permission prompt on CONTINUE |

### Outro + monetization
| # | Screen | Purpose |
|---|---|---|
| 20 | Challenge System | Sell the quest loop (Daily 40-100 XP / Weekly 200-500 XP / Boss 2000+ XP), "BRING ON THE CHALLENGES" CTA |
| 21 | Paywall | "Turn Your Workouts Into A Game". 3 tiers, Best Value preselected, "ACTIVATE PRO" button. Small "skip" in header for free tier. |

**Onboarding completion trigger:** first render of Home screen fires `onboarding_completed` event with all collected fields.

---

## 9. Post-Onboarding Features

### 9.1 Home (today's dashboard)
- Greeting with display name + current rank badge
- XP bar for current level
- "Today's Quest" card (1 daily quest surfaced)
- "Start Training" primary CTA → today's generated workout
- Streak counter with flame icon
- Active boss challenge progress (if any)

### 9.2 Workout logger
- Plan-generated session with exercises sorted by muscle group
- Per-set inputs: weight, reps, RPE (1–10)
- Rest timer between sets with haptic ping
- "+XP" floating toast on each set completion
- Session summary screen on finish: total volume, XP earned, rank changes, new PRs

### 9.3 Ranks dashboard
- Anime hero silhouette with muscle groups overlaid
- Tap a muscle → drill-down: current rank (E–S), XP in this rank, what's needed for next rank, PR history
- **Rank formula (v1.1):** rolling 4-week max volume × max-weight × frequency → mapped to Bronze I → Grandmaster via the absolute thresholds in §9A.4. (Absolute thresholds preferred over percentile at launch to avoid unfairness at low user counts; revisit at 10k MAU.)

### 9.4 Quests
- **Daily (40–100 XP):** e.g. "Complete today's workout", "Hit 3 sets at RPE 8+", "Finish under 45 min". Rotate at 04:00 local time.
- **Weekly (200–500 XP):** e.g. "Train 4 days", "Beat a PR", "Log RPE on every set". Reset Monday.
- **Boss (2000+ XP, premium):** multi-week objectives, e.g. "Deadlift bodyweight × 2", "Add 10% to bench e1RM in 6 weeks". Themed boss art.

### 9.5 Streaks
- Incremented by completing ≥1 workout in the user's scheduled days.
- Grace day: 1 per week auto-applied.
- Streak-warning notification fires at 7pm local on a scheduled day if no workout logged.

### 9.6 Profile & settings
- Edit onboarding answers (opens the same screens in "edit" mode)
- Units (metric/imperial)
- Notification toggles
- Subscription management
- Export data (CSV)
- Delete account

---

---

## 9A. In-App Screens After Registration (detailed spec)

After the paywall decision (skip or subscribe), the user lands in the main app. Unlike the multi-colored onboarding, the in-app shell uses a **unified purple/violet theme** with amber accents — giving the sense that the "System" has settled into the user's Player profile.

### 9A.0 Global app shell

**Bottom tab bar** (4 items, pill-shaped glowing active state):
1. **Home** — house icon
2. **Quests** — speech/scroll icon
3. **Streak** — flame icon
4. **Profile / Player Class** — crown icon

**Top app bar** — contextual back arrow + screen title + per-screen trailing action (e.g. Edit).

**Theme (in-app):**
- Background: #0A0612 (deep violet-black)
- Primary accent: #8B5CF6 (violet glow borders, progress bars)
- Secondary accent: #F5A623 (amber — used for XP, level badges)
- Destructive/streak: #FF6B35 (flame orange)

All cards have a soft 1px violet glow border and subtle particle/ember background animation (Lottie loop at 15% opacity).

---

### 9A.1 Home / Dashboard

**Route:** `/(tabs)/home`

**Purpose:** In under 5 seconds the user knows their level, streak, today's workout, and can tap Start.

**Layout (top → bottom, scrollable):**
1. **Welcome header** — "Welcome back," + display name + Player-Class chip (e.g. "MASS"). Avatar top-right.
2. **Level strip** — two pills side-by-side:
   - Amber pill: "LV 12"
   - Violet pill: "14.3K XP"
3. **XP progress bar** — "Progress to Level 13" + % right-aligned, amber gradient bar with bounds label "250 XP / 1000 XP" below.
4. **Total Workouts card** — dumbbell icon + big number ("89") + "Total Workouts" label. Tap → workout history.
5. **Streak card** — flame icon + "47 day streak" + italic motivational subtitle ("On fire!"). Tap → Streak screen.
6. **Next Workout card** — icon + "Lower Body" title + meta row (duration • exercises count). Tap → Today's Workout.
7. **Start Workout** — primary teal CTA, sticky above tab bar.

**Data:** `current_level`, `current_xp`, `xp_to_next_level`, `total_workouts`, `streak.current`, `next_workout_summary`.

**States:**
- First-day user (0 workouts): Total Workouts card replaced with "Your journey begins" copy + arrow to tutorial.
- Rest day: Next Workout replaced with "Rest Day — recovery is a buff" card, Start Workout disabled or relabeled "Log free workout".

---

### 9A.2 Today's Workout

**Route:** `/(tabs)/home/todays-workout`

**Purpose:** Show the user exactly what they're about to do, let them swap exercises, and start the session.

**Elements (top → bottom):**
1. **Header** — back arrow, "Today's Workout" title, trailing **Edit** link.
2. **Session summary chip-row:**
   - Category chip (e.g. "Lower Body")
   - Duration chip (e.g. "~60 min")
   - Exercises count chip ("5 exercises")
3. **Muscle split tags** — colored pills showing % of volume per muscle (e.g. `quadriceps 35%` • `hamstrings 35%` • `glutes`). Color-coded by recency of training (red = high recent volume, orange = moderate, green = fresh).
4. **"Why this workout?" link** — expandable row. Tap to reveal a short System-voice explanation: *"Your priority muscles (Quads, Hams) are 72 hrs recovered. Previous bench day loaded shoulders — skipping today to avoid overreach."* Crucial for trust.
5. **Exercises list** — card per exercise:
   - Icon + exercise name
   - Target muscles summary ("abs, calves, glutes, +6 more")
   - Set rows (Set 1: 10 reps, Set 2: 10 reps, …)
   - **Swap** button (pill) — opens a sheet with 3 alternative exercises filtered by same muscle focus + available equipment + injury constraints.
6. **Start Workout** CTA (teal, sticky bottom).

**Edit mode:** Tap header Edit → same screen but every exercise row gets drag handle + delete icon, and an "Add exercise" button appears. Non-destructive: edits are stored as `workout_overrides` for that date only; underlying plan is untouched.

---

### 9A.3 Workout Logger (active session)

**Route:** `/(tabs)/home/session/{id}`

**Purpose:** Frictionless per-set logging with live XP feedback.

**Top stat row (sticky):**
- **Time** — elapsed timer (format `m:ss`)
- **Volume** — running total (kg×reps)
- **+XP** — running session XP
- **X** close (confirm dialog) on far left, **Finish** link on far right.

**Active exercise card (large, glowing violet):**
- Exercise icon + name + overflow menu (Swap / Replace / Note)
- Set indicator: "SET 1" (amber pill) + difficulty letter grade top-right ("D", auto-calculated from RPE vs target)
- Weight line: either `BODYWEIGHT` label or numeric stepper + KG/LBS unit
- Reps readout (big) + stepper
- **COMPLETE SET** primary CTA — on tap:
  - Saves set
  - Plays +XP animation floating up
  - Haptic success tap
  - Auto-starts rest timer
  - Advances to Set 2

**Remaining sets** — shown dimmed below the active card (`Set 2 — 10 reps`, `Set 3 — 10 reps`).

**Below the active card:**
- `+ Add Set` link
- Next exercise preview card ("Punch And Kick — 0 of 3")
- `+ Add Exercise` FAB

**Rest timer:** full-width bar at bottom when active; tap to skip or extend by 30s.

**Finish flow:** Summary modal — duration, total volume, XP earned, sets completed, new PRs (if any), rank changes. Primary CTA: Save → Home.

---

### 9A.4 Muscle Rankings

**Route:** `/(tabs)/profile/ranks`

**Purpose:** Show the headline RPG mechanic — every muscle has a visible rank.

**Elements:**
1. **Header** — back + "Muscle Rankings"
2. **Hero visual** — anime body silhouette with glowing muscle zones (Lottie). Zones pulse at a cadence proportional to that muscle's rank — higher rank = faster pulse.
3. **Overall Rank badge** — big amber-framed badge below the hero. Format: `Bronze III`. Tap for tier explainer sheet.
4. **Per-muscle list** — row per muscle:
   - Muscle icon
   - Muscle name (Chest, Shoulders, Quadriceps, …)
   - Tier chip ("Silver I")
   - XP in rank (e.g. `1240`)
   - Chevron → drill-down

**Drill-down screen:** Rank progress bar, "X XP to next tier", PR history for that muscle (bench PR for chest, squat for quads, etc.), recent set volume graph.

**Tier naming (v1.1 — revised from v1.0 E/D/C/B/A/S):**

| Tier | Sub-ranks | Volume-XP threshold |
|---|---|---|
| Bronze | I, II, III | 0 – 500 |
| Silver | I, II, III | 500 – 1500 |
| Gold | I, II, III | 1500 – 3500 |
| Platinum | I, II, III | 3500 – 7000 |
| Diamond | I, II, III | 7000 – 12000 |
| Master | — | 12000 – 20000 |
| Grandmaster | — | 20000+ |

Overall Rank is the weighted median across the 10 tracked muscle groups.

---

### 9A.5 Streak

**Route:** `/(tabs)/streak`

**Purpose:** Anchor the habit loop, surface Streak Freezes, render historical activity.

**Elements:**
1. **Header** — back + "Streak"
2. **Hero number** — flame icon + giant "47" + subtitle "day streak / On fire!"
3. **This Month** pill — "14 This Month"
4. **Streak Freezes card** — "Streak Freezes — 2/2 available" + row of freeze icons. Subtitle: "All freezes available". Tap → explainer sheet.
5. **Activity Calendar** — month grid (M T W T F S S header). Each day cell rendered as:
   - Amber filled square: workout completed
   - Violet outline: scheduled rest
   - Grey: missed
   - Snowflake overlay: freeze used
   - Today: pulsing ring
6. Month scrubber arrows (‹ February 2026 ›).

**Streak Freeze mechanic:** free users get 1/week auto-granted; Pro gets 2/week. Freeze auto-activates on a missed scheduled day if the user has one available — no manual action. Surface a toast the next session: "[System] Streak freeze deployed. 1 remaining this week."

---

### 9A.6 Weight Tracker

**Route:** `/(tabs)/profile/weight`

**Purpose:** Track body-weight change against the target set in onboarding.

**Elements:**
1. **Header** — back + "Weight Tracker" + trailing `+ Log weight` action.
2. **Current weight card** — icon + big number (e.g. `79.9 kg`) + green delta ("↓ 0.2 kg since last") + amber target chip ("5.1 kg to go").
3. **Tab row** — Start / Current / Target (segmented view; selected tab expands a comparison card).
4. **Weight Trend card:**
   - Title + 30D / 90D / 1Y segmented toggle
   - Line chart with glowing teal-to-violet gradient stroke and scattered ember particles at each data point
   - Y-axis labels auto-scaled, X-axis date ticks
   - Tap a point → tooltip with exact weight + date

**Logging modal:** single numeric input + unit toggle. Optional note. Max 1 log per day.

---

### 9A.7 Profile / Player Class

**Route:** `/(tabs)/profile`

**Purpose:** Identity page. Celebrates the Player Class archetype.

**Elements (top → bottom):**
1. **Profile header card** — circular avatar (initial), display name, email, trailing edit-pencil.
2. **Level + XP strip** — amber "LV 12" pill, violet "14,250 XP" pill.
3. **Progress bar** — "Progress to Level 13" + % (e.g. 25%) + range labels (250 XP / 1,000 XP).
4. **PRO MEMBER** chip (amber outlined) — if subscribed. For free users: "UPGRADE TO PRO" CTA instead.
5. **Player Class card** — glowing amber-framed card:
   - Large class artwork (e.g. "MASS BUILDER" anime-style badge)
   - Class name ("Mass Builder")
   - One-line description ("Building size through volume and dedication.")
   - Tap → Class details sheet (buffs, recommended quest types, possible evolutions).
6. **Body Stats section** — grouped list:
   - Age — "25 years"
   - Height — "175 cm"
   - BMI — "24.5 (Normal)" (computed, read-only)
   - Weight — links to Weight Tracker
7. **Menu list** — Muscle Rankings • Edit Onboarding • Notifications • Units • Subscription • Export Data • Sign Out • Delete Account.

**Player Class derivation (auto-assigned post-onboarding, mutable later):**

| Class | Triggered when |
|---|---|
| **Mass Builder** | `body_type = Muscular/Defined` AND `weight_direction = Gain` |
| **Shadow Athlete** | `body_type = Lean & Toned` AND `weight_direction = Lose` |
| **Iron Warrior** | `body_type = Strong & Powerful` AND `tenure ≥ Some Experience` |
| **Balanced Monk** | `body_type = Balanced & Functional` |
| **Rookie Hunter** | default for `tenure = Complete Beginner` regardless of goal |

Class is surfaced on home (chip) and profile (full card). Reassignable every 30 days.

---



| Token | Value |
|---|---|
| `bg.base` | #05090C |
| `bg.card` | #0C131A |
| `border.glow.teal` | #19E3E3 |
| `border.glow.purple` | #8B5CF6 |
| `border.glow.yellow` | #F5D742 |
| `border.glow.green` | #22E06B |
| `text.primary` | #E6EEF5 |
| `text.muted` | #7B8794 |
| `font.display` | Rajdhani / Orbitron (uppercase, spaced) |
| `font.body` | Inter |
| `font.mono` | JetBrains Mono (for % and numeric readouts) |

**In-app (post-onboarding) overrides:**

| Token | Value | Usage |
|---|---|---|
| `inapp.bg` | #0A0612 | App shell bg |
| `inapp.accent.primary` | #8B5CF6 | Card borders, progress fill |
| `inapp.accent.secondary` | #F5A623 | Level badges, XP pills |
| `inapp.accent.streak` | #FF6B35 | Flame, streak alerts |
| `inapp.cta.primary` | #19E3E3 | Start/Complete CTAs |

**Tab bar** — 4 items, 72pt tall, `inapp.bg` with violet top-border glow. Active item: amber fill circle behind icon + particle sparkle on change.

**Motion:**
- Borders pulse at 2s cycle (opacity 0.6 → 1.0).
- Progress bars animate with easeOutQuart over 400ms.
- XP toasts rise + fade over 900ms.
- Calibrating loader uses a shimmer across the bar.

**Accessibility:**
- Minimum 4.5:1 contrast against `bg.base` for all body text.
- Glow colors are decorative; never sole signal — always paired with label/icon.
- Sliders support fine keyboard/voiceover increments.
- Motion-reduction setting disables pulses and shimmers.

---

## 11. Technical Architecture

**Posture:** Offline-first, single-device, zero-backend for MVP. The app ships as a self-contained Flutter binary; the user can install and play without ever connecting to the internet. Network is an optimistic optimisation, never a requirement.

### 11.0 Client stack (Flutter / Dart)

| Concern | Package / approach |
|---|---|
| Language | **Dart 3.x** |
| Framework | **Flutter** (single codebase, iOS + Android) |
| Routing | `go_router` (declarative, type-safe) |
| State management | `provider` for v1.0; migrate to `riverpod` if complexity grows |
| Theming | `ThemeExtension` + a hand-rolled tokens file (`lib/theme/tokens.dart`) matching the design-system doc |
| Animations / motion | Flutter's built-in `AnimationController` + `flutter_animate`; `lottie` for the calibrating loader and flame |
| Icons | Material Icons + custom `CustomPainter` for rank shields, flame, muscle figure, XP ring |
| Fonts | `google_fonts` (Rajdhani, Inter, JetBrains Mono) — pre-downloaded + bundled so cold-launch does not hit network |
| Haptics | `flutter/services` `HapticFeedback` |

### 11.1 Storage layer — **SQLite is the source of truth**

All user-facing writes go to SQLite synchronously on the UI event. There is no in-memory-only state that can be lost.

| Concern | Package / approach |
|---|---|
| Primary DB | **SQLite** via `sqflite` (iOS + Android platform channel) wrapped with **`drift`** (type-safe DAOs, reactive `Stream<List<Row>>` queries, migrations) |
| DB location | App documents directory, path `gym_levels.db`. Hidden from iCloud/Google backup by default; user-toggleable in Settings (v1.1). |
| Migrations | Drift schema versions; every schema bump ships a numbered migration that is unit-tested against a seed DB from the previous version. Never drop user data. |
| Encryption | `sqflite_sqlcipher` with a device-keychain-derived key (via `flutter_secure_storage`). Opt-in setting; **default ON** (body-fat estimate + weight logs are sensitive). |
| Key-value prefs | `shared_preferences` for small scalar settings (units, theme, last-seen onboarding step, reduced-motion). DB-scale data never lives here. |
| Secrets | `flutter_secure_storage` for the SQLCipher key and any purchase-receipt caches. |
| Seed data | Exercise catalog (~80 rows) ships as a bundled SQL asset (`assets/seed/exercises.sql`) and is loaded on first launch if the `exercises` table is empty. |
| Offline queue | Separate `outbox` table holds analytics + receipt-validation events for opportunistic upload. Rows never block the UI and can be purged without data loss. |

### 11.2 Where server-ish logic runs

There is no server. Everything that the prototype PRD described as an "edge function" runs on-device:

| Job | Where it runs | Trigger |
|---|---|---|
| XP award on set complete | Dart, in the workout-logger bloc/provider | On `completeSet()` |
| Muscle-rank recomputation | Dart, `RankService` | Once on workout save; also a nightly pass via `workmanager` for rolling 4-week windows |
| Daily / weekly quest rotation | Dart, `QuestService` scheduled with `workmanager` at 04:00 local | Background isolate; safe to miss — catches up on next launch |
| Streak warning push | `flutter_local_notifications` scheduled at 19:00 local on every `schedule.days` entry | Scheduled at onboarding; re-scheduled on any schedule edit |
| Weekly report push | Local notification Sunday 20:00 local | Same |
| Paywall receipt check | `in_app_purchase` or `purchases_flutter` (RevenueCat, optional) | On upgrade tap only; cached entitlement valid for 30d offline |

### 11.3 Payments (only online touchpoint)

**Preferred:** Flutter's official `in_app_purchase` talking directly to App Store / Play Billing. No server validation service in v1.0 — we trust the store receipt and cache entitlement + expiry in SQLite. This matches the offline-first principle: once a user has purchased, they can stay on airplane mode indefinitely without re-validation.

**Optional:** `purchases_flutter` (RevenueCat) if we decide we want cross-platform entitlement sync in v1.1 — it brings a server dependency, so it's a v1.1 decision, not MVP.

Products: `weekly_1050_inr`, `best_value_3200_inr` (3mo), `annual_8800_inr`.

### 11.4 Notifications

100% local. No APNs/FCM server. `flutter_local_notifications` schedules:
- Workout reminders (per `schedule.days`)
- Streak warnings at 19:00 local on a scheduled day with no logged workout
- Weekly progress report at Sunday 20:00 local
- PR alerts + quest completion toasts (immediate, in-app)

Local notifications survive device reboots (iOS: up to 64 pending slots; Android: WorkManager + AlarmManager fallback).

### 11.5 Analytics & crash reporting

**Design constraint:** the app must work perfectly with zero network calls. Therefore:

- All analytics events are written to a local `analytics_events` table.
- A background `workmanager` job opportunistically batches-uploads to **PostHog** when Wi-Fi is available and the user hasn't opted out.
- If the user is permanently offline, the events simply age out of the table after 30 days. The product still works.
- **Crash reporting:** `sentry_flutter` is configured with `captureLocally: true` — crashes are written to a local ring buffer and only uploaded opportunistically. No crash ever blocks app startup waiting on Sentry's network call.

### 11.6 Illustrations & assets

Commissioned anime-style key art bundled in-app (`assets/art/`). Lottie files for the calibrating loader and flame also bundled. Rank/quest icons from a single SVG sprite, rendered with `flutter_svg` or inline `CustomPainter`. No assets are fetched at runtime — this is essential for offline-first and also keeps cold-launch snappy.

### 11.7 Data model — SQLite DDL (v1.0)

Single-user, single-device. `user_id` is always `1` — the schema keeps the column for forward-compatibility with v1.1 cloud sync, but MVP never reads or writes any other value. SQLite has no array type, so `TEXT[]`-shaped fields are stored as **JSON-encoded TEXT** and type-checked at the Dart layer via drift converters. Timestamps are **`INTEGER` Unix-epoch seconds** (cross-platform, sortable, no TZ ambiguity).

```sql
-- ─────────────────────────────────────────────
-- Profile & onboarding
-- ─────────────────────────────────────────────
CREATE TABLE player (                       -- single row in v1.0
    id                  INTEGER PRIMARY KEY CHECK (id = 1),
    display_name        TEXT    NOT NULL,
    age                 INTEGER NOT NULL,
    height_cm           REAL    NOT NULL,
    weight_kg           REAL    NOT NULL,
    body_fat_estimate   TEXT,                -- 'very_lean'|'lean'|'average'|'above'
    units_pref          TEXT    NOT NULL DEFAULT 'metric',
    onboarded_at        INTEGER,             -- null until onboarding done
    created_at          INTEGER NOT NULL,
    updated_at          INTEGER NOT NULL
);

CREATE TABLE goals (
    user_id             INTEGER PRIMARY KEY REFERENCES player(id) ON DELETE CASCADE,
    body_type           TEXT,
    priority_muscles    TEXT NOT NULL DEFAULT '[]',   -- JSON array
    reward_style        TEXT,
    weight_direction    TEXT,                          -- 'gain'|'lose'|'maintain'
    target_weight_kg    REAL,
    updated_at          INTEGER NOT NULL
);

CREATE TABLE experience (
    user_id             INTEGER PRIMARY KEY REFERENCES player(id) ON DELETE CASCADE,
    tenure              TEXT,                          -- 'beginner'|'starting'|'some'|'experienced'
    equipment           TEXT NOT NULL DEFAULT '[]',   -- JSON array
    limitations         TEXT NOT NULL DEFAULT '[]',   -- JSON array
    styles              TEXT NOT NULL DEFAULT '[]',   -- JSON array
    updated_at          INTEGER NOT NULL
);

CREATE TABLE schedule (
    user_id             INTEGER PRIMARY KEY REFERENCES player(id) ON DELETE CASCADE,
    days                TEXT NOT NULL DEFAULT '[]',   -- JSON array of 0..6 (Mon..Sun)
    session_minutes     INTEGER,
    updated_at          INTEGER NOT NULL
);

CREATE TABLE notification_prefs (
    user_id             INTEGER PRIMARY KEY REFERENCES player(id) ON DELETE CASCADE,
    workout_reminders   INTEGER NOT NULL DEFAULT 1,
    streak_warnings     INTEGER NOT NULL DEFAULT 1,
    weekly_reports      INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE player_class (
    user_id             INTEGER PRIMARY KEY REFERENCES player(id) ON DELETE CASCADE,
    class_key           TEXT NOT NULL,                 -- 'mass_builder'|'shadow_athlete'|'iron_warrior'|'balanced_monk'|'rookie_hunter'
    assigned_at         INTEGER NOT NULL,
    last_changed_at     INTEGER NOT NULL,
    evolution_history   TEXT NOT NULL DEFAULT '[]'    -- JSON array of {class_key, changed_at}
);

-- ─────────────────────────────────────────────
-- Exercise catalog (seeded from asset on first run)
-- ─────────────────────────────────────────────
CREATE TABLE exercises (
    id                  INTEGER PRIMARY KEY,
    name                TEXT NOT NULL UNIQUE,
    primary_muscle      TEXT NOT NULL,
    secondary_muscles   TEXT NOT NULL DEFAULT '[]',   -- JSON array
    equipment           TEXT NOT NULL DEFAULT '[]',   -- JSON array
    base_xp             INTEGER NOT NULL DEFAULT 3,
    demo_video_url      TEXT,                          -- optional, may be null in offline build
    cue_text            TEXT
);
CREATE INDEX idx_exercises_primary_muscle ON exercises(primary_muscle);

-- ─────────────────────────────────────────────
-- Workouts & sets
-- ─────────────────────────────────────────────
CREATE TABLE workouts (
    id                  INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id             INTEGER NOT NULL REFERENCES player(id) ON DELETE CASCADE,
    started_at          INTEGER NOT NULL,
    ended_at            INTEGER,
    xp_earned           INTEGER NOT NULL DEFAULT 0,
    volume_kg           REAL    NOT NULL DEFAULT 0,
    note                TEXT
);
CREATE INDEX idx_workouts_user_started ON workouts(user_id, started_at DESC);

CREATE TABLE sets (
    id                  INTEGER PRIMARY KEY AUTOINCREMENT,
    workout_id          INTEGER NOT NULL REFERENCES workouts(id) ON DELETE CASCADE,
    exercise_id         INTEGER NOT NULL REFERENCES exercises(id),
    set_number          INTEGER NOT NULL,
    weight_kg           REAL,
    reps                INTEGER NOT NULL,
    rpe                 INTEGER,                        -- 1..10
    is_pr               INTEGER NOT NULL DEFAULT 0,
    xp_earned           INTEGER NOT NULL DEFAULT 0,
    completed_at        INTEGER NOT NULL
);
CREATE INDEX idx_sets_workout ON sets(workout_id);
CREATE INDEX idx_sets_exercise ON sets(exercise_id);

CREATE TABLE workout_overrides (
    id                  INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id             INTEGER NOT NULL REFERENCES player(id) ON DELETE CASCADE,
    scheduled_for       INTEGER NOT NULL,               -- day (epoch seconds at 00:00 local)
    overrides_json      TEXT NOT NULL,                  -- the edited session
    created_at          INTEGER NOT NULL
);

CREATE TABLE exercise_swaps (
    id                      INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id                 INTEGER NOT NULL REFERENCES player(id) ON DELETE CASCADE,
    original_exercise_id    INTEGER NOT NULL REFERENCES exercises(id),
    swapped_to_id           INTEGER NOT NULL REFERENCES exercises(id),
    workout_id              INTEGER REFERENCES workouts(id) ON DELETE SET NULL,
    reason                  TEXT,
    created_at              INTEGER NOT NULL
);

-- ─────────────────────────────────────────────
-- Progression
-- ─────────────────────────────────────────────
CREATE TABLE muscle_ranks (
    user_id             INTEGER NOT NULL REFERENCES player(id) ON DELETE CASCADE,
    muscle              TEXT NOT NULL,
    rank                TEXT NOT NULL,                  -- 'bronze'|'silver'|'gold'|'platinum'|'diamond'|'master'|'grandmaster'
    sub_rank            TEXT,                           -- 'I'|'II'|'III' (null for master/grandmaster)
    rank_xp             INTEGER NOT NULL DEFAULT 0,
    updated_at          INTEGER NOT NULL,
    PRIMARY KEY (user_id, muscle)
);

CREATE TABLE quests (
    id                  INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id             INTEGER NOT NULL REFERENCES player(id) ON DELETE CASCADE,
    type                TEXT NOT NULL,                  -- 'daily'|'weekly'|'boss'
    title               TEXT NOT NULL,
    description         TEXT,
    target              INTEGER NOT NULL,
    progress            INTEGER NOT NULL DEFAULT 0,
    xp_reward           INTEGER NOT NULL,
    issued_at           INTEGER NOT NULL,
    expires_at          INTEGER,
    completed_at        INTEGER,
    locked              INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX idx_quests_user_type_active ON quests(user_id, type, completed_at, expires_at);

CREATE TABLE streaks (
    user_id                 INTEGER PRIMARY KEY REFERENCES player(id) ON DELETE CASCADE,
    current                 INTEGER NOT NULL DEFAULT 0,
    longest                 INTEGER NOT NULL DEFAULT 0,
    last_active_date        INTEGER,                    -- epoch seconds at 00:00 local of last counted day
    freezes_remaining       INTEGER NOT NULL DEFAULT 1,
    freezes_period_start    INTEGER NOT NULL            -- week boundary for freeze replenishment
);

CREATE TABLE streak_freeze_events (
    id                  INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id             INTEGER NOT NULL REFERENCES player(id) ON DELETE CASCADE,
    used_on             INTEGER NOT NULL,
    reason              TEXT
);

-- ─────────────────────────────────────────────
-- Body metrics
-- ─────────────────────────────────────────────
CREATE TABLE weight_logs (
    id                  INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id             INTEGER NOT NULL REFERENCES player(id) ON DELETE CASCADE,
    logged_on           INTEGER NOT NULL,               -- epoch seconds at 00:00 local
    weight_kg           REAL NOT NULL,
    note                TEXT,
    UNIQUE (user_id, logged_on)                          -- 1 log per day per user
);
CREATE INDEX idx_weight_logs_user_date ON weight_logs(user_id, logged_on DESC);

-- body_stats is a runtime query in Dart, not a materialised view.
-- (SQLite supports views but drift's reactive queries make a plain JOIN simpler.)

-- ─────────────────────────────────────────────
-- Subscription (locally cached entitlement)
-- ─────────────────────────────────────────────
CREATE TABLE subscriptions (
    user_id             INTEGER PRIMARY KEY REFERENCES player(id) ON DELETE CASCADE,
    tier                TEXT NOT NULL DEFAULT 'free',   -- 'free'|'weekly'|'quarterly'|'annual'
    status              TEXT NOT NULL DEFAULT 'inactive',
    purchased_at        INTEGER,
    renews_at           INTEGER,
    receipt_data        TEXT,                            -- base64 blob for verification-on-next-online
    last_verified_at    INTEGER,
    updated_at          INTEGER NOT NULL
);

-- ─────────────────────────────────────────────
-- Offline outbox (analytics, deferred uploads)
-- ─────────────────────────────────────────────
CREATE TABLE analytics_events (
    id                  INTEGER PRIMARY KEY AUTOINCREMENT,
    name                TEXT NOT NULL,
    payload_json        TEXT NOT NULL,
    created_at          INTEGER NOT NULL,
    uploaded_at         INTEGER                          -- null = pending, non-null = sent
);
CREATE INDEX idx_analytics_pending ON analytics_events(uploaded_at) WHERE uploaded_at IS NULL;

CREATE TABLE crash_reports (
    id                  INTEGER PRIMARY KEY AUTOINCREMENT,
    created_at          INTEGER NOT NULL,
    payload_json        TEXT NOT NULL,
    uploaded_at         INTEGER
);
```

**Integrity rules:**
- All `user_id` FKs cascade on delete so "Delete my data" in settings is a single `DELETE FROM player WHERE id=1`.
- Drift DAOs enforce non-null invariants on the Dart side; the schema enforces on the SQL side.
- Migrations: a dedicated `schema_version` table tracks the applied version. Every version bump ships a forward-only migration unit-tested against a seed DB from the previous version.
- **No RLS** — RLS is a server-side concept. Single-device means access control is the OS's file-sandboxing + the SQLCipher key.

**Backup / restore (v1.0):**
- User can export the full SQLite file via Settings → Export to share to Files / Drive / email.
- Import is behind a confirm dialog and validates schema version before replacing the DB.
- This is the v1.0 "multi-device" story until cloud sync lands in v1.1.

### 11.8 Repo layout (Flutter)

```
gym_levels/
├── lib/
│   ├── main.dart                      // bootstraps DB, theme, router
│   ├── router.dart                    // go_router config
│   ├── theme/
│   │   ├── tokens.dart                // palette, space, radius, type, glow
│   │   └── app_theme.dart             // dark ThemeData
│   ├── state/
│   │   ├── player_state.dart          // ChangeNotifier over SQLite `player` row
│   │   └── session_state.dart         // active workout session draft
│   ├── data/                          // offline-first persistence
│   │   ├── database.dart              // drift Database, schema, migrations
│   │   ├── daos/
│   │   │   ├── player_dao.dart
│   │   │   ├── workout_dao.dart
│   │   │   ├── sets_dao.dart
│   │   │   ├── quest_dao.dart
│   │   │   ├── streak_dao.dart
│   │   │   ├── weight_log_dao.dart
│   │   │   └── analytics_dao.dart
│   │   └── seed/                      // bundled seeds (exercise catalog)
│   ├── services/                      // all business logic runs on-device
│   │   ├── xp_service.dart
│   │   ├── rank_service.dart
│   │   ├── quest_service.dart         // rotation, generation
│   │   ├── streak_service.dart
│   │   ├── plan_generator.dart        // Appendix B, in Dart
│   │   ├── notifications_service.dart // flutter_local_notifications wrapper
│   │   ├── purchase_service.dart      // the only online-capable service
│   │   └── analytics_service.dart     // writes to `analytics_events`; uploads opportunistically
│   ├── widgets/                       // shared UI primitives
│   │   ├── neon_card.dart
│   │   ├── progress_header.dart
│   │   ├── rank_badge.dart
│   │   ├── xp_ring.dart
│   │   ├── xp_toast.dart
│   │   ├── muscle_figure.dart
│   │   ├── tab_bar.dart
│   │   └── …
│   └── screens/
│       ├── onboarding/                // welcome, calibrating, objectives, experience, attributes
│       ├── home/                      // dashboard, today's workout
│       ├── workout/                   // logger, summary
│       ├── quests/                    // daily, weekly, boss, detail
│       ├── streak/
│       ├── profile/                   // class card, body stats, ranks drill-down, weight tracker
│       └── celebration/               // level up, streak milestone
├── assets/
│   ├── art/                           // bundled key art + class badges
│   ├── lottie/                        // calibrating loader, flame
│   ├── seed/
│   │   └── exercises.sql              // 80-exercise catalog
│   └── fonts/                         // Rajdhani, Inter, JetBrains Mono (bundled)
├── test/
│   ├── unit/                          // services (XP math, rank thresholds, quest rotation, plan gen)
│   ├── golden/                        // widget/pixel tests for the themed components
│   └── db/                            // migration round-trip tests
├── integration_test/                  // end-to-end offline flows (airplane mode simulated)
├── android/
├── ios/
├── pubspec.yaml
└── analysis_options.yaml
```

**Key directory contracts:**
- `data/` is the only place that touches SQLite. Screens never do raw queries — they go through DAOs.
- `services/` is pure Dart + DAO calls. Zero HTTP imports except in `purchase_service.dart` and the opportunistic uploader inside `analytics_service.dart`.
- `screens/` and `widgets/` are pure UI; they read state via providers and dispatch through services. They do not know SQLite exists.

---

## 12. Gamification Mechanics (precise rules)

**XP per set** = `base_xp × rpe_multiplier × pr_bonus`
- `base_xp` = 5 for compound lifts, 3 for accessories (from exercise catalog)
- `rpe_multiplier` = 0.6 at RPE 5, 1.0 at RPE 8, 1.3 at RPE 10
- `pr_bonus` = +25 XP if the set sets a weight-for-reps PR

**Level curve** (player level, not muscle rank):
- `xp_to_next(level) = round(100 × level^1.45)`
- Level 1 → 2 = 100 XP, Level 10 → 11 ≈ 2818 XP, cap at 99.

**Muscle rank** — see §9.3 and §9A.4 for the Bronze → Grandmaster tier ladder. Recomputed nightly by edge function. Overall Rank = weighted median across the 10 tracked muscles (priority muscles from onboarding weighted 1.5×).

**Player Class** — see §9A.7 for derivation rules. Class provides flavored copy + biases quest selection (e.g. Mass Builder gets more volume-based daily quests; Shadow Athlete gets more cardio/density quests). Class does not affect XP math — it's a flavor layer.

**Streak rules**
- Incremented once per scheduled day if ≥1 set logged with RPE ≥6.
- Missed scheduled day: 1 grace/week auto-used. Second miss resets streak.

---

## 13. Monetization

| Tier | Price (₹) | Price (USD est) | Billing |
|---|---|---|---|
| Weekly | ₹1,050 | $12.59 | 7-day |
| Annual | ₹8,800 | $105.49 | yearly |
| Best Value (3-month) | ₹3,200 | $38.35 | 90-day |

7-day free trial on Annual. Best Value preselected in UI (SAVE 64% vs weekly × 13).

**Free tier includes:** full onboarding, daily quests, muscle ranks, basic plan, 3 workouts logged per week cap.

**Premium unlocks:** unlimited logging, weekly + boss quests, advanced analytics (e1RM graphs, volume-per-muscle), cosmetic rank-badge skins, custom plan regeneration, data export.

**Paywall surfaces:**
1. End of onboarding (trial offer)
2. After logging the 4th workout in a week (limit hit)
3. When tapping a locked boss challenge
4. Day 3 streak milestone

**Offline behaviour for payments (v1.2):**
- The paywall is reachable offline and shows cached product pricing from the last online fetch; prices refresh next online launch.
- Tapping "Upgrade" is the **only** user action that requires network. If offline, we show `[System] Connection required to activate. Your streak is safe.` and the app remains fully usable on the free tier.
- On successful purchase, the receipt is validated once against App Store / Play Billing and the entitlement is cached in `subscriptions.receipt_data`. Subsequent launches read the cache — the Pro experience works fully offline for the duration of the entitlement.
- Entitlement is re-checked opportunistically in the background when network is available. A grace period of 7 days protects against transient billing outages — the user is never kicked off Pro because the store is down.
- All receipt validation caches age out at `renews_at`, after which a re-validation is required the next time the user comes online.

---

## 14. Notifications

**100% local.** Every notification below is scheduled by `flutter_local_notifications` from on-device state. **Zero server push.** This means notifications continue to fire correctly in airplane mode, on rural treks, or in any gym basement.

| Trigger | Copy (example) | Timing | Scheduled by |
|---|---|---|---|
| Workout reminder | "[System] Today's quest awaits, {name}." | 1h before user's typical log time | Local, on schedule edit |
| Streak warning | "[System] Streak at risk. Train in the next 3 hours to preserve rank." | 19:00 local on scheduled day with no log | Local, rescheduled nightly |
| Weekly report | "[System] Week {n} report ready. Rank movement: +2 tiers." | Sunday 20:00 local | Local, rolling weekly schedule |
| PR alert | "[System] New personal record detected — Bench +2.5kg." | On save | Immediate in-app banner |
| Quest complete | "[System] Quest complete: +80 XP." | On save | Immediate in-app banner |

**Implementation details:**
- All scheduled notifications are registered on app launch from the local DB state, so they survive reboots.
- iOS 64-pending-slot cap: we schedule a rolling 14-day window and re-fill at each launch.
- Android: WorkManager + exact-alarm fallback for Android 12+.
- All copy uses the "System" voice (brackets + terse, diagnostic tone).

---

## 15. Analytics (events)

**Offline-first analytics.** Every event below is written synchronously to the local `analytics_events` SQLite table as the user performs the action. A background `workmanager` job batches-uploads pending rows to PostHog when Wi-Fi is available **and** the user has not opted out in Settings. If the user is permanently offline, events age out of the table after 30 days — product functionality is unaffected.

The app must never block a user interaction waiting for an analytics call. The local write is synchronous; the network upload is fire-and-forget.

```
onboarding_started
onboarding_section_completed  { section, duration_ms }
onboarding_completed          { duration_ms, answers_summary }
workout_started               { session_id, source:"plan"|"custom" }
set_logged                    { weight, reps, rpe, is_pr, xp_earned }
workout_finished              { duration_min, xp_total, volume_kg }
quest_completed               { quest_id, type, xp }
rank_changed                  { muscle, from, to }
streak_incremented            { new_value }
paywall_shown                 { trigger }
paywall_converted             { tier, price }
paywall_dismissed             { trigger }
app_opened_offline            { pending_uploads }         // new in v1.2
analytics_upload_flushed      { count, ms, success }      // new in v1.2
```

Each event is auto-tagged with `user_level`, `user_tenure_days`, `sub_status`, and a boolean `captured_offline` flag so we can audit offline engagement after the fact.

**Privacy:** No PII in event payloads — display_name, email, weight values, or body-fat estimate are never sent. Identifier is a randomly generated `install_id` stored in `shared_preferences`. Users can wipe the outbox from Settings → "Clear analytics".

**Crash reporting:** `sentry_flutter` is configured so crash envelopes write to a local ring buffer (`crash_reports` table) before the network call. The first launch after a crash opportunistically uploads the pending envelopes; if offline, they persist indefinitely until uploaded or user-cleared.

---

## 16. Roadmap

| Release | Timeline | Highlights |
|---|---|---|
| **v0.1 Internal alpha** | Wk 1–6 | Onboarding + auth + data model |
| **v0.5 Closed beta** | Wk 7–12 | Workout logger, XP, ranks, daily quests, paywall, push |
| **v1.0 Public launch** | Wk 13–16 | Weekly + boss quests, analytics polish, store-ready assets |
| v1.1 | +6 wks | Apple Health / Google Fit import, social feed |
| v1.2 | +10 wks | AI form-check (upload video → feedback) |
| v1.3 | +14 wks | Guilds / leaderboards, friend challenges |
| v2.0 | +6 mo | Web app, custom program editor, nutrition |

---

## 17. Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Anime/System aesthetic feels gimmicky to general audience | Med | High | Keep the brand tight for launch geos (India/SEA); a "Pro" theme toggle in v1.2 |
| Rank formula feels unfair with small user base (percentile-based) | High | Med | Launch with absolute thresholds; switch to percentile at 10k MAU |
| Store rejection over "medical claims" in body-fat estimator | Low | High | Label as "estimate only, not medical advice"; avoid BMI/diagnosis language |
| Churn after trial | High | High | Weekly report email re-engages; re-onboarding flow when returning after 14d |
| ₹ pricing perception in US/EU | Med | Med | Localized pricing via `in_app_purchase` / store config from day 1 |
| Scope creep into nutrition / social at MVP | High | High | Hard no per §6.3; gated behind v1.1+ |
| **Offline — user loses device, loses all their data** | Med | High | In-app reminder to export their SQLite backup every 30 days; surface an "Export backup" action in the streak-milestone celebration. v1.1 adds cloud sync as the permanent fix. |
| **Offline — DB schema migration corrupts user data** | Low | Critical | Every drift migration is unit-tested against a seed DB from the previous version in CI. App takes a backup copy of `gym_levels.db` to `gym_levels.db.pre-migration` before any migration runs; automatic rollback if the migration throws. |
| **Offline — SQLCipher key lost (keychain wipe on factory reset)** | Low | High | At onboarding completion, show a one-time "save your recovery code" sheet. Recovery code is a 4-word mnemonic that re-derives the key. Skippable with explicit acknowledgement. |
| **Offline — clock skew (user sets device time back to game the streak)** | Med | Med | Compare device clock against last-seen timestamps; if the device clock goes backwards by >24h, freeze streak increments for 24h and log a `clock_anomaly` event. No hard fail — some timezone-travelling users will trip this. |
| **Paywall — user buys Pro, flies, Pro "disappears" when store check fails** | Low | High | 7-day grace period on cached entitlement; app never downgrades Pro → Free without 3 consecutive failed online re-validations. |
| **IAP — store receipt validated client-side only = easy to pirate** | Med | Low | v1.0 accepts this risk for offline-first simplicity. v1.1 adds optional server-side receipt validation via Apple/Google. |

---

## 18. Open Questions

1. Do we offer a lifetime tier? (proposed: ₹18,000, evaluate after 3 months of subscription data)
2. Should boss challenges be personalized (AI-generated) or curated? — propose curated for MVP, personalized post-v1.2.
3. Rank visibility in profile — public by default or private? — **propose private at launch**, social visibility with v1.3 guilds.
4. Do we need an onboarding "skip" option? — **propose no** for MVP; the calibration is the product. Re-evaluate if completion <60%.

---

## 19. Acceptance Criteria (MVP)

**Rendering & flows**
- [ ] All 21 onboarding screens + 7 post-registration screens (Home, Today's Workout, Logger, Muscle Rankings, Streak, Weight Tracker, Profile) render on iPhone SE → Pro Max and Android 360dp → 480dp with no clipping
- [ ] Paywall reachable from ≥4 triggers listed in §13
- [ ] Push notifications fire at correct local times across DST changes

**Offline-first (v1.2 — blocking for MVP release)**
- [ ] **Airplane-mode smoke test:** install fresh, enable airplane mode, complete onboarding, log a full workout, complete a daily quest, hit a streak milestone, edit profile, export data. Every step succeeds; no network error is ever shown.
- [ ] Cold launch on airplane mode completes in ≤2s and reaches Home without any spinner attributable to network.
- [ ] Every user-visible write hits SQLite synchronously before the UI advances to the next state. Verified by an instrumentation test that kills the process after each `completeSet()` and re-launches — the set is always persisted.
- [ ] Onboarding state persists across app kills (written to SQLite as each section completes) and survives backgrounding.
- [ ] Workout logger saves offline and remains queryable offline; the Home "total workouts" count reflects the save within 500ms.
- [ ] XP and rank update within 2s of set save (all computation on-device).
- [ ] Activity calendar on the Streak screen populates from SQLite only — zero network calls in the flow.
- [ ] "Export Data" produces a valid SQLite file + a human-readable CSV; both openable on desktop.
- [ ] "Delete my data" wipes all SQLite rows + the SQLCipher key and returns the app to first-launch state.
- [ ] 30-day migration round-trip test passes for every schema version in CI.
- [ ] Paywall: with entitlement cached, Pro features remain unlocked for the full `renews_at` window even with permanently disabled network.

**Reliability & security**
- [ ] SQLCipher encryption ON by default; verified by opening `gym_levels.db` with a raw SQLite browser — must be unreadable.
- [ ] Crash-free sessions ≥ 99.5% in the last 7 days of beta
- [ ] Store listings (screenshots, preview video) approved in both stores
- [ ] No user data ever leaves the device in v1.0 except (a) anonymised analytics with an `install_id` only and (b) store-billing receipts. A network-interception test confirms this.

---

## 20. Appendix A — Exercise catalog seed (v1)

Seed 80 exercises across: Chest (12), Back (12), Shoulders (8), Biceps (6), Triceps (6), Core (8), Quads (10), Hamstrings (6), Glutes (6), Calves (6). Each row: `name`, `primary_muscle`, `secondary_muscles[]`, `equipment`, `base_xp`, `demo_video_url`, `cue_text`.

## Appendix B — Plan generation (v1 pseudocode)

```
input: profile, goals, experience, schedule
  days_per_week = len(schedule.days)
  split = pick_split(days_per_week, goals.priority_muscles)
     // 2d → full-body, 3d → push/pull/legs, 4d → upper/lower×2, 5-6d → bro-split or PPLUL
  respect experience.limitations (swap exercises)
  respect experience.equipment (filter catalog)
  volume_multiplier = { beginner: 0.8, starting: 1.0, some: 1.1, experienced: 1.2 }[tenure]
  for each session:
    pick 1-2 compounds + 3-4 accessories targeting day's muscle focus
    prescribe sets×reps by goal.body_type (hypertrophy, strength, endurance mix)
  return weekly_plan
```

Regenerates on goal/equipment/schedule edits.

---

**End of document.**
