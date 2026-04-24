import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/models/exercise.dart';
import '../data/models/goal.dart';
import '../data/models/workout.dart';
import '../data/services/exercise_service.dart';
import '../data/services/goals_service.dart';
import '../data/services/workout_service.dart';
import '../game/plan_generator.dart';
import '../theme/tokens.dart';
import '../widgets/buttons.dart';
import '../widgets/neon_card.dart';
import '../widgets/screen_base.dart';
import '../widgets/system_header.dart';

/// PRD §9A.2 — Today's Workout.
///
/// Surfaces the [PlanGenerator] output: today's focus, prescribed exercises
/// with sets × reps, muscle-split chips, a "why this workout" rationale, and
/// a Swap sheet per exercise. Start Workout kicks off a live session with
/// the first prescribed exercise.
///
/// Rest-day state (no scheduled training today) shows the rest-day card with
/// a secondary "log free workout" escape hatch to the exercise picker.
class TodaysWorkoutScreen extends StatefulWidget {
  const TodaysWorkoutScreen({super.key});

  @override
  State<TodaysWorkoutScreen> createState() => _TodaysWorkoutScreenState();
}

class _TodaysWorkoutScreenState extends State<TodaysWorkoutScreen> {
  late Future<_PlanBundle> _future;

  // Local overrides for Swap — keyed by slot index; v1 keeps them in-memory.
  // PRD §9A.2 "Edit mode" persists to `workout_overrides`; deferred.
  final Map<int, PlannedExercise> _swaps = {};

  bool _rationaleOpen = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_PlanBundle> _load() async {
    final plan = await PlanGenerator.todaysSession();
    final goal = await GoalsService.get();
    final doneToday = await WorkoutService.finishedToday();
    return _PlanBundle(plan: plan, goal: goal, doneToday: doneToday);
  }

  List<PlannedExercise> _currentExercises(SessionPlan plan) {
    final out = <PlannedExercise>[];
    for (var i = 0; i < plan.exercises.length; i++) {
      out.add(_swaps[i] ?? plan.exercises[i]);
    }
    return out;
  }

  Future<void> _openSwapSheet(int slotIndex, PlannedExercise current) async {
    final catalog = await ExerciseService.getAll();
    final currentEx = catalog.firstWhere(
      (e) => e.id == current.exerciseId,
      orElse: () => catalog.first,
    );
    final alternates = catalog
        .where((e) =>
            e.id != null &&
            e.id != current.exerciseId &&
            e.primaryMuscle == currentEx.primaryMuscle)
        .take(3)
        .toList();

    if (!mounted) return;
    final picked = await showModalBottomSheet<Exercise>(
      context: context,
      backgroundColor: AppPalette.carbon,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => _SwapSheet(
        current: currentEx,
        alternates: alternates,
      ),
    );
    if (picked == null || picked.id == null) return;

    setState(() {
      _swaps[slotIndex] = PlannedExercise(
        exerciseId: picked.id!,
        name: picked.name,
        sets: current.sets,
        reps: current.reps,
        isPriority: current.isPriority,
      );
    });
  }

  void _startWorkout(List<PlannedExercise> exercises) {
    if (exercises.isEmpty) return;
    // Queue the remaining exercises as a comma-separated query param so the
    // logger can advance through them in order, all under one `workouts`
    // row. Example: `/workout/new/12?queue=45,67` → user logs 12, then
    // NEXT EXERCISE advances to 45, then 67, then FINISH closes the row.
    final first = exercises.first.exerciseId;
    final rest = exercises.skip(1).map((e) => e.exerciseId).join(',');
    final suffix = rest.isEmpty ? '' : '?queue=$rest';
    context.go('/workout/new/$first$suffix');
  }

  @override
  Widget build(BuildContext context) {
    return ScreenBase(
      child: FutureBuilder<_PlanBundle>(
        future: _future,
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppPalette.teal),
            );
          }
          final bundle = snap.data!;
          if (bundle.plan == null) {
            return _NoScheduleState(onBack: () => context.go('/home'));
          }

          final plan = bundle.plan!;
          final exercises = _currentExercises(plan);
          final doneToday = bundle.doneToday;

