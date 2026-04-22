# LEVEL UP IRL — Design System
### v1.0 — Mobile-first (iOS + Android via React Native / Expo)
**Last updated:** 2026-04-20
**Companion doc:** [PRD_GamifiedFitnessApp.md](PRD_GamifiedFitnessApp.md)

---

## 0. Philosophy

Three rules govern every decision in this system:

1. **The UI is the game.** No "gamified mode" switch — every surface uses neon, rank badges, System voice.
2. **Glow with restraint.** One glow source per card, never two borders fighting. Glow is an accent, not a texture.
3. **Legibility over lore.** If a user can't read a number in 3 seconds from arm's length, strip the effect.

---

## 1. Design Tokens

Tokens are the atomic values. **Never hand-code a hex or a px** outside this layer.

### 1.1 Color — base palette

```ts
export const palette = {
  // Backgrounds
  obsidian:   '#05090C',   // onboarding base
  void:       '#0A0612',   // in-app base (violet-black)
  carbon:     '#0C131A',   // cards, elevated surfaces
  slate:      '#111923',   // inputs, inactive chips

  // Accents (section themes)
  teal:       '#19E3E3',
  teal_dim:   '#0F7A7A',
  purple:     '#8B5CF6',
  purple_dim: '#4C2D99',
  yellow:     '#F5D742',
  yellow_dim: '#8A7614',
  green:      '#22E06B',
  green_dim:  '#126B34',
  white:      '#E6EEF5',

  // Signal
  xp_gold:    '#F5A623',   // level, XP pills
  flame:      '#FF6B35',   // streak, warnings
  success:    '#22E06B',
  danger:     '#E04444',

  // Text
  text_primary:   '#E6EEF5',
  text_secondary: '#9BA8B4',
  text_muted:     '#6B7785',
  text_disabled:  '#3A4450',

  // Strokes
  stroke_hairline: 'rgba(230, 238, 245, 0.08)',
  stroke_subtle:   'rgba(230, 238, 245, 0.14)',
}
```

### 1.2 Color — semantic tokens (use these in code)

```ts
export const tokens = {
  // Surfaces
  bg:            palette.void,       // in-app
  bg_onboarding: palette.obsidian,
  surface:       palette.carbon,
  surface_alt:   palette.slate,

  // Text
  fg:         palette.text_primary,
  fg_muted:   palette.text_secondary,
  fg_subtle:  palette.text_muted,
  fg_disabled:palette.text_disabled,

  // Brand / gamification
  level:   palette.xp_gold,
  xp:      palette.xp_gold,
  streak:  palette.flame,
  rank:    palette.xp_gold,

  // Actions
  cta:          palette.teal,
  cta_pressed:  palette.teal_dim,
  link:         palette.teal,

  // Per-section (onboarding)
  section_registration:  palette.teal,
  section_objectives:    palette.purple,
  section_experience:    palette.yellow,
  section_attributes:    palette.teal,
  section_operations:    palette.green,
  section_settings:      palette.white,

  // Status
  success: palette.success,
  danger:  palette.danger,
}
```

### 1.3 Glow tokens

A "glow" is a box-shadow + border combo. We never use raw `shadowColor`.

```ts
export const glow = {
  none:   { shadow: 'none', border: tokens.stroke_subtle },
  teal:   { shadow: '0 0 16px rgba(25, 227, 227, 0.45)',  border: palette.teal },
  purple: { shadow: '0 0 16px rgba(139, 92, 246, 0.45)', border: palette.purple },
  yellow: { shadow: '0 0 16px rgba(245, 215, 66, 0.45)', border: palette.yellow },
  green:  { shadow: '0 0 16px rgba(34, 224, 107, 0.45)', border: palette.green },
  xp:     { shadow: '0 0 20px rgba(245, 166, 35, 0.55)',  border: palette.xp_gold },
  flame:  { shadow: '0 0 20px rgba(255, 107, 53, 0.55)',  border: palette.flame },
}
```

React Native note: on iOS use `shadowColor/Offset/Opacity/Radius`, on Android use `elevation` + a colored absolute `View` underlay. We abstract this in `<Glow color="…" />`.

### 1.4 Typography

Three typefaces. Don't add a fourth.

