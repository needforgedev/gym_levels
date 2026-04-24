import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/muscle_rank.dart';
import '../data/models/quest.dart' as model;
import '../data/services/analytics_service.dart';
import '../data/services/muscle_rank_service.dart';
import '../data/services/player_service.dart';
import '../data/models/workout.dart';
import '../data/services/quest_service.dart';
import '../data/services/workout_service.dart';
import '../game/plan_generator.dart';
import '../game/quest_engine.dart';
import '../game/rank_engine.dart';
import '../state/onboarding_flag.dart';
import '../state/player_state.dart';
import '../theme/tokens.dart';
import '../widgets/buttons.dart';
import '../widgets/in_app_shell.dart';
import '../widgets/muscle_figure.dart';
import '../widgets/neon_card.dart';
import '../widgets/pills.dart';
import '../widgets/quest_row.dart';
import '../widgets/rank_badge.dart';
import '../widgets/tab_bar.dart';
import '../widgets/xp_ring.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<model.Quest>> _dailyQuests;
  late Future<List<MuscleRank>> _muscleRanks;

  @override
  void initState() {
    super.initState();
    _dailyQuests = _loadDailyQuests();
    _muscleRanks = MuscleRankService.getAll();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeCompleteOnboarding());
  }

  /// Rotates the daily batch if none issued today, then returns today's
  /// full batch (completed ones included). Completed quests stay visible
  /// with a DONE state until tomorrow's rotation — matches the Quests tab.
  Future<List<model.Quest>> _loadDailyQuests() async {
    await QuestEngine.rotateDailyIfNeeded();
    return QuestService.issuedSince('daily', QuestEngine.todayEpoch());
  }

  /// Summary label for the muscle-ranks card — averages `rank_xp` across the
  /// tracked muscles and maps the result back to a tier name.
  String _overallLabel(List<MuscleRank> ranks) {
    if (ranks.isEmpty) return 'NO DATA YET';
    final avg =
        (ranks.fold<int>(0, (a, r) => a + r.rankXp) / ranks.length).round();
    final a = RankEngine.assign(avg);
    return a.subRank == null
        ? 'AVG: ${a.rank.toUpperCase()}'
        : 'AVG: ${a.rank.toUpperCase()} ${a.subRank}';
  }

  /// Fires once on first Home render after the user finishes the onboarding
  /// flow. Writes `player.onboarded_at`, queues the analytics event, and
  /// refreshes PlayerState so observers pick up the new state.
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
    // Flip the router flag so subsequent cold starts (and any in-session
    // navigation back to `/`) go straight to Home instead of re-running
    // the onboarding flow.
    isOnboardedNotifier.value = true;
    if (!mounted) return;
    await state.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<PlayerState>();
    return InAppShell(
      active: AppTab.home,
      title: 'HOME',
      child: ListView(
        padding: const EdgeInsets.all(AppSpace.s5),
        children: [
          Text(
            '…welcome back, player.',
            style: AppType.system(color: AppPalette.textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            s.playerName.toUpperCase(),
            style: AppType.displayLG(color: AppPalette.textPrimary),
          ),
          const SizedBox(height: AppSpace.s3),
          Row(
            children: [
              LevelPill(level: s.level),
              const SizedBox(width: AppSpace.s3),
              StreakPill(count: s.streak),
            ],
          ),
          const SizedBox(height: AppSpace.s4),

          // XP ring card
          NeonCard(
            glow: GlowColor.xp,
            padding: const EdgeInsets.all(AppSpace.s6),
            onTap: () => context.go('/profile'),
            child: Row(
              children: [
                XPRing(level: s.level, percent: s.xpPercent, size: 92),
                const SizedBox(width: AppSpace.s5),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NEXT LEVEL',
                        style: AppType.label(color: AppPalette.textMuted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${s.xpCurrent} / ${s.xpMax}',
                        style: AppType.monoLG(color: AppPalette.xpGold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${s.xpMax - s.xpCurrent} XP to LVL ${s.level + 1}',
                        style: AppType.bodySM(color: AppPalette.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.s4),

          // Today's Session — surfaces the PlanGenerator output. Rest day
          // falls back to a "pick any" escape hatch to the exercise picker.
          _TodaysSessionCard(),
          const SizedBox(height: AppSpace.s3),
          Align(
            alignment: Alignment.centerRight,
            child: GhostButton(
              label: 'OR PICK ANY EXERCISE →',
              onTap: () => context.go('/exercise-picker'),
            ),
          ),
          const SizedBox(height: AppSpace.s4),

          // Total Workouts card — reads from SQLite via FutureBuilder, taps
          // through to the full history list.
          _TotalWorkoutsCard(
            onTap: () => context.go('/workouts'),
          ),
          const SizedBox(height: AppSpace.s4),

          // Active quests
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'ACTIVE QUESTS',
                style: AppType.label(color: AppPalette.textMuted),
              ),
              GhostButton(
                label: 'VIEW ALL →',
                onTap: () => context.go('/quests'),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s3),
          FutureBuilder<List<model.Quest>>(
            future: _dailyQuests,
            builder: (ctx, snap) {
              final quests = snap.data ?? const [];
              if (quests.isEmpty) {
                return Text(
                  '> rotating today\'s quests…',
                  style: AppType.system(color: AppPalette.textMuted),
                );
              }
              // Show up to 2, but prefer in-progress quests over completed
              // ones so the user sees what's actionable without losing the
              // DONE state of a just-finished quest until tomorrow.
              final sorted = [
                ...quests.where((q) => !q.isCompleted),
                ...quests.where((q) => q.isCompleted),
              ];
              return Column(
                children: [
                  for (final q in sorted.take(2)) ...[
                    QuestRow(
                      title: q.title,
                      type: QuestType.daily,
                      progress: q.isCompleted ? 1.0 : q.progressRatio,
                      xp: q.xpReward,
                      completed: q.isCompleted,
                    ),
                    const SizedBox(height: AppSpace.s3),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: AppSpace.s4),

          // Muscle ranks — real data from RankEngine. Empty until the user
          // logs their first sets.
          NeonCard(
            glow: GlowColor.none,
            padding: const EdgeInsets.all(AppSpace.s5),
            pulse: false,
            onTap: () => context.go('/profile'),
            child: FutureBuilder<List<MuscleRank>>(
              future: _muscleRanks,
              builder: (ctx, snap) {
                final ranks = snap.data ?? const [];
                final overall = _overallLabel(ranks);
                // Show up to 5 most-trained muscles inline.
                final top = [...ranks]
                  ..sort((a, b) => b.rankXp.compareTo(a.rankXp));
                final display = top.take(5).toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'MUSCLE RANKS',
                                style: AppType.label(color: AppPalette.textMuted),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                overall,
                                style: AppType.displayMD(
                                  color: AppPalette.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const MuscleFigure(
                          highlight: MuscleHighlight.chest,
                          color: AppPalette.xpGold,
                          size: 80,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.s4),
                    if (display.isEmpty)
                      Text(
                        '> log a set to see your first rank.',
                        style: AppType.system(color: AppPalette.textMuted),
                      )
                    else
                      Row(
                        children: [
                          for (final r in display)
                            _MuscleMini(
                              name: r.muscle.toUpperCase(),
                              rank: rankFromString(r.rank),
                              sub: r.subRank ?? '—',
                            ),
                        ],
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TodaysSessionCard extends StatelessWidget {
  Future<_SessionCardState> _load() async {
    final results = await Future.wait([
      PlanGenerator.todaysSession(),
      WorkoutService.finishedToday(),
    ]);
    return _SessionCardState(
      plan: results[0] as SessionPlan?,
      doneToday: results[1] as Workout?,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_SessionCardState>(
      future: _load(),
      builder: (ctx, snap) {
        final data = snap.data;
        final plan = data?.plan;
        final done = data?.doneToday;
        final settled = snap.connectionState == ConnectionState.done;
        final didToday = done != null;
        final noScheduleYet = settled && plan == null && !didToday;
        final noMatches =
            !didToday && plan != null && plan.exercises.isEmpty;
        final isOptional =
            !didToday && plan != null && !plan.isScheduled;

        // Five states, distinguished by tap target and copy:
        //   0) done today         → "/workouts/<id>"      (green, check)
        //   1) no schedule        → "/training-days"      (teal, play)
        //   2) no equipment match → "/equipment"          (teal, tune)
        //   3) optional day       → "/home/todays-workout" (teal, moon)
        //   4) scheduled          → "/home/todays-workout" (purple, play)
        final String tapRoute;
        if (didToday) {
          tapRoute = '/workouts/${done.id}';
        } else if (noScheduleYet) {
          tapRoute = '/training-days';
        } else if (noMatches) {
          tapRoute = '/equipment';
        } else {
          tapRoute = '/home/todays-workout';
        }

        final Color accent;
        final GlowColor glow;
        if (didToday) {
          accent = AppPalette.green;
          glow = GlowColor.green;
        } else if (noScheduleYet || noMatches || isOptional) {
          accent = AppPalette.teal;
          glow = GlowColor.teal;
        } else {
          accent = AppPalette.purple;
          glow = GlowColor.purple;
        }

        final IconData icon;
        if (didToday) {
          icon = Icons.check;
        } else if (noMatches) {
          icon = Icons.tune;
        } else if (isOptional) {
          icon = Icons.bedtime;
        } else {
          icon = Icons.play_arrow;
        }

        final String kicker;
        final String title;
        final String subtitle;
        if (didToday) {
          kicker = 'COMPLETED TODAY';
          title = (plan?.focus ?? 'SESSION LOGGED');
          final xp = done.xpEarned;
          final vol = done.volumeKg.round();
          subtitle = 'Tap to view session · +$xp XP · ${vol}kg volume';
        } else if (noScheduleYet) {
          kicker = 'NO SCHEDULE SET';
          title = 'PICK TRAINING DAYS';
          subtitle = 'Tap to set your weekly training days.';
        } else if (noMatches) {
          kicker = 'EQUIPMENT MISSING';
          title = plan.focus;
          subtitle =
              'No exercises match your gear for ${plan.focus.toLowerCase()} day. Tap to add equipment.';
        } else if (isOptional) {
          kicker = 'OPTIONAL · NOT SCHEDULED';
          title = plan.focus;
          subtitle =
              '${plan.exercises.length} exercises · today is a rest day, train anyway?';
        } else {
          kicker = "TODAY'S PROTOCOL";
          title = plan?.focus ?? 'LOADING…';
          subtitle = plan == null
              ? '…calibrating your session'
              : '${plan.exercises.length} exercises · ~${plan.estimatedMinutes} min';
        }

        return NeonCard(
          glow: glow,
          padding: const EdgeInsets.all(AppSpace.s5),
          onTap: () => GoRouter.of(context).go(tapRoute),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(kicker, style: AppType.label(color: accent)),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style:
                          AppType.displayMD(color: AppPalette.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style:
                          AppType.bodySM(color: AppPalette.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: accent, blurRadius: 16),
                  ],
                ),
                child: Icon(
                  icon,
                  color: AppPalette.obsidian,
                  size: 22,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SessionCardState {
  const _SessionCardState({required this.plan, required this.doneToday});
  final SessionPlan? plan;
  final Workout? doneToday;
}

class _TotalWorkoutsCard extends StatelessWidget {
  const _TotalWorkoutsCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      glow: GlowColor.teal,
      padding: const EdgeInsets.all(AppSpace.s5),
      pulse: false,
      onTap: onTap,
      child: FutureBuilder<int>(
        future: WorkoutService.totalFinished(),
        builder: (ctx, snap) {
          final count = snap.data ?? 0;
          return Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL WORKOUTS',
                      style: AppType.label(color: AppPalette.teal),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$count',
                      style: AppType.monoXL(color: AppPalette.teal).copyWith(
                        fontSize: 40,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      count == 0
                          ? 'your journey begins'
                          : 'tap to view history',
                      style: AppType.bodySM(color: AppPalette.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.history,
                color: AppPalette.teal,
                size: 32,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MuscleMini extends StatelessWidget {
  const _MuscleMini({
    required this.name,
    required this.rank,
    required this.sub,
  });

  final String name;
  final Rank rank;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          RankBadge(rank: rank, subRank: sub, size: 32),
          const SizedBox(height: 4),
          Text(
            name,
            style: AppType.label(color: AppPalette.textMuted).copyWith(
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}