          return Column(
            children: [
              _Header(onBack: () => context.go('/home')),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.s5,
                    AppSpace.s4,
                    AppSpace.s5,
                    AppSpace.s6,
                  ),
                  children: [
                    if (doneToday != null) ...[
                      _CompletedBanner(workout: doneToday),
                      const SizedBox(height: AppSpace.s4),
                    ] else if (!plan.isScheduled) ...[
                      _OptionalBanner(),
                      const SizedBox(height: AppSpace.s4),
                    ],
                    _SummaryChipRow(plan: plan),
                    const SizedBox(height: AppSpace.s3),
                    _ProfileChipRow(plan: plan),
                    const SizedBox(height: AppSpace.s4),
                    _MuscleSplitTags(plan: plan, goal: bundle.goal),
                    const SizedBox(height: AppSpace.s4),
                    _WhyCard(
                      open: _rationaleOpen,
                      plan: plan,
                      goal: bundle.goal,
                      onToggle: () =>
                          setState(() => _rationaleOpen = !_rationaleOpen),
                    ),
                    const SizedBox(height: AppSpace.s5),
                    Text(
                      'EXERCISES',
                      style: AppType.label(color: AppPalette.textMuted),
                    ),
                    const SizedBox(height: AppSpace.s3),
                    for (var i = 0; i < exercises.length; i++) ...[
                      _ExerciseCard(
                        slot: i + 1,
                        exercise: exercises[i],
                        onSwap: () => _openSwapSheet(i, exercises[i]),
                      ),
                      const SizedBox(height: AppSpace.s3),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.s5,
                  0,
                  AppSpace.s5,
                  AppSpace.s5,
                ),
                child: doneToday != null
                    ? PrimaryButton(
                        label: 'VIEW SESSION',
                        onTap: () =>
                            context.go('/workouts/${doneToday.id}'),
                      )
                    : PrimaryButton(
                        label: 'START WORKOUT',
                        onTap: () => _startWorkout(exercises),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PlanBundle {
  const _PlanBundle({
    required this.plan,
    required this.goal,
    required this.doneToday,
  });
  final SessionPlan? plan;
  final Goal? goal;
  final Workout? doneToday;
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.s5,
        AppSpace.s5,
        AppSpace.s5,
        AppSpace.s3,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppPalette.strokeHairline)),
      ),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onBack,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: AppPalette.strokeHairline),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: AppPalette.textSecondary, size: 16),
            ),
          ),
          const SizedBox(width: AppSpace.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SystemHeader(
                  kicker: 'PROTOCOL',
                  color: AppPalette.teal,
                ),
                const SizedBox(height: 2),
                Text(
                  "TODAY'S WORKOUT",
                  style: AppType.displayMD(color: AppPalette.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryChipRow extends StatelessWidget {
  const _SummaryChipRow({required this.plan});
  final SessionPlan plan;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpace.s3,
      runSpacing: AppSpace.s3,
      children: [
        _Chip(
          text: plan.focus,
          color: AppPalette.purple,
        ),
        _Chip(
          text: '~${plan.estimatedMinutes} min',
          color: AppPalette.teal,
        ),
        _Chip(
          text: '${plan.exercises.length} exercises',
          color: AppPalette.xpGold,
        ),
      ],
    );
  }
}

/// Strip of chips that reflect the user's profile inputs feeding the plan.
/// Visible so edits to onboarding (equipment / priority muscles / body type /
/// days) are obviously the reason a prescription changed.
class _ProfileChipRow extends StatelessWidget {
  const _ProfileChipRow({required this.plan});
  final SessionPlan plan;

  String _bodyTypeLabel(String? bt) {
    switch (bt) {
      case 'lean':
        return 'LEAN GOAL';
      case 'muscular':
        return 'HYPERTROPHY';
      case 'strong':
        return 'STRENGTH';
      case 'balanced':
        return 'BALANCED';
      default:
        return 'DEFAULT MIX';
    }
  }

  @override
  Widget build(BuildContext context) {
    final equipmentCount = plan.ownedEquipment
        .where((e) => e != 'bodyweight')
        .length;
    final equipmentChip = equipmentCount == 0
        ? 'BODYWEIGHT ONLY'
        : '$equipmentCount GEAR';
    final priorityChip = plan.priorityMuscles.isEmpty
        ? null
        : 'PRIORITY: ${plan.priorityMuscles.take(2).join(" · ").toUpperCase()}';

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _TinyChip(text: '${plan.daysPerWeek} DAYS/WK'),
        _TinyChip(text: _bodyTypeLabel(plan.bodyType)),
        _TinyChip(text: equipmentChip),
        if (priorityChip != null)
          _TinyChip(text: priorityChip, highlight: true),
      ],
    );
  }
}

class _TinyChip extends StatelessWidget {
  const _TinyChip({required this.text, this.highlight = false});
  final String text;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final color =
        highlight ? AppPalette.yellow : AppPalette.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: highlight
            ? AppPalette.yellow.withValues(alpha: 0.08)
            : AppPalette.slate,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: highlight ? AppPalette.yellow : AppPalette.strokeSubtle,
        ),
      ),
      child: Text(
        text,
        style: AppType.label(color: color).copyWith(fontSize: 9),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color),
      ),
      child: Text(
        text.toUpperCase(),
        style: AppType.label(color: color),
      ),
    );
  }
}