| Role | Family | Weights | Use |
|---|---|---|---|
| **Display** | Rajdhani | 500, 600, 700 | Hero titles, screen headings, "System" copy |
| **Body** | Inter | 400, 500, 600 | All running text, labels, descriptions |
| **Mono** | JetBrains Mono | 400, 500 | Numbers, percentages, XP, timers |

**Scale** (type is scaled against a 16-base with 1.2 modular ratio):

```ts
export const type = {
  displayXL: { family: 'Rajdhani', weight: 700, size: 40, line: 44, tracking: -0.5, uppercase: true },
  displayLG: { family: 'Rajdhani', weight: 700, size: 32, line: 36, tracking: -0.25, uppercase: true },
  displayMD: { family: 'Rajdhani', weight: 600, size: 24, line: 28, tracking: 0.5,  uppercase: true },
  displaySM: { family: 'Rajdhani', weight: 600, size: 18, line: 22, tracking: 1.5,  uppercase: true },

  bodyLG:  { family: 'Inter', weight: 500, size: 17, line: 24 },
  bodyMD:  { family: 'Inter', weight: 400, size: 15, line: 22 },
  bodySM:  { family: 'Inter', weight: 400, size: 13, line: 18 },
  label:   { family: 'Inter', weight: 600, size: 12, line: 16, tracking: 0.8, uppercase: true },

  monoXL:  { family: 'JetBrainsMono', weight: 500, size: 48, line: 52 },   // big number readouts
  monoLG:  { family: 'JetBrainsMono', weight: 500, size: 24, line: 28 },
  monoMD:  { family: 'JetBrainsMono', weight: 500, size: 15, line: 20 },

  system:  { family: 'Rajdhani', weight: 500, size: 13, line: 18, italic: true, color: 'fg_muted' },
}
```

**"System voice" rule:** all ambient subtitles under titles ("*Scanning biological data…*") use `type.system`, always italic, always fg_muted, always prefixed with an ellipsis if incomplete.

### 1.5 Spacing

8-pt grid. Half steps for tight UI (chips, strokes). **No 5px, no 7px, no "eyeball" values.**

```ts
export const space = {
  0: 0, 1: 2, 2: 4, 3: 8, 4: 12, 5: 16, 6: 20, 7: 24, 8: 32, 9: 40, 10: 48, 11: 56, 12: 64, 14: 80, 16: 96,
}
// Usage: padding: space[5]   // 16
```

### 1.6 Radius

```ts
export const radius = {
  sm: 6,    // chips, small tags
  md: 10,   // inputs, buttons
  lg: 16,   // cards
  xl: 24,   // hero cards, paywall
  pill: 999,
}
```

### 1.7 Elevation / Z

```ts
export const z = {
  base: 0,
  card: 1,
  sticky: 10,
  nav: 20,
  sheet: 30,
  modal: 40,
  toast: 50,
}
```

### 1.8 Motion

```ts
export const motion = {
  // Duration
  instant: 120,
  quick:   200,
  normal:  320,
  slow:    480,
  glacial: 800,

  // Easings (cubic-bezier)
  easeOut:    [0.2, 0.8, 0.2, 1],
  easeInOut:  [0.6, 0.0, 0.2, 1],
  spring:     { stiffness: 220, damping: 22, mass: 1 }, // Reanimated
  bounce:     { stiffness: 300, damping: 14, mass: 1 },

  // Signature animations
  glow_pulse:   { duration: 2000, easing: 'easeInOut', loop: true }, // 0.6 → 1.0 opacity
  bar_fill:     { duration: 400,  easing: 'easeOut' },
  xp_toast:     { duration: 900,  easing: 'easeOut' },  // rise 40px, fade
  shimmer:      { duration: 1400, easing: 'linear', loop: true },
  haptic_tap:   'ImpactFeedbackStyle.Light',
  haptic_level: 'NotificationFeedbackType.Success',
}
```

**Motion-reduction:** when `prefers-reduced-motion` is on, glow_pulse → static 0.8 opacity, bar_fill → duration 0, xp_toast → fade-only (no rise), shimmer → off.

### 1.9 Breakpoints / devices

The app is mobile-only at launch. Support range:

| Device class | Width (dp) | Tested |
|---|---|---|
| Small | 360 | iPhone SE, Galaxy S8 |
| Medium | 390 | iPhone 14 / 15 |
| Large | 430 | iPhone Pro Max |
| Android narrow | 360–412 | Pixel, OnePlus |

