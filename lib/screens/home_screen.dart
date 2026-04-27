import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/quest.dart' as model;
import '../data/models/workout.dart';
import '../data/services/analytics_service.dart';
import '../data/services/player_service.dart';
import '../data/services/quest_service.dart';
import '../data/services/workout_service.dart';
import '../game/plan_generator.dart';
import '../game/quest_engine.dart';
import '../state/onboarding_flag.dart';
import '../state/player_state.dart';
import '../theme/tokens.dart';
import '../widgets/in_app_shell.dart';
import '../widgets/neon_card.dart';
import '../widgets/pills.dart';
import '../widgets/progress_bar.dart';
import '../widgets/tab_bar.dart';

/// Home screen — matches design v2 (`design/v2/screens-home.jsx`).
///
/// Layout (top → bottom):
///   1. Top bar — greeting + name + class line + avatar slot
///   2. Level + Total XP strip — two side-by-side mini cards
///   3. XP progress bar with shimmer
///   4. Total Workouts + Streak row
///   5. Next Workout card (clickable, opens Today's Workout)
///   6. Today's Quest card
///   7. START WORKOUT teal CTA
///
/// Floating glass tab bar lives at the bottom, layered by [InAppShell].
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<model.Quest>> _dailyQuests;
  late Future<int> _totalWorkouts;
  late Future<_HomeSession> _session;

  @override
  void initState() {
    super.initState();
    _dailyQuests = _loadDailyQuests();
    _totalWorkouts = WorkoutService.totalFinished();
    _session = _loadSession();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeCompleteOnboarding());
  }

  Future<List<model.Quest>> _loadDailyQuests() async {
    // Daily rotation runs every Home mount; weekly + boss are also
    // refreshed here so a user landing on Home Monday morning gets a
    // fresh weekly batch and any never-seeded boss rows show up.
    await QuestEngine.rotateDailyIfNeeded();
    await QuestEngine.rotateWeeklyIfNeeded();
    await QuestEngine.seedBossesIfNeeded();
    return QuestService.issuedSince('daily', QuestEngine.todayEpoch());
  }

  Future<_HomeSession> _loadSession() async {
    final results = await Future.wait([
      PlanGenerator.todaysSession(),
      WorkoutService.finishedToday(),
    ]);
    return _HomeSession(
      plan: results[0] as SessionPlan?,
      doneToday: results[1] as Workout?,
    );
  }

  Future<void> _maybeCompleteOnboarding() async {
    if (!mounted) return;
    final state = context.read<PlayerState>();
    if (state.player == null) {
      await state.refresh();
    }
    if (!mounted) return;
    final already = state.player?.isOnboarded ?? false;
    if (already) return;

    await PlayerService.completeOnboarding();
    await AnalyticsService.log('onboarding_completed', {
      'source': 'home_first_render',
    });
    isOnboardedNotifier.value = true;
    if (!mounted) return;
    await state.refresh();
  }

  void _startWorkout() {
    context.go('/exercise-picker');
  }

  void _openTodaysWorkout() {
    context.go('/home/todays-workout');
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<PlayerState>();
    // The floating tab bar sits 24px above the home indicator. Reserve
    // tabBarSafeBottom + safe-area bottom inset on the ListView so the
    // last item (START WORKOUT) clears the bar instead of being clipped
    // behind it.
    final safeBottom = MediaQuery.of(context).padding.bottom;
    return InAppShell(
      active: AppTab.home,
      title: 'HOME',
      showHeader: false,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          0,
          0,
          0,
          InAppShell.tabBarSafeBottom + safeBottom,
        ),
        children: [
          _TopBar(
            name: s.playerName,
            className: s.playerClass.displayName,
            onAvatar: () => context.go('/profile'),
          ),
          _LevelXpStrip(level: s.level, totalXp: s.totalXp),
          _XpProgressBlock(
            level: s.level,
            xpInto: s.xpCurrent,
            xpMax: s.xpMax,
          ),
          _StatRow(
            totalWorkoutsFuture: _totalWorkouts,
            streak: s.streak,
            onStreakTap: () => context.go('/streak'),
          ),
          _NextWorkoutBlock(
            future: _session,
            onTap: _openTodaysWorkout,
          ),
          _TodaysQuestBlock(future: _dailyQuests),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: _StartWorkoutButton(onTap: _startWorkout),
          ),
        ],
      ),
    );
  }
}