class _MuscleSplitTags extends StatelessWidget {
  const _MuscleSplitTags({required this.plan, required this.goal});
  final SessionPlan plan;
  final Goal? goal;

  @override
  Widget build(BuildContext context) {
    // Count exercises per primary muscle (read from the generated plan).
    // We don't have the exercise model here — pass it via the cards. For the
    // tag strip we extract muscle name from the exercise name heuristically
    // by mapping the plan's focus label back to its muscle groups.
    final muscles = _PlanGeneratorView.musclesFromFocus(plan.focus);
    final priority = goal?.priorityMuscles ?? const <String>[];

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final m in muscles)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: priority.contains(m)
                  ? AppPalette.xpGold.withValues(alpha: 0.15)
                  : AppPalette.slate,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                color: priority.contains(m)
                    ? AppPalette.xpGold
                    : AppPalette.strokeSubtle,
              ),
            ),
            child: Text(
              m,
              style: AppType.bodySM(
                color: priority.contains(m)
                    ? AppPalette.xpGold
                    : AppPalette.textSecondary,
              ),
            ),
          ),
      ],
    );
  }
}

/// Thin lookup helpers — mirrors the maps inside [PlanGenerator] without
/// re-exporting private state.
class _PlanGeneratorView {
  static List<String> musclesFromFocus(String focusLabel) {
    switch (focusLabel.toUpperCase()) {
      case 'PUSH':
        return ['chest', 'shoulders', 'triceps'];
      case 'PULL':
        return ['back', 'biceps'];
      case 'LEGS':
        return ['quads', 'hamstrings', 'glutes', 'calves'];
      case 'UPPER BODY':
        return ['chest', 'back', 'shoulders', 'biceps', 'triceps'];
      case 'LOWER BODY':
        return ['quads', 'hamstrings', 'glutes', 'calves'];
      case 'FULL BODY':
        return ['chest', 'back', 'shoulders', 'quads', 'hamstrings', 'core'];
      default:
        return const [];
    }
  }
}

class _WhyCard extends StatelessWidget {
  const _WhyCard({
    required this.open,
    required this.plan,
    required this.goal,
    required this.onToggle,
  });

  final bool open;
  final SessionPlan plan;
  final Goal? goal;
  final VoidCallback onToggle;