Layout breaks are rare — we use flex and relative sizing, not media queries.

---

## 2. Iconography

**Library:** Phosphor Icons (Regular + Bold variants). Consistent stroke weight, maps well to the neon aesthetic.

**Sizes:** 16, 20, 24, 32. Never 18 or 22.

**Custom icons** (SVG sprites in `assets/icons/game/`):
- `rank-bronze`, `rank-silver`, `rank-gold`, `rank-platinum`, `rank-diamond`, `rank-master`, `rank-grandmaster`
- `flame-streak`, `xp-orb`, `quest-daily`, `quest-weekly`, `quest-boss`
- `muscle-chest`, `muscle-back`, `muscle-shoulders`, `muscle-biceps`, `muscle-triceps`, `muscle-core`, `muscle-quads`, `muscle-hamstrings`, `muscle-glutes`, `muscle-calves`
- `class-mass-builder`, `class-shadow-athlete`, `class-iron-warrior`, `class-balanced-monk`, `class-rookie-hunter`

All custom icons support a `glow` prop that applies a matching colored outer glow.

---

## 3. Components

Each component has: **purpose**, **props**, **states**, **visual spec**, **do/don't**.

### 3.1 `<NeonCard />`

The atomic container. 95% of content lives inside one.

```tsx
type Props = {
  glow?: 'teal'|'purple'|'yellow'|'green'|'xp'|'flame'|'none'
  padding?: keyof typeof space        // default space[5]
  children: ReactNode
  onPress?: () => void
}
```

**Spec**
- Background: `tokens.surface`
- Border: 1px solid (color from `glow[prop].border`), `radius.lg`
- Shadow: `glow[prop].shadow` (iOS) / `elevation 4` + colored underlay (Android)
- Pulse animation: opacity 0.6 → 1.0 on 2s loop (paused if `onPress` unset and user preference is reduced motion)
- On press: scale 0.98, haptic `light`

**Don't**
- Nest two NeonCards with glows — pick one.
- Use a glow color that doesn't match the screen's section theme.

### 3.2 `<PrimaryButton />` / `<SecondaryButton />`

```tsx
type Props = {
  label: string
  variant?: 'primary'|'secondary'|'ghost'|'destructive'
  size?: 'sm'|'md'|'lg'        // 40 / 48 / 56 height
  icon?: IconName
  iconPosition?: 'left'|'right'
  loading?: boolean
  disabled?: boolean
  onPress: () => void
}
```

**Variants**

| Variant | BG | Text | Border | Glow |
|---|---|---|---|---|
| primary | `tokens.cta` | `#05090C` | none | teal @ 0.4 |
| secondary | transparent | `tokens.fg` | 1px `fg_subtle` | none |
| ghost | transparent | `tokens.cta` | none | none |
| destructive | `tokens.danger` | `#fff` | none | red @ 0.3 |

**States**
- hover (tablet/web only): +5% brightness
- pressed: scale 0.97 + haptic light
- loading: replace label with 3-dot pulse, disable press
- disabled: 40% opacity, ignore press

**Min touch target:** 44×44 (iOS HIG). Always.

### 3.3 `<ProgressHeader />`

Used at the top of every onboarding screen and above major in-app flows.

```tsx
type Props = {
  section: SectionKey     // determines color
  label: string           // 'PLAYER REGISTRATION'
  percent: number         // 0–100
  subtitle?: string       // '*Scanning biological data…*'
}
```

**Spec**
- Label left (`type.displaySM`, section color)
- Percent right (`type.monoMD`, section color)
- 2px bar below, full width, filled with section color gradient (90deg, base → +15% lightness)
- Subtitle below in `type.system`
- Bar animates with `motion.bar_fill` on percent change

### 3.4 `<Chip />`

Single-select or multi-select pill.

```tsx
type Props = {
  label: string
  icon?: IconName
  selected?: boolean
  disabled?: boolean
  theme?: 'teal'|'purple'|'yellow'|'green'     // matches section
  onToggle: () => void
}
```

**Spec**
- Unselected: `surface_alt` bg, `fg_muted` text, 1px `stroke_subtle` border
- Selected: theme color bg @ 0.18 alpha, theme color text, 1px solid theme color + glow
- Height: 36, padding: 8×14, radius: `pill`

### 3.5 `<ChipGroup />`