class _HomeSession {
  const _HomeSession({required this.plan, required this.doneToday});
  final SessionPlan? plan;
  final Workout? doneToday;
}

// ─── Top bar (greeting + name + class + avatar) ────────────
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.name,
    required this.className,
    required this.onAvatar,
  });
  final String name;
  final String className;
  final VoidCallback onAvatar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppPalette.textMuted,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      _displayName(name),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text('🔥', style: TextStyle(fontSize: 22)),
                  ],
                ),
                const SizedBox(height: 6),
                ShaderMask(
                  shaderCallback: (rect) => const LinearGradient(
                    colors: [AppPalette.amber, AppPalette.amberSoft],
                  ).createShader(rect),
                  child: Text(
                    'CLASS • $className',
                    style: AppType.displaySM(color: Colors.white).copyWith(
                      fontSize: 14,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onAvatar,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const _HeroAvatar(size: 48),
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppPalette.amber,
                      border: Border.all(color: AppPalette.voidBg, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _displayName(String raw) {
    if (raw.isEmpty) return 'Player';
    return raw[0].toUpperCase() + raw.substring(1);
  }
}

/// Stylized character avatar — circular gradient disc with a violet ring,
/// outer glow, and a simple painted face inside. Approximates the design v2
/// `HeroAvatar` SVG (`design/v2/screens-home.jsx`).
class _HeroAvatar extends StatelessWidget {
  const _HeroAvatar({this.size = 48});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D1B4E), Color(0xFF1A0F2B)],
        ),
        border: Border.all(
          color: AppPalette.purple.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppPalette.purple.withValues(alpha: 0.3),
            blurRadius: 16,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/hero-bust.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

// ─── Level + Total XP strip ────────────────────────────────
class _LevelXpStrip extends StatelessWidget {
  const _LevelXpStrip({required this.level, required this.totalXp});
  final int level;
  final int totalXp;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      // Design v2 widths: Level flex 1, Total XP flex 1.3. Flutter's flex is
      // int-only, so use 10:13 to preserve the same proportions.
      child: Row(
        children: [
          Expanded(
            flex: 10,
            child: _StripCard(
              icon: Icons.star,
              iconColor: AppPalette.amber,
              kicker: 'LEVEL',
              value: 'LV $level',
              valueColor: AppPalette.amber,
              tint: AppPalette.amber,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 13,
            child: _StripCard(
              icon: Icons.bolt,
              iconColor: AppPalette.purpleSoft,
              kicker: 'TOTAL XP',
              value: _format(totalXp),
              valueColor: AppPalette.purpleSoft,
              tint: AppPalette.purple,
            ),
          ),
        ],
      ),
    );
  }

  static String _format(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final fromEnd = s.length - i;
      buf.write(s[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }
}

class _StripCard extends StatelessWidget {
  const _StripCard({
    required this.icon,
    required this.iconColor,
    required this.kicker,
    required this.value,
    required this.valueColor,
    required this.tint,
  });

  final IconData icon;
  final Color iconColor;
  final String kicker;
  final String value;
  final Color valueColor;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tint.withValues(alpha: 0.20),
            tint.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tint.withValues(alpha: 0.40),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  kicker,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: AppPalette.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: AppType.displayMD(color: valueColor)
                        .copyWith(fontSize: 22, height: 1),
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── XP progress block ─────────────────────────────────────
class _XpProgressBlock extends StatelessWidget {
  const _XpProgressBlock({
    required this.level,
    required this.xpInto,
    required this.xpMax,
  });

  final int level;
  final int xpInto;
  final int xpMax;

  @override
  Widget build(BuildContext context) {
    final pct = xpMax == 0 ? 0.0 : (xpInto / xpMax * 100).clamp(0, 100);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress to Level ${level + 1}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppPalette.textMuted,
                ),
              ),
              Text(
                '${pct.round()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.amber,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          XpBar(percent: pct.toDouble(), height: 10),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$xpInto XP',
                style: TextStyle(
                  fontSize: 10,
                  color: AppPalette.textDim,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                '$xpMax XP',
                style: TextStyle(
                  fontSize: 10,
                  color: AppPalette.textDim,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Total + Streak row ────────────────────────────────────
class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.totalWorkoutsFuture,
    required this.streak,
    required this.onStreakTap,
  });

  final Future<int> totalWorkoutsFuture;
  final int streak;
  final VoidCallback onStreakTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: FutureBuilder<int>(
              future: totalWorkoutsFuture,
              builder: (ctx, snap) => _StatTile(
                kicker: 'TOTAL',
                value: '${snap.data ?? 0}',
                caption: 'Workouts',
                icon: Icons.fitness_center,
                accent: AppPalette.purpleSoft,
                valueColor: AppPalette.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatTile(
              kicker: 'STREAK',
              value: '$streak',
              caption: streak > 0 ? 'On fire!' : 'Start today',
              captionColor: AppPalette.streak,
              captionItalic: true,
              icon: Icons.local_fire_department,
              accent: AppPalette.streak,
              valueColor: AppPalette.streak,
              valueGlow: true,
              animateIcon: streak > 0,
              onTap: onStreakTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatefulWidget {
  const _StatTile({
    required this.kicker,
    required this.value,
    required this.caption,
    required this.icon,
    required this.accent,
    required this.valueColor,
    this.captionColor,
    this.captionItalic = false,
    this.valueGlow = false,
    this.animateIcon = false,
    this.onTap,
  });

  final String kicker;
  final String value;
  final String caption;
  final IconData icon;
  final Color accent;
  final Color valueColor;
  final Color? captionColor;
  final bool captionItalic;
  final bool valueGlow;
  final bool animateIcon;
  final VoidCallback? onTap;

  @override
  State<_StatTile> createState() => _StatTileState();
}

class _StatTileState extends State<_StatTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    if (widget.animateIcon) _ctl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      padding: const EdgeInsets.all(14),
      glow: GlowColor.purple,
      pulse: false,
      onTap: widget.onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.kicker,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: AppPalette.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.value,
                  style: AppType.displayLG(color: widget.valueColor).copyWith(
                    fontSize: 34,
                    height: 1,
                    shadows: widget.valueGlow
                        ? [
                            Shadow(
                              color: widget.accent.withValues(alpha: 0.6),
                              blurRadius: 12,
                            ),
                          ]
                        : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.caption,
                  style: TextStyle(
                    fontSize: 11,
                    color: widget.captionColor ?? AppPalette.textMuted,
                    fontStyle: widget.captionItalic
                        ? FontStyle.italic
                        : FontStyle.normal,
                    fontWeight: widget.captionItalic
                        ? FontWeight.w500
                        : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _ctl,
            builder: (context, _) {
              final glow = widget.animateIcon
                  ? 6 + _ctl.value * 8
                  : 6.0;
              return Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: widget.accent.withValues(alpha: 0.15),
                ),
                child: Icon(
                  widget.icon,
                  size: 22,
                  color: widget.accent,
                  shadows: widget.animateIcon
                      ? [
                          Shadow(
                            color: widget.accent.withValues(
                              alpha: 0.5 + _ctl.value * 0.4,
                            ),
                            blurRadius: glow.toDouble(),
                          ),
                        ]
                      : null,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Next Workout block (real plan + done-today + no-schedule states) ─
class _NextWorkoutBlock extends StatelessWidget {
  const _NextWorkoutBlock({required this.future, required this.onTap});
  final Future<_HomeSession> future;
  final VoidCallback onTap;

  /// Maps the focus label back to a muscle-grouping category for the
  /// subtitle line on the Next Workout card. Matches the design's
  /// `USER.nextWorkout.category` field.
  static String _categoryFor(String focus) {
    final f = focus.toLowerCase();
    if (f.contains('push') || f.contains('pull') || f.contains('upper')) {
      return 'Upper Body';
    }
    if (f.contains('leg') || f.contains('lower')) return 'Lower Body';
    if (f.contains('full')) return 'Full Body';
    return 'Mixed';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'NEXT WORKOUT',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: AppPalette.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          FutureBuilder<_HomeSession>(
            future: future,
            builder: (ctx, snap) {
              final data = snap.data;
              final plan = data?.plan;
              final done = data?.doneToday;
              final settled = snap.connectionState == ConnectionState.done;

              if (!settled) {
                return _NextWorkoutCard(
                  title: 'LOADING…',
                  subtitle: '…calibrating your session',
                  pills: const [],
                  iconAccent: AppPalette.purpleSoft,
                  onTap: null,
                );
              }
              if (done != null) {
                return _NextWorkoutCard(
                  title: (plan?.focus ?? 'COMPLETED'),
                  subtitle:
                      'Done today · +${done.xpEarned} XP · ${done.volumeKg.round()}kg',
                  pills: const [],
                  iconAccent: AppPalette.success,
                  iconData: Icons.check_circle,
                  onTap: () => GoRouter.of(context).go('/workouts/${done.id}'),
                  glow: GlowColor.green,
                );
              }
              if (plan == null) {
                return _NextWorkoutCard(
                  title: 'PICK TRAINING DAYS',
                  subtitle: 'Tap to set your weekly schedule.',
                  pills: const [],
                  iconAccent: AppPalette.teal,
                  iconData: Icons.event_outlined,
                  onTap: () => GoRouter.of(context).go('/training-days'),
                  glow: GlowColor.teal,
                );
              }
              if (plan.exercises.isEmpty) {
                return _NextWorkoutCard(
                  title: plan.focus,
                  subtitle: 'No matching exercises — tap to add equipment.',
                  pills: const [],
                  iconAccent: AppPalette.teal,
                  iconData: Icons.tune,
                  onTap: () => GoRouter.of(context).go('/equipment'),
                  glow: GlowColor.teal,
                );
              }
              final muscleSet = <String>{};
              for (final e in plan.exercises) {
                final lower = e.name.toLowerCase();
                if (lower.contains('press') || lower.contains('bench') || lower.contains('push')) {
                  muscleSet.add('Chest');
                }
                if (lower.contains('shoulder') || lower.contains('lateral') || lower.contains('overhead')) {
                  muscleSet.add('Shoulders');
                }
                if (lower.contains('tricep') || lower.contains('dip')) {
                  muscleSet.add('Triceps');
                }
                if (lower.contains('row') || lower.contains('pull')) {
                  muscleSet.add('Back');
                }
                if (lower.contains('curl') && !lower.contains('nordic')) {
                  muscleSet.add('Biceps');
                }
                if (lower.contains('squat') || lower.contains('lunge')) {
                  muscleSet.add('Legs');
                }
                if (lower.contains('glute') || lower.contains('bridge')) {
                  muscleSet.add('Glutes');
                }
              }
              final pills = muscleSet.take(3).toList();

              return _NextWorkoutCard(
                title: plan.focus,
                subtitle:
                    '${_categoryFor(plan.focus)} · ~${plan.estimatedMinutes} min · ${plan.exercises.length} exercises',
                pills: pills,
                iconAccent: AppPalette.purpleSoft,
                onTap: onTap,
                glow: plan.isScheduled ? GlowColor.purple : GlowColor.teal,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NextWorkoutCard extends StatelessWidget {
  const _NextWorkoutCard({
    required this.title,
    required this.subtitle,
    required this.pills,
    required this.iconAccent,
    this.iconData = Icons.fitness_center,
    this.onTap,
    this.glow = GlowColor.purple,
  });

  final String title;
  final String subtitle;
  final List<String> pills;
  final Color iconAccent;
  final IconData iconData;
  final VoidCallback? onTap;
  final GlowColor glow;

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      glow: glow,
      pulse: false,
      padding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      onTap: onTap,
      // IntrinsicHeight makes the Row size to the tallest child's natural
      // height so the violet icon column on the left can stretch alongside
      // the text column on the right (the CSS prototype gets this for free
      // via flex's `align-items: stretch`).
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 80,
              decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  iconAccent.withValues(alpha: 0.30),
                  iconAccent.withValues(alpha: 0.10),
                ],
              ),
              border: Border(
                right: BorderSide(
                  color: iconAccent.withValues(alpha: 0.20),
                  width: 1,
                ),
              ),
            ),
            child: Center(
              child: Icon(iconData, size: 36, color: iconAccent),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppType.displayMD(color: AppPalette.textPrimary)
                        .copyWith(fontSize: 22, height: 1),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppPalette.textMuted,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (pills.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final p in pills)
                          AppPill(label: p, dense: true),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Icon(
              Icons.chevron_right,
              color: AppPalette.textMuted,
              size: 20,
            ),
          ),
        ],
      ),
      ),
    );
  }
}

// ─── Today's Quest block ───────────────────────────────────
class _TodaysQuestBlock extends StatelessWidget {
  const _TodaysQuestBlock({required this.future});
  final Future<List<model.Quest>> future;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "TODAY'S QUEST",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: AppPalette.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<model.Quest>>(
            future: future,
            builder: (ctx, snap) {
              final quests = snap.data ?? const <model.Quest>[];
              if (quests.isEmpty) {
                return _QuestCard(
                  title: 'Rotating today\'s quests…',
                  progress: 0,
                  subtitle: '',
                  reward: 0,
                  done: false,
                );
              }
              // Show the first not-yet-completed quest; if all done, show
              // the first completed one stamped DONE.
              final pending = quests.firstWhere(
                (q) => !q.isCompleted,
                orElse: () => quests.first,
              );
              final p = pending.target == 0
                  ? 0.0
                  : pending.progress / pending.target;
              return _QuestCard(
                title: pending.title,
                progress: pending.isCompleted ? 1.0 : p.clamp(0.0, 1.0),
                subtitle:
                    'Progress: ${pending.progress} / ${pending.target}',
                reward: pending.xpReward,
                done: pending.isCompleted,
                onTap: () => GoRouter.of(context).go('/quests'),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _QuestCard extends StatelessWidget {
  const _QuestCard({
    required this.title,
    required this.progress,
    required this.subtitle,
    required this.reward,
    required this.done,
    this.onTap,
  });

  final String title;
  final double progress;
  final String subtitle;
  final int reward;
  final bool done;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = done ? AppPalette.success : AppPalette.amber;
    return NeonCard(
      padding: const EdgeInsets.all(14),
      glow: GlowColor.purple,
      pulse: false,
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: accent.withValues(alpha: 0.15),
              border: Border.all(
                color: accent.withValues(alpha: 0.30),
                width: 1,
              ),
            ),
            child: Icon(
              done ? Icons.check : Icons.gps_fixed,
              size: 20,
              color: accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppPalette.textPrimary,
                    decoration:
                        done ? TextDecoration.lineThrough : TextDecoration.none,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppPalette.textMuted,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: SizedBox(
                    height: 4,
                    child: Stack(
                      children: [
                        Container(
                          color: accent.withValues(alpha: 0.15),
                        ),
                        FractionallySizedBox(
                          widthFactor: progress.clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: accent,
                              boxShadow: [
                                BoxShadow(color: accent, blurRadius: 6),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '+$reward XP',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: accent,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Start Workout teal CTA ────────────────────────────────
class _StartWorkoutButton extends StatelessWidget {
  const _StartWorkoutButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 58,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF19E3E3), Color(0xFF0EC6C6)],
            ),
            boxShadow: [
              BoxShadow(
                color: AppPalette.teal.withValues(alpha: 0.30),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.play_arrow,
                size: 18,
                color: AppPalette.voidBg,
              ),
              const SizedBox(width: 10),
              Text(
                'START WORKOUT',
                style: AppType.displaySM(color: AppPalette.voidBg).copyWith(
                  fontSize: 16,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
