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
import '../widgets/pills.dart';
import '../widgets/screen_base.dart';

/// Today's Workout — matches design v2 (`design/v2/screens-home.jsx`
/// `TodaysWorkoutScreen`).
///
/// Layout: header (back / title / Edit) → big focus title + summary pills
/// → volume-split chips → "Why this workout?" expander → exercise cards
/// with Swap pill → bottom teal START WORKOUT.
///
/// State plumbing preserved from earlier passes: real `PlanGenerator`
/// output, in-memory swap overrides, queued-multi-exercise start, and
/// "session completed today" notice.
class TodaysWorkoutScreen extends StatefulWidget {
  const TodaysWorkoutScreen({super.key});

  @override
  State<TodaysWorkoutScreen> createState() => _TodaysWorkoutScreenState();
}

class _TodaysWorkoutScreenState extends State<TodaysWorkoutScreen> {
  SessionPlan? _plan;
  Goal? _goal;
  Workout? _doneToday;

  // Working list is materialized once the plan loads, then mutated
  // freely by swap / add / remove. All edits are in-memory only —
  // they don't write back to the schedule (the next visit regenerates
  // a fresh plan via PlanGenerator).
  List<PlannedExercise> _exercises = [];
  bool _editing = false;
  bool _rationaleOpen = false;
  bool _loading = true;
  bool _empty = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      PlanGenerator.todaysSession(),
      GoalsService.get(),
      WorkoutService.finishedToday(),
    ]);
    if (!mounted) return;
    final plan = results[0] as SessionPlan?;
    setState(() {
      _plan = plan;
      _goal = results[1] as Goal?;
      _doneToday = results[2] as Workout?;
      _exercises = plan == null ? [] : List.of(plan.exercises);
      _loading = false;
      _empty = plan == null;
    });
  }

  Future<void> _openSwapSheet(int index, PlannedExercise current) async {
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
      backgroundColor: AppPalette.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _SwapSheet(
        current: currentEx,
        alternates: alternates,
      ),
    );
    if (picked == null || picked.id == null) return;
    setState(() {
      _exercises[index] = PlannedExercise(
        exerciseId: picked.id!,
        name: picked.name,
        sets: current.sets,
        reps: current.reps,
        isPriority: current.isPriority,
      );
    });
  }

  Future<void> _openAddSheet() async {
    final catalog = await ExerciseService.getAll();
    final inSession = _exercises.map((e) => e.exerciseId).toSet();
    // Don't show exercises already in the session — would just be a
    // duplicate slot. User can re-add them after removing if needed.
    final available = catalog
        .where((e) => e.id != null && !inSession.contains(e.id))
        .toList();
    if (!mounted) return;
    final picked = await showModalBottomSheet<Exercise>(
      context: context,
      backgroundColor: AppPalette.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _AddExerciseSheet(available: available),
    );
    if (picked == null || picked.id == null) return;
    setState(() {
      _exercises.add(PlannedExercise(
        exerciseId: picked.id!,
        name: picked.name,
        sets: 3,
        reps: 10,
        isPriority: false,
      ));
    });
  }

  void _removeAt(int index) {
    setState(() {
      _exercises.removeAt(index);
    });
  }

  void _toggleEdit() {
    setState(() => _editing = !_editing);
  }

  void _startWorkout() {
    if (_exercises.isEmpty) return;
    final first = _exercises.first.exerciseId;
    final rest = _exercises.skip(1).map((e) => e.exerciseId).join(',');
    final suffix = rest.isEmpty ? '' : '?queue=$rest';
    context.go('/workout/new/$first$suffix');
  }

  @override
  Widget build(BuildContext context) {
    return ScreenBase(
      child: Builder(
        builder: (ctx) {
          if (_loading) {
            return const Center(
              child: CircularProgressIndicator(color: AppPalette.purple),
            );
          }
          if (_empty) {
            return _NoScheduleEmpty(onBack: () => context.go('/home'));
          }
          final plan = _plan!;
          final doneToday = _doneToday;

          return Column(
            children: [
              _Header(
                onBack: () => context.go('/home'),
                editing: _editing,
                onEditToggle: doneToday == null ? _toggleEdit : null,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 32),
                  children: [
                    if (doneToday != null) ...[
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(20, 0, 20, 14),
                        child: _DoneTodayNotice(workout: doneToday),
                      ),
                    ] else if (!plan.isScheduled)
                      const Padding(
                        padding: EdgeInsets.fromLTRB(20, 0, 20, 14),
                        child: _OptionalNotice(),
                      ),
                    _TitleBlock(plan: plan, exerciseCount: _exercises.length),
                    _VolumeSplit(exercises: _exercises, goal: _goal),
                    _WhyExpander(
                      open: _rationaleOpen,
                      plan: plan,
                      goal: _goal,
                      onToggle: () =>
                          setState(() => _rationaleOpen = !_rationaleOpen),
                    ),
                    _ExercisesSection(
                      exercises: _exercises,
                      editing: _editing,
                      onSwap: _openSwapSheet,
                      onRemove: _removeAt,
                      onAdd: _openAddSheet,
                    ),
                    if (!_editing)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: doneToday != null
                            ? _ViewSessionButton(
                                onTap: () =>
                                    context.go('/workouts/${doneToday.id}'),
                              )
                            : _StartButton(
                                onTap: _exercises.isEmpty
                                    ? null
                                    : _startWorkout,
                              ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Header ────────────────────────────────────────────────
class _Header extends StatelessWidget {
  const _Header({
    required this.onBack,
    required this.editing,
    required this.onEditToggle,
  });

  final VoidCallback onBack;
  final bool editing;

  /// Tappable Edit / Done CTA. Null when the user has already
  /// completed today's session — editing is disabled at that point.
  final VoidCallback? onEditToggle;

  @override
  Widget build(BuildContext context) {
    final label = editing ? 'DONE' : 'EDIT';
    final color = onEditToggle == null
        ? AppPalette.textDisabled
        : (editing ? AppPalette.amber : AppPalette.teal);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _IconCircle(
            icon: Icons.chevron_left,
            onTap: onBack,
            size: 38,
          ),
          const Text(
            "Today's Workout",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppPalette.textPrimary,
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onEditToggle,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 60,
                height: 38,
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: color,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconCircle extends StatelessWidget {
  const _IconCircle({
    required this.icon,
    required this.onTap,
    this.size = 38,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size / 2),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppPalette.purple.withValues(alpha: 0.12),
            border: Border.all(
              color: AppPalette.purple.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Icon(icon, size: 20, color: AppPalette.textPrimary),
        ),
      ),
    );
  }
}

// ─── Title block ───────────────────────────────────────────
class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.plan, required this.exerciseCount});
  final SessionPlan plan;
  final int exerciseCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            plan.focus,
            style: AppType.displayXL(color: AppPalette.textPrimary).copyWith(
              fontSize: 40,
              height: 1,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              AppPill(label: _categoryFor(plan.focus)),
              AppPill(
                label: '~${plan.estimatedMinutes} min',
                variant: AppPillVariant.ghost,
              ),
              AppPill(
                label: '$exerciseCount exercises',
                variant: AppPillVariant.ghost,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _categoryFor(String focus) {
    final f = focus.toLowerCase();
    if (f.contains('push') || f.contains('upper')) return 'Upper Body';
    if (f.contains('pull')) return 'Upper Body';
    if (f.contains('leg') || f.contains('lower')) return 'Lower Body';
    if (f.contains('full')) return 'Full Body';
    return 'Mixed';
  }
}

// ─── Volume split chips ────────────────────────────────────
class _VolumeSplit extends StatelessWidget {
  const _VolumeSplit({required this.exercises, required this.goal});
  final List<PlannedExercise> exercises;
  final Goal? goal;

  // Simple muscle-percent estimate based on number of exercises hitting
  // each primary muscle. Reflects edits made via the EDIT button.
  Map<String, int> _split() {
    final counts = <String, int>{};
    for (final e in exercises) {
      final m = _muscleFor(e.name);
      counts[m] = (counts[m] ?? 0) + 1;
    }
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return const {};
    return {
      for (final entry in counts.entries)
        entry.key: ((entry.value / total) * 100).round(),
    };
  }

  static String _muscleFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('press') || n.contains('bench') || n.contains('push')) {
      return 'chest';
    }
    if (n.contains('shoulder') ||
        n.contains('lateral') ||
        n.contains('overhead')) {
      return 'shoulders';
    }
    if (n.contains('tricep') || n.contains('dip')) return 'triceps';
    if (n.contains('row') || n.contains('pull')) return 'back';
    if (n.contains('curl') && !n.contains('nordic')) return 'biceps';
    if (n.contains('squat') || n.contains('lunge')) return 'quads';
    if (n.contains('glute') || n.contains('bridge')) return 'glutes';
    if (n.contains('hamstring') || n.contains('nordic')) return 'hamstrings';
    if (n.contains('calf') || n.contains('jump')) return 'calves';
    return 'core';
  }

  static Color _colorFor(String muscle, int rank) {
    // First → amber, second → violet, third → green, rest → muted violet.
    if (rank == 0) return AppPalette.amberSoft;
    if (rank == 1) return AppPalette.purpleSoft;
    if (rank == 2) return const Color(0xFF22E06B);
    return AppPalette.textMuted;
  }

  @override
  Widget build(BuildContext context) {
    final split = _split();
    if (split.isEmpty) return const SizedBox.shrink();
    final entries = split.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'VOLUME SPLIT',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: AppPalette.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < entries.length; i++)
                _SplitChip(
                  label: '${entries[i].key} ${entries[i].value}%',
                  color: _colorFor(entries[i].key, i),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SplitChip extends StatelessWidget {
  const _SplitChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.30),
          width: 1,
        ),
      ),
      child: Text(
        label.toLowerCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ─── Why this workout? expander ───────────────────────────
class _WhyExpander extends StatelessWidget {
  const _WhyExpander({
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
    final priority = plan.priorityMuscles;
    final priorityLine = priority.isEmpty
        ? 'no priority muscles set'
        : 'priority: ${priority.take(3).join(", ")}';
    final goalLine = switch (plan.bodyType) {
      'strong' => 'strength bias — low reps, heavy compounds',
      'muscular' => 'hypertrophy bias — moderate reps, volume focus',
      'lean' => 'endurance bias — higher reps, shorter rest',
      'balanced' => 'balanced mix — moderate everything',
      _ => 'default hypertrophy mix',
    };
    return 'Today is a ${plan.focus.toLowerCase()} day. System selected ${plan.exercises.length} exercises matching your available equipment. $goalLine. $priorityLine.';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppPalette.purple.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppPalette.purple.withValues(alpha: 0.20),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppPalette.purpleSoft,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Why this workout?',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppPalette.textPrimary,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: open ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        size: 16,
                        color: AppPalette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (open) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppPalette.purple.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppPalette.purple.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: RichText(
                text: TextSpan(
                  style: AppType.system(color: AppPalette.textMuted),
                  children: [
                    TextSpan(
                      text: '[System] ',
                      style: TextStyle(
                        color: AppPalette.purpleSoft,
                        fontWeight: FontWeight.w700,
                        fontStyle: FontStyle.normal,
                      ),
                    ),
                    TextSpan(text: _rationale()),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Exercises section ─────────────────────────────────────
class _ExercisesSection extends StatelessWidget {
  const _ExercisesSection({
    required this.exercises,
    required this.editing,
    required this.onSwap,
    required this.onRemove,
    required this.onAdd,
  });

  final List<PlannedExercise> exercises;
  final bool editing;
  final void Function(int index, PlannedExercise ex) onSwap;
  final void Function(int index) onRemove;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'EXERCISES',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: AppPalette.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          if (exercises.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                editing
                    ? 'No exercises yet — tap ADD EXERCISE to build your session.'
                    : 'No exercises in this session.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppPalette.textMuted,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          for (var i = 0; i < exercises.length; i++) ...[
            _ExerciseCard(
              exercise: exercises[i],
              editing: editing,
              onSwap: () => onSwap(i, exercises[i]),
              onRemove: () => onRemove(i),
            ),
            const SizedBox(height: 10),
          ],
          if (editing) _AddExerciseRow(onTap: onAdd),
        ],
      ),
    );
  }
}

class _AddExerciseRow extends StatelessWidget {
  const _AddExerciseRow({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: AppPalette.teal.withValues(alpha: 0.08),
            border: Border.all(
              color: AppPalette.teal.withValues(alpha: 0.40),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline,
                  size: 18, color: AppPalette.teal),
              const SizedBox(width: 8),
              Text(
                'ADD EXERCISE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppPalette.teal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.exercise,
    required this.editing,
    required this.onSwap,
    required this.onRemove,
  });

  final PlannedExercise exercise;
  final bool editing;
  final VoidCallback onSwap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      glow: GlowColor.purple,
      pulse: false,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppPalette.purple.withValues(alpha: 0.25),
                  AppPalette.purple.withValues(alpha: 0.08),
                ],
              ),
              border: Border.all(
                color: AppPalette.purple.withValues(alpha: 0.30),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.fitness_center,
              size: 20,
              color: AppPalette.purpleSoft,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppPalette.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (exercise.isPriority) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.star, size: 11, color: AppPalette.amber),
                      const SizedBox(width: 4),
                      Text(
                        'PRIORITY MUSCLE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: AppPalette.amber,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  '${exercise.sets} × ${exercise.reps} reps',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppPalette.textDim,
                    fontFamily: 'JetBrainsMono',
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          if (editing)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onRemove,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppPalette.danger.withValues(alpha: 0.12),
                    border: Border.all(
                      color: AppPalette.danger.withValues(alpha: 0.40),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.close,
                        size: 12,
                        color: AppPalette.danger,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'REMOVE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppPalette.danger,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onSwap,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppPalette.purple.withValues(alpha: 0.12),
                    border: Border.all(
                      color: AppPalette.purple.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.swap_horiz,
                        size: 12,
                        color: AppPalette.purpleSoft,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'SWAP',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppPalette.purpleSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Notice strips (done today / optional rest day) ────────
class _DoneTodayNotice extends StatelessWidget {
  const _DoneTodayNotice({required this.workout});
  final Workout workout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPalette.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppPalette.success.withValues(alpha: 0.30),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: AppPalette.success, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SESSION COMPLETED TODAY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppPalette.success,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '+${workout.xpEarned} XP · ${workout.volumeKg.round()}kg · '
                  '${workout.duration.inMinutes} min — tap VIEW SESSION below.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppPalette.textMuted,
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

class _OptionalNotice extends StatelessWidget {
  const _OptionalNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPalette.teal.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppPalette.teal.withValues(alpha: 0.30),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.bedtime, color: AppPalette.teal, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TODAY IS A REST DAY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppPalette.teal,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Session below is the next scheduled focus — train anyway if you feel like it.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppPalette.textMuted,
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

// ─── No-schedule empty state ───────────────────────────────
class _NoScheduleEmpty extends StatelessWidget {
  const _NoScheduleEmpty({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Header(onBack: onBack, editing: false, onEditToggle: null),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: NeonCard(
                glow: GlowColor.teal,
                pulse: false,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NO SCHEDULE SET',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppPalette.teal,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'PICK YOUR TRAINING DAYS',
                      style: AppType.displayMD(color: AppPalette.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Set the days you can train this week so the System can prescribe today\'s session.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppPalette.textMuted,
                      ),
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: 'PICK TRAINING DAYS',
                      onTap: () =>
                          GoRouter.of(context).go('/training-days'),
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

// ─── Bottom CTAs ───────────────────────────────────────────
class _StartButton extends StatelessWidget {
  const _StartButton({required this.onTap});

  /// Null disables the button (greyed-out look). Used when the user
  /// has emptied the exercise list mid-edit.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
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
            gradient: LinearGradient(
              colors: disabled
                  ? [
                      AppPalette.teal.withValues(alpha: 0.35),
                      AppPalette.teal.withValues(alpha: 0.25),
                    ]
                  : const [Color(0xFF19E3E3), Color(0xFF0EC6C6)],
            ),
            boxShadow: disabled
                ? null
                : [
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
              Icon(Icons.play_arrow, color: AppPalette.voidBg, size: 18),
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

class _ViewSessionButton extends StatelessWidget {
  const _ViewSessionButton({required this.onTap});
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
            color: AppPalette.success.withValues(alpha: 0.12),
            border: Border.all(
              color: AppPalette.success.withValues(alpha: 0.45),
              width: 1,
            ),
          ),
          child: Text(
            'VIEW SESSION',
            style: AppType.displaySM(color: AppPalette.success).copyWith(
              fontSize: 16,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Swap sheet ────────────────────────────────────────────
class _SwapSheet extends StatelessWidget {
  const _SwapSheet({required this.current, required this.alternates});
  final Exercise current;
  final List<Exercise> alternates;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SWAP · ${current.primaryMuscle.toUpperCase()}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: AppPalette.purpleSoft,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Replace ${current.name}',
              style: AppType.displayMD(color: AppPalette.textPrimary),
            ),
            const SizedBox(height: 16),
            if (alternates.isEmpty)
              Text(
                '> no alternates available for this muscle with your equipment.',
                style: AppType.system(color: AppPalette.textMuted),
              )
            else
              for (final a in alternates)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(a),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppPalette.bgCard2,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppPalette.borderViolet,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    a.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppPalette.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    a.equipment.isEmpty
                                        ? 'bodyweight'
                                        : a.equipment.join(' · '),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppPalette.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: AppPalette.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            const SizedBox(height: 8),
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

// ─── Add-exercise sheet ───────────────────────────────────────
//
// Larger sheet than _SwapSheet because the user is browsing the full
// catalog rather than 3 same-muscle alternates. Group by primary
// muscle so it's scannable; defaults sets/reps to 3×10 on pick (the
// caller can refine later in-session).

class _AddExerciseSheet extends StatefulWidget {
  const _AddExerciseSheet({required this.available});
  final List<Exercise> available;

  @override
  State<_AddExerciseSheet> createState() => _AddExerciseSheetState();
}

class _AddExerciseSheetState extends State<_AddExerciseSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? widget.available
        : widget.available
            .where((e) =>
                e.name.toLowerCase().contains(_query) ||
                e.primaryMuscle.toLowerCase().contains(_query))
            .toList();

    final byMuscle = <String, List<Exercise>>{};
    for (final e in filtered) {
      byMuscle.putIfAbsent(e.primaryMuscle, () => []).add(e);
    }
    final groupKeys = byMuscle.keys.toList()..sort();

    final sheetHeight = MediaQuery.of(context).size.height * 0.75;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: sheetHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ADD EXERCISE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: AppPalette.teal,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pick from the catalog',
                style: AppType.displayMD(color: AppPalette.textPrimary),
              ),
              const SizedBox(height: 14),
              TextField(
                onChanged: (v) =>
                    setState(() => _query = v.trim().toLowerCase()),
                style: const TextStyle(color: AppPalette.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search exercises or muscle…',
                  hintStyle: const TextStyle(color: AppPalette.textDim),
                  prefixIcon: Icon(Icons.search,
                      size: 18, color: AppPalette.textMuted),
                  isDense: true,
                  filled: true,
                  fillColor: AppPalette.bgCard2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No exercises match "$_query".',
                          style: TextStyle(color: AppPalette.textMuted),
                        ),
                      )
                    : ListView(
                        children: [
                          for (final muscle in groupKeys) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(2, 4, 2, 8),
                              child: Text(
                                muscle.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                  color: AppPalette.purpleSoft,
                                ),
                              ),
                            ),
                            for (final e in byMuscle[muscle]!) ...[
                              _AddSheetRow(
                                exercise: e,
                                onTap: () => Navigator.of(context).pop(e),
                              ),
                              const SizedBox(height: 6),
                            ],
                            const SizedBox(height: 8),
                          ],
                        ],
                      ),
              ),
              const SizedBox(height: 8),
              SecondaryButton(
                label: 'CANCEL',
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddSheetRow extends StatelessWidget {
  const _AddSheetRow({required this.exercise, required this.onTap});
  final Exercise exercise;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppPalette.bgCard2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppPalette.borderViolet, width: 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      exercise.equipment.isEmpty
                          ? 'bodyweight'
                          : exercise.equipment.join(' · '),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppPalette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.add_circle_outline,
                  size: 18, color: AppPalette.teal),
            ],
          ),
        ),
      ),
    );
  }
}