Wraps `<Chip />` with group behavior.

```tsx
type Props = {
  options: { value: string; label: string; icon?: IconName }[]
  mode: 'single'|'multi'|'capped-multi'
  cap?: number            // only for capped-multi
  exclusive?: string[]    // e.g. 'None' deselects others
  value: string | string[]
  onChange: (v: string | string[]) => void
  theme?: SectionKey
}
```

### 3.6 `<SliderPicker />`

Numeric picker used for age, height, weight, bodyfat.

```tsx
type Props = {
  min: number
  max: number
  step?: number
  value: number
  unit?: string                       // 'kg', 'cm'
  unitToggle?: { options: string[]; value: string; onChange: (v: string) => void }
  bigLabel?: boolean                  // huge mono readout
  theme?: SectionKey
  onChange: (v: number) => void
}
```

**Spec**
- If `bigLabel`: 96pt mono readout above the slider, unit in `bodySM` muted next to it
- Slider track: 4px, `slate`, with theme-colored fill from min to current
- Thumb: 20×20 circle, theme color + glow, haptic tick on step boundary
- `unitToggle` renders a segmented `<Toggle />` above the readout

### 3.7 `<SegmentedToggle />`

```tsx
type Props = {
  options: { value: string; label: string }[]
  value: string
  onChange: (v: string) => void
  theme?: SectionKey
}
```

Height 40, `surface_alt` container, selected segment bg = theme color @ 0.2 + 1px glow border.

### 3.8 `<AvatarCard />`

Used in "Which body type" and "Body fat estimate" screens.

```tsx
type Props = {
  image: ImageSource
  title: string
  subtitle?: string
  selected?: boolean
  theme?: SectionKey
  onPress: () => void
}
```

2×2 grid friendly. Aspect 3:4. Selected: theme glow + amber checkmark overlay top-right.

### 3.9 `<LevelPill />` / `<XPPill />`

Dual-purpose header pills.

| Component | BG | Icon | Text color |
|---|---|---|---|
| LevelPill | `xp_gold` @ 0.18 + border `xp_gold` | bolt | `xp_gold` |
| XPPill | `purple` @ 0.18 + border `purple` | orb | `purple` |

Text uses `type.monoMD`. Height 28, radius `pill`, padding 4×10.

### 3.10 `<RankBadge />`

Displays Bronze I → Grandmaster.

```tsx
type Props = {
  rank: RankKey           // 'bronze', 'silver', …, 'grandmaster'
  subRank?: 'I'|'II'|'III'
  size?: 'sm'|'md'|'lg'   // 24 / 48 / 96
  animated?: boolean      // subtle rotation + glow pulse
}
```

Rank-specific gradient + icon (see `assets/icons/game/rank-*`). Lg size used on profile + ranks screens; md in per-muscle rows; sm in chips/notifications.

### 3.11 `<StreakFlame />`

```tsx
type Props = {
  count: number
  size?: 'sm'|'md'|'lg'
  frozen?: boolean        // shows snowflake overlay
}
```

Animated flame Lottie (Lg size). Number renders in `type.monoXL` on Lg, `monoMD` on Sm.

### 3.12 `<XPToast />`

Floating +XP indicator, rendered in a toast layer.

```tsx
type Props = { amount: number; source?: string }
```

Spec: rises 40px over 900ms while fading, mono amber text "+25 XP", sparkle particles.

### 3.13 `<CalibratingLoader />`

Section-to-section interstitial.

```tsx
type Props = { theme: SectionKey; durationMs?: number; onComplete: () => void }
```

Centered ANALYSIS label in a thin glowing box → "CALIBRATING SYSTEM" big → 2px bar that fills 0→100 → dots "SYS / NET / DB / GPU" that flip green in sequence. Defaults to 1200ms.

### 3.14 `<SystemTitle />`

Screen hero for the first slide of each section ("LEVEL UP IRL", "MUSCLE RANKS").

- 3 glowing dots upper left (`● ● ●`) + kicker label
- `type.displayLG` uppercase title
- Optional stats row (rank letters, +XP)
- Optional body + Continue CTA

### 3.15 `<TabBar />`

4-item bottom navigation.

```tsx
items: [
  { key: 'home',    icon: 'House',      label: 'Home' },
  { key: 'quests',  icon: 'Scroll',     label: 'Quests' },
  { key: 'streak',  icon: 'Flame',      label: 'Streak' },
  { key: 'profile', icon: 'Crown',      label: 'Profile' },
]
```