  String _rationale() {
    final bt = goal?.bodyType;
    final focus = plan.focus.toLowerCase();
    final priority = goal?.priorityMuscles ?? const [];
    final priorityLine = priority.isEmpty
        ? 'no priority muscles set'
        : 'priority: ${priority.take(3).join(", ")}';
    final goalLine = switch (bt) {
      'strong' => 'strength bias — low reps, heavy compounds',
      'muscular' => 'hypertrophy bias — moderate reps, volume focus',
      'lean' => 'endurance bias — higher reps, shorter rest',
      'balanced' => 'balanced mix — moderate everything',
      _ => 'default hypertrophy mix',
    };
    return 'Today is a $focus day. System selected ${plan.exercises.length} exercises matching your available equipment. $goalLine. $priorityLine.';
  }

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      glow: GlowColor.none,
      pulse: false,
      padding: EdgeInsets.zero,
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology_outlined,
                    color: AppPalette.teal, size: 16),
                const SizedBox(width: 8),
                Text(
                  'WHY THIS WORKOUT?',
                  style: AppType.label(color: AppPalette.teal),
                ),
                const Spacer(),
                Icon(open ? Icons.expand_less : Icons.expand_more,
                    color: AppPalette.textMuted, size: 18),
              ],
            ),
            if (open) ...[
              const SizedBox(height: AppSpace.s3),
              Text(
                _rationale(),
                style: AppType.bodyMD(color: AppPalette.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.slot,
    required this.exercise,
    required this.onSwap,
  });

  final int slot;
  final PlannedExercise exercise;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      glow: GlowColor.none,
      pulse: false,
      padding: const EdgeInsets.all(AppSpace.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppPalette.teal.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppPalette.teal),
                ),
                child: Text(
                  '$slot',
                  style: AppType.monoMD(color: AppPalette.teal),
                ),
              ),
              const SizedBox(width: AppSpace.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: AppType.bodyLG(color: AppPalette.textPrimary),
                    ),
                    if (exercise.isPriority) ...[
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            color: AppPalette.yellow,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'PRIORITY MUSCLE',
                            style: AppType.label(color: AppPalette.yellow)
                                .copyWith(fontSize: 9),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              InkWell(
                onTap: onSwap,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppPalette.purple.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: AppPalette.purple),
                  ),
                  child: Text(
                    'SWAP',
                    style: AppType.label(color: AppPalette.purple)
                        .copyWith(fontSize: 10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s3),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 1; i <= exercise.sets; i++)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppPalette.slate,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: AppPalette.strokeSubtle),
                  ),
                  child: Text(
                    'Set $i: ${exercise.reps} reps',
                    style: AppType.bodySM(color: AppPalette.textSecondary),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SwapSheet extends StatelessWidget {
  const _SwapSheet({required this.current, required this.alternates});
  final Exercise current;
  final List<Exercise> alternates;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.s5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SWAP · ${current.primaryMuscle.toUpperCase()}',
              style: AppType.label(color: AppPalette.purple),
            ),
            const SizedBox(height: 4),
            Text(
              'Replace ${current.name}',
              style: AppType.displayMD(color: AppPalette.textPrimary),
            ),
            const SizedBox(height: AppSpace.s5),
            if (alternates.isEmpty)
              Text(
                '> no alternates available for this muscle with your equipment.',
                style: AppType.system(color: AppPalette.textMuted),
              )
            else
              for (final a in alternates)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.s3),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(a),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpace.s4),
                        decoration: BoxDecoration(
                          color: AppPalette.slate,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppPalette.strokeSubtle),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    a.name,
                                    style: AppType.bodyLG(
                                      color: AppPalette.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    a.equipment.isEmpty
                                        ? 'bodyweight'
                                        : a.equipment.join(' · '),
                                    style: AppType.bodySM(
                                      color: AppPalette.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios,
                                color: AppPalette.textMuted, size: 14),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            const SizedBox(height: AppSpace.s3),
            SecondaryButton(
              label: 'CANCEL',
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Inline banner shown when today isn't in `schedule.days`. The session list
/// still renders below — user can train anyway or skip.
class _OptionalBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return NeonCard(
      glow: GlowColor.teal,
      pulse: false,
      padding: const EdgeInsets.all(AppSpace.s4),
      child: Row(
        children: [
          const Icon(Icons.bedtime, color: AppPalette.teal, size: 20),
          const SizedBox(width: AppSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TODAY IS A REST DAY',
                  style: AppType.label(color: AppPalette.teal),
                ),
                const SizedBox(height: 2),
                Text(
                  'Session below is your next-scheduled focus — train anyway if you feel like it.',
                  style: AppType.bodySM(color: AppPalette.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletedBanner extends StatelessWidget {
  const _CompletedBanner({required this.workout});
  final Workout workout;

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      glow: GlowColor.green,
      pulse: false,
      padding: const EdgeInsets.all(AppSpace.s4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppPalette.green, size: 22),
          const SizedBox(width: AppSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SESSION COMPLETED TODAY',
                  style: AppType.label(color: AppPalette.green),
                ),
                const SizedBox(height: 2),
                Text(
                  '+${workout.xpEarned} XP · ${workout.volumeKg.round()}kg · '
                  '${workout.duration.inMinutes} min logged. Tap VIEW SESSION for details.',
                  style: AppType.bodySM(color: AppPalette.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-screen empty state when the user hasn't completed the training-days
/// step of onboarding (or wiped the schedule). PlanGenerator returns null
/// only in this case now.
class _NoScheduleState extends StatelessWidget {
  const _NoScheduleState({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Header(onBack: onBack),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.s7),
              child: NeonCard(
                glow: GlowColor.teal,
                padding: const EdgeInsets.all(AppSpace.s7),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SystemHeader(
                      kicker: 'NO SCHEDULE',
                      color: AppPalette.teal,
                    ),
                    const SizedBox(height: AppSpace.s4),
                    Text(
                      'SET YOUR\nTRAINING DAYS',
                      style: AppType.displayLG(color: AppPalette.textPrimary),
                    ),
                    const SizedBox(height: AppSpace.s3),
                    Text(
                      '…the System needs at least two training days to generate a session. Or log one-off workouts from the picker.',
                      style: AppType.bodyMD(color: AppPalette.textSecondary),
                    ),
                    const SizedBox(height: AppSpace.s6),
                    PrimaryButton(
                      label: 'PICK AN EXERCISE',
                      onTap: () => GoRouter.of(context).go('/exercise-picker'),
                    ),
                    const SizedBox(height: AppSpace.s3),
                    SecondaryButton(
                      label: 'EDIT TRAINING DAYS',
                      onTap: () => GoRouter.of(context).go('/training-days'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