Height 72 + safe-area. Active: amber fill circle (28dp) behind icon + sparkle particle burst on change (Lottie, 400ms). Inactive: icon `fg_muted`.

### 3.16 `<SetCard />`

The core logger unit.

```tsx
type Props = {
  setNumber: number
  targetReps?: number
  targetWeight?: number       // kg
  isBodyweight?: boolean
  rpe?: number
  state: 'pending'|'active'|'completed'
  onComplete: (data: { weight: number; reps: number; rpe: number }) => void
}
```

**States**
- `pending`: dim, no glow, small height
- `active`: violet glow, large, shows steppers + COMPLETE SET button, `BODYWEIGHT` label pill if applicable
- `completed`: green outlined, checkmark, shows actual logged values + difficulty letter (D = easy, A = hard)

### 3.17 `<RestTimer />`

Sticky bar at bottom of logger when rest is active.

- Full-width, 48 tall, `carbon` bg
- Animated gradient sweep (teal → purple) left→right as timer progresses
- Big mono countdown centered
- Two ghost buttons: `-30s` | `Skip` | `+30s`
- Haptic `success` when timer hits 0

### 3.18 `<WeightChart />`

Trend line with game-y styling.

- Line: 2px stroke, teal→violet gradient
- Each data point: 4px circle with inner glow
- On hover/tap: tooltip card with weight + date
- X-axis: date ticks `fg_muted`
- 30D / 90D / 1Y toggle via `<SegmentedToggle />`

### 3.19 `<ActivityCalendar />`

Month grid for streak screen.

| Cell state | Visual |
|---|---|
| workout done | `xp_gold` filled square, 4px radius |
| scheduled rest | violet outline |
| missed | `carbon` (blank) |
| freeze used | snowflake icon overlay |
| today | pulsing teal ring |

Cell size 32, 4px gap. Header row M T W T F S S in `type.label`.

### 3.20 `<PlayerClassCard />`

Hero card on profile.

- 4:3 aspect
- Background: class artwork, darkened 40%
- Centered: class badge (circular, 96dp) + name (`type.displayMD`) + one-line description (`type.bodyMD`)
- Border: `xp_gold` glow
- On tap: opens bottom sheet with buffs/perks

### 3.21 `<QuestCard />`

```tsx
type Props = {
  title: string
  description: string
  type: 'daily'|'weekly'|'boss'
  progress: number        // 0–1
  xpReward: number
  expiresAt?: Date
  completed?: boolean
  locked?: boolean        // premium gate
}
```

**Variants**
- Daily: green accent, small
- Weekly: purple accent, medium
- Boss: red/orange accent, large with boss art background

Progress bar bottom, XP reward chip top-right, lock icon if `locked`.

### 3.22 `<SystemNotification />` (in-app banner)

Match push notification voice.

Format: `[System] {message}` in `type.bodyMD`, slides down from top over 240ms, auto-dismisses in 4s, dismissable on swipe.

### 3.23 Forms & input primitives

| Component | Purpose |
|---|---|
| `<TextField />` | name, notes — 48 tall, `surface_alt` bg, glow on focus |
| `<NumericStepper />` | weight / reps in logger — `-  123  +` layout |
| `<ToggleSwitch />` | notifications — teal track, amber thumb |
| `<Radio />` | single-select in objectives |
| `<Checkbox />` | internal only; user-facing use `<Chip multi/>` |

---

## 4. Screen templates

Every screen uses one of three templates. This keeps the system cohesive and onboarding predictable.

### 4.1 `<OnboardingTemplate />`

```
┌───────────────────────────────┐
│ ProgressHeader(section, %)    │
│ system subtitle               │
│                               │
│ ┌───────────────────────────┐ │
│ │ NeonCard (theme=section)  │ │
│ │  Title (displayLG)        │ │
│ │  {children}               │ │
│ └───────────────────────────┘ │
│                               │
│        (free space)           │
│                               │
│ BACK    CONTINUE              │
└───────────────────────────────┘
```

Back is always `secondary` at 40% width; Continue is `primary` at 60%. Continue disabled until step is valid.

### 4.2 `<HypeTemplate />`

Used for Muscle Ranks / Progression System / Challenge System slides.

```
┌───────────────────────────────┐
│                               │
│    [ Full-bleed key art ]     │
│                               │
│ ┌───────────────────────────┐ │
│ │ ● ● ●  KICKER             │ │
│ │ TITLE (displayXL)         │ │
│ │ stats row or tier row     │ │
│ │ supporting text           │ │
│ │                           │ │
│ │ [ CONTINUE ]              │ │
│ └───────────────────────────┘ │
└───────────────────────────────┘
```

Key art fills top ~55%, card sits in bottom 45%. Card has glow matching theme.

### 4.3 `<InAppTemplate />`

```
┌───────────────────────────────┐
│ ← Title                Action │
│                               │
│  {scrollable content}         │
│                               │
├───────────────────────────────┤
│  [Home] [Quests] [🔥] [👑]    │
└───────────────────────────────┘
```

Content area has standard `space[5]` horizontal padding. Sticky CTAs (Start Workout) sit above the tab bar with an 8px gradient fade.

---

## 5. Section themes

Onboarding sections use this theme table. Switching sections swaps the whole theme via context.

```ts
export const sectionThemes = {
  registration: {
    accent: palette.teal,
    glow: glow.teal,
    kicker: 'PLAYER REGISTRATION',
  },
  objectives: {
    accent: palette.purple,
    glow: glow.purple,
    kicker: 'MISSION OBJECTIVES',
  },
  experience: {
    accent: palette.yellow,
    glow: glow.yellow,
    kicker: 'COMBAT EXPERIENCE',
  },
  attributes: {
    accent: palette.teal,
    glow: glow.teal,
    kicker: 'PHYSICAL ATTRIBUTES',
  },
  operations: {
    accent: palette.green,
    glow: glow.green,
    kicker: 'DAILY OPERATIONS',
  },
  settings: {
    accent: palette.white,
    glow: glow.none,
    kicker: 'SYSTEM SETTINGS',
  },
}
```

In-app uses a single theme (`purple` accent + `xp_gold` highlights), defined in `tokens` above.

---

## 6. Patterns

### 6.1 "System voice" copy

All system-generated text follows these rules:

- Prefix push notifications with `[System]`.
- Use terse, diagnostic language: "Scanning biological data…", "Calibrating target mass…"
- Address user as `Player`, or by their display name.
- Errors read as system failures: "⚠ Signal lost. Retry?"

**Do:** "Streak at risk. Train in the next 3 hours."
**Don't:** "Hey 👋 don't forget to hit the gym today!"

### 6.2 Empty states

Every list/data surface must have an empty state styled as a terminal readout:

```
> no workouts logged
> awaiting first data packet…
[ LOG FIRST WORKOUT ]
```

Font: `type.mono`, color `fg_muted`, cursor blink optional.

### 6.3 Loading states

Three patterns:

1. **Calibrating loader** (`<CalibratingLoader />`) — use between major flow steps.
2. **Skeleton** — grey blocks with shimmer for list/content loading.
3. **Inline spinner** — three dots bouncing, for buttons and quick actions.

**Never** use a spinner when a skeleton will do.

### 6.4 Feedback

Every important action gets feedback through three channels:

| Channel | When |
|---|---|
| Visual | Always (state change, glow, toast) |
| Haptic | State transitions (set complete, level up, streak saved) |
| Audio | Off by default. Opt-in in settings for XP/level-up chimes. |

### 6.5 Error handling

All errors appear as a `<SystemNotification />` banner with `[System] ⚠` prefix + retry CTA. Never use raw alerts for non-destructive errors. Destructive errors (delete account, cancel subscription) use a full-screen confirm with the violet danger treatment.

---

## 7. Accessibility

**Targets**
- Minimum contrast 4.5:1 for body, 3:1 for display. Verified with Stark for every token pair.
- Minimum touch target 44×44.
- All color-coded status backed by an icon or label.
- Motion-reduction honored across glow pulses, shimmers, XP toast rises.

**Dynamic type**
- Support OS text-size preferences 85% → 135%.
- Display type caps at 135% (keeps layouts intact); body scales freely.

**Screen reader**
- Every `<NeonCard onPress>` must have `accessibilityLabel` + `accessibilityRole="button"`.
- Sliders announce current + unit ("Age, 23 years, slider, double tap to edit").
- Decorative glow layers `accessibilityElementsHidden={true}`.

---

## 8. Implementation (React Native / Expo)

### 8.1 Recommended stack

```
expo@latest
expo-router                      # file-based nav
react-native-reanimated@3
react-native-gesture-handler
react-native-svg
@shopify/restyle                 # token-based styling
lottie-react-native              # glow pulses, key art animations
expo-haptics                     # tap feedback
expo-font                        # load Rajdhani, Inter, JetBrains Mono
expo-linear-gradient             # progress bars, chart gradients
zustand                          # client state (onboarding draft, active session)
react-native-mmkv                # local cache
```

### 8.2 Restyle theme file

```ts
// theme/index.ts
import { createTheme } from '@shopify/restyle'
import { palette, tokens, glow, space, radius, type } from './tokens'

export const theme = createTheme({
  colors: { ...palette, ...tokens },
  spacing: space,
  borderRadii: radius,
  textVariants: type,
  cardVariants: {
    neon_teal:   { backgroundColor: 'surface', borderColor: 'teal',   borderWidth: 1, borderRadius: 'lg' },
    neon_purple: { backgroundColor: 'surface', borderColor: 'purple', borderWidth: 1, borderRadius: 'lg' },
    neon_yellow: { backgroundColor: 'surface', borderColor: 'yellow', borderWidth: 1, borderRadius: 'lg' },
    neon_green:  { backgroundColor: 'surface', borderColor: 'green',  borderWidth: 1, borderRadius: 'lg' },
  },
})
export type Theme = typeof theme
```

### 8.3 File/folder layout

```
design-system/
├── tokens/           # color, type, space, glow, motion — no components
├── primitives/       # Box, Text, Pressable wrappers from Restyle
├── components/       # NeonCard, Button, ProgressHeader, …
├── templates/        # OnboardingTemplate, HypeTemplate, InAppTemplate
├── themes/           # sectionThemes.ts, ThemeProvider.tsx
├── icons/            # Phosphor re-exports + custom SVGs
└── animations/       # Lottie JSON, Reanimated presets
```

### 8.4 Storybook

Every component ships with a Storybook story (`.stories.tsx`) showing all variants. CI blocks merges if a component lacks a story.

### 8.5 Naming conventions

- Components: `PascalCase.tsx`
- Tokens: `snake_case` keys
- Props: `camelCase`
- Colors: `semantic_role` (never `bluish_teal_2`)

---

## 9. Figma parity

If producing Figma alongside code:

1. Token file in Figma Variables matches `design-system/tokens/` 1:1.
2. Components use Auto Layout + variables (no detached styles).
3. A hand-off doc maps Figma component → code component:

| Figma | Code |
|---|---|
| `Card / Neon / Teal` | `<NeonCard glow="teal" />` |
| `Button / Primary / LG` | `<PrimaryButton size="lg" />` |
| `Slider / Big Label` | `<SliderPicker bigLabel />` |

4. Every screen in the PRD §8 & §9A has a matching Figma frame named `S{n} – {screen name}`.

---

## 10. Governance

**Adding a token:** PR must justify why an existing token can't be used. Any new color is reviewed against WCAG.

**Adding a component:** needs (a) a real screen that uses it, (b) a story, (c) a dark-mode test (all in-app screens are dark today; a light mode is not planned).

**Deprecating:** mark in `@deprecated` JSDoc for one release cycle before removal.

**Release cadence:** design system versioned independently. Minor for new components, major for breaking token changes.

---

## 11. Quick-reference cheatsheet

| Need | Use |
|---|---|
| A card with a glow | `<NeonCard glow="teal">` |
| A "continue" button | `<PrimaryButton label="CONTINUE" size="lg" />` |
| Title over a screen | `<ProgressHeader section="registration" label="…" percent={25} />` |
| Pick 1 of N | `<ChipGroup mode="single" />` or `<RadioGroup />` |
| Pick up to K | `<ChipGroup mode="capped-multi" cap={3} />` |
| A number with a slider | `<SliderPicker bigLabel />` |
| Between flow steps | `<CalibratingLoader theme="registration" />` |
| Floating +XP feedback | `showXPToast(25)` |
| Section heading (hype) | `<SystemTitle />` inside `<HypeTemplate />` |
| In-app screen frame | `<InAppTemplate title="Home">` |

---

**End of document.**
