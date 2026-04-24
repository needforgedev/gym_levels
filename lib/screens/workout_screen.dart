import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/exercise.dart';
import '../data/models/workout_set.dart';
import '../data/services/exercise_service.dart';
import '../data/services/sets_service.dart';
import '../data/services/workout_service.dart';
import '../game/game_handlers.dart';
import '../state/player_state.dart';
import '../theme/tokens.dart';
import '../widgets/buttons.dart';
import '../widgets/neon_card.dart';
import '../widgets/numeric_stepper.dart';
import '../widgets/screen_base.dart';
import '../widgets/xp_toast.dart';

/// Live workout logger. Creates a `workouts` row on mount, writes a `sets`
/// row on every COMPLETE SET. Finish (or back-with-sets) stamps `ended_at`,
/// rolls up `volume_kg` and `xp_earned`, and lands the user on Home. If the
/// user backs out before logging a set, the empty workout is deleted.
enum _SetState { active, completed }

class _SetData {
  _SetData({required this.n, required this.state});
  final int n;
  _SetState state;
  int? reps;
  double? weight;
}

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({
    super.key,
    required this.exerciseId,
    this.queue = const [],
  });

  /// The exercise to log right now.
  final int exerciseId;

  /// Remaining exercises in the session after the current one. When non-empty,
  /// the logger shows a progress header and a `NEXT EXERCISE` CTA that swaps
  /// in the next id without ending the workout row. Passed through from
  /// Today's Workout so a prescribed 3-exercise session is tracked as one
  /// workout instead of three isolated ones.
  final List<int> queue;

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  Exercise? _exercise;
  int? _workoutId;
  bool _loading = true;
  final _sets = <_SetData>[_SetData(n: 1, state: _SetState.active)];
  int _reps = 8;
  double _weight = 20;
  bool _resting = false;
  int _restSec = 90;
  Timer? _restTimer;
  int? _toastKey;
  int _sessionXp = 0;
  DateTime? _startedAt;

  // Multi-exercise session state.
  late int _currentExerciseId;
  late List<int> _remaining;
  int _exerciseIndex = 0; // 1-based display = _exerciseIndex + 1
  late final int _totalExercises;

  @override
  void initState() {
    super.initState();
    _currentExerciseId = widget.exerciseId;
    _remaining = List<int>.from(widget.queue);
    _totalExercises = 1 + widget.queue.length;
    _boot();
  }

  Future<void> _boot() async {
    final ex = await ExerciseService.byId(_currentExerciseId);
    if (!mounted) return;
    if (ex == null) {
      context.go('/home');
      return;
    }
    final id = await WorkoutService.start();
    if (!mounted) return;
    setState(() {
      _exercise = ex;
      _workoutId = id;
      _startedAt = DateTime.now();
      _loading = false;
    });
  }

  Future<void> _advanceToNextExercise() async {
    if (_remaining.isEmpty) return;
    final nextId = _remaining.removeAt(0);
    final ex = await ExerciseService.byId(nextId);
    if (!mounted || ex == null) return;
    _restTimer?.cancel();
    setState(() {
      _currentExerciseId = nextId;
      _exercise = ex;
      _exerciseIndex += 1;
      _sets
        ..clear()
        ..add(_SetData(n: 1, state: _SetState.active));
      _reps = 8;
      _weight = 20;
      _resting = false;
      _restSec = 90;
    });
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    super.dispose();
  }

  void _startRest() {
    _restTimer?.cancel();
    setState(() {
      _resting = true;
      _restSec = 90;
    });
    _restTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _restSec = (_restSec - 1).clamp(0, 9999));
      if (_restSec == 0) {
        _restTimer?.cancel();
        setState(() => _resting = false);
      }
    });
  }

  Future<void> _completeSet() async {
    final idx = _sets.indexWhere((s) => s.state == _SetState.active);
    if (idx == -1 || _workoutId == null) return;

    // PR detection: beat either weight-for-reps or reps-at-weight?
    // Simple rule — a set is a PR if it out-volumes every prior set of the
    // same exercise (weight × reps). Uses SetsService.bestFor which already
    // orders by weight DESC, reps DESC.
    final prior = await SetsService.bestFor(_currentExerciseId);
    final priorVolume = prior == null
        ? 0
        : (prior.weightKg ?? 0) * prior.reps;
    final thisVolume = _weight * _reps;
    final isPr = prior != null && thisVolume > priorVolume;

    final xpEarned = await GameHandlers.xpForSet(
      exerciseId: _currentExerciseId,
      rpe: null, // RPE capture lands in a later Phase 2 polish pass
      isPr: isPr,
    );

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await SetsService.insertSet(WorkoutSet(
      workoutId: _workoutId!,
      exerciseId: _currentExerciseId,
      setNumber: _sets[idx].n,
      weightKg: _weight,
      reps: _reps,
      xpEarned: xpEarned,
      isPr: isPr,
      completedAt: now,
    ));

    if (!mounted) return;
    setState(() {
      _sets[idx]
        ..state = _SetState.completed
        ..reps = _reps
        ..weight = _weight;
      _sessionXp += xpEarned;
      _toastKey = DateTime.now().millisecondsSinceEpoch;
    });

    context.read<PlayerState>().addXp(xpEarned);
    _startRest();

    Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() => _toastKey = null);
    });
  }

  void _addSet() {
    setState(() {
      _sets.add(_SetData(n: _sets.length + 1, state: _SetState.active));
    });
  }

  Future<void> _finishAndGo(String fallbackRoute) async {
    if (_workoutId == null) {
      if (!mounted) return;
      context.go(fallbackRoute);
      return;
    }

    // Capture the PlayerState before any awaits so we don't lint-trip on
    // `context.read` across async gaps.
    final state = context.read<PlayerState>();

    // Pull the full set list from the DB — we aggregate across every
    // exercise in a multi-exercise session, not just the one currently on
    // screen.
    final allSets = await SetsService.forWorkout(_workoutId!);
    if (allSets.isEmpty) {
      await WorkoutService.delete(_workoutId!);
      if (!mounted) return;
      context.go(fallbackRoute);
      return;
    }

    final volume = await SetsService.volumeFor(_workoutId!);

    await WorkoutService.finish(
      _workoutId!,
      xpEarned: _sessionXp,
      volumeKg: volume,
    );

    // Fan out to the gameplay engines (rank recompute, streak tick, quest
    // progress, analytics). Summary drives post-session celebration nav.
    final summary = await GameHandlers.onWorkoutFinished(_workoutId!);
    await state.refresh();

    if (!mounted) return;
    // Prefer the strongest celebration this session earned. When routing
    // straight to the workout detail, forward the summary via `extra` so
    // the detail screen can render a one-time quest/PR celebration banner.
    if (summary.leveledUp) {
      context.go('/level-up');
    } else if (summary.streakMilestoneReached) {
      context.go('/streak-milestone');
    } else if (fallbackRoute.startsWith('/workouts/')) {
      context.go(fallbackRoute, extra: summary);
    } else {
      context.go(fallbackRoute);
    }
  }

  String get _elapsed {
    if (_startedAt == null) return '0:00';
    final d = DateTime.now().difference(_startedAt!);
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const ScreenBase(
        child: Center(
          child: CircularProgressIndicator(color: AppPalette.teal),
        ),
      );
    }
    final ex = _exercise!;
    final completedCount = _sets.where((s) => s.state == _SetState.completed).length;
    final hasQueue = _totalExercises > 1;
    final hasNext = _remaining.isNotEmpty;
    final canAdvance = hasNext && completedCount > 0;

    return ScreenBase(
      child: Stack(
        children: [
          Column(
            children: [
              _Header(
                exerciseName: ex.name,
                setsCompleted: completedCount,
                elapsed: _elapsed,
                sessionProgress: hasQueue
                    ? 'EXERCISE ${_exerciseIndex + 1} OF $_totalExercises'
                    : null,
                onClose: () => _finishAndGo('/home'),
                onFinish: () => _finishAndGo('/workouts/$_workoutId'),
              ),
              _StatRow(
                volume: _sets.fold<double>(
                  0,
                  (a, s) => a + ((s.weight ?? 0) * (s.reps ?? 0)),
                ),
                xp: _sessionXp,
                sets: completedCount,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.s5,
                    AppSpace.s4,
                    AppSpace.s5,
                    AppSpace.s6,
                  ),
                  children: [
                    for (final s in _sets)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpace.s3),
                        child: _SetCard(
                          data: s,
                          reps: _reps,
                          weight: _weight,
                          onReps: (v) => setState(() => _reps = v.round()),
                          onWeight: (v) =>
                              setState(() => _weight = v.toDouble()),
                          onComplete: _completeSet,
                        ),
                      ),
                    _AddSetButton(onTap: _addSet),
                    if (hasNext) ...[
                      const SizedBox(height: AppSpace.s4),
                      _NextExerciseButton(
                        enabled: canAdvance,
                        onTap: canAdvance ? _advanceToNextExercise : null,
                      ),
                    ],
                  ],
                ),
              ),
              if (_resting)
                _RestTimerBar(
                  restSec: _restSec,
                  onMinus: () => setState(
                    () => _restSec = (_restSec - 30).clamp(0, 9999),
                  ),
                  onPlus: () => setState(() => _restSec += 30),
                  onSkip: () {
                    _restTimer?.cancel();
                    setState(() {
                      _resting = false;
                      _restSec = 90;
                    });
                  },
                ),
            ],
          ),
          if (_toastKey != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: _resting ? 120 : 80,
              child: Center(
                child: XPToast(
                  key: ValueKey(_toastKey),
                  amount: _sessionXp == 0
                      ? 0
                      : (_exercise?.baseXp ?? 3) * 5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.exerciseName,
    required this.setsCompleted,
    required this.elapsed,
    required this.onClose,
    required this.onFinish,
    this.sessionProgress,
  });

  final String exerciseName;
  final int setsCompleted;
  final String elapsed;
  final VoidCallback onClose;
  final VoidCallback onFinish;

  /// "EXERCISE 2 OF 3" when the logger is walking through a prescribed
  /// multi-exercise session; `null` for a single-exercise entry.
  final String? sessionProgress;

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
            onTap: onClose,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: AppPalette.strokeHairline),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.close,
                color: AppPalette.textSecondary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: AppSpace.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sessionProgress == null
                      ? '$setsCompleted SETS LOGGED · $elapsed'
                      : '$sessionProgress · $setsCompleted SETS · $elapsed',
                  style: AppType.label(
                    color: sessionProgress == null
                        ? AppPalette.textMuted
                        : AppPalette.teal,
                  ).copyWith(fontSize: 10),
                ),
                Text(
                  exerciseName.toUpperCase(),
                  style: AppType.displayMD(color: AppPalette.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GhostButton(label: 'FINISH', onTap: onFinish),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.volume,
    required this.xp,
    required this.sets,
  });
  final double volume;
  final int xp;
  final int sets;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('VOLUME', '${volume.round()} kg'),
      ('SESSION XP', '+$xp'),
      ('SETS', '$sets'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.s5,
        AppSpace.s4,
        AppSpace.s5,
        0,
      ),
      child: Row(
        children: items.asMap().entries.map((e) {
          final isLast = e.key == items.length - 1;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: isLast ? 0 : AppSpace.s3),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppPalette.carbon,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppPalette.strokeHairline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.value.$1,
                      style: AppType.label(color: AppPalette.textMuted)
                          .copyWith(fontSize: 9),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      e.value.$2,
                      style: AppType.monoMD(color: AppPalette.textPrimary),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SetCard extends StatelessWidget {
  const _SetCard({
    required this.data,
    required this.reps,
    required this.weight,
    required this.onReps,
    required this.onWeight,
    required this.onComplete,
  });

  final _SetData data;
  final int reps;
  final double weight;
  final ValueChanged<num> onReps;
  final ValueChanged<num> onWeight;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    if (data.state == _SetState.completed) {
      return Container(
        padding: const EdgeInsets.all(AppSpace.s4),
        decoration: BoxDecoration(
          color: AppPalette.carbon,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppPalette.green.withValues(alpha: 0.33)),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppPalette.green.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: AppPalette.green, size: 16),
            ),
            const SizedBox(width: AppSpace.s4),
            Text('#${data.n}',
                style: AppType.monoMD(color: AppPalette.textPrimary)),
            const SizedBox(width: AppSpace.s4),
            Expanded(
              child: Text(
                '${data.reps} reps × ${data.weight} kg',
                style: AppType.bodyMD(color: AppPalette.textPrimary),
              ),
            ),
          ],
        ),
      );
    }

    return NeonCard(
      glow: GlowColor.purple,
      padding: const EdgeInsets.all(AppSpace.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('#${data.n}',
                  style: AppType.monoMD(color: AppPalette.purple)),
              const SizedBox(width: AppSpace.s3),
              Text('ACTIVE SET',
                  style: AppType.label(color: AppPalette.purple)),
            ],
          ),
          const SizedBox(height: AppSpace.s4),
          Row(
            children: [
              Expanded(
                child: NumericStepper(
                  value: weight,
                  step: 2.5,
                  label: 'WEIGHT',
                  unit: 'kg',
                  onChanged: onWeight,
                ),
              ),
              const SizedBox(width: AppSpace.s3),
              Expanded(
                child: NumericStepper(
                  value: reps,
                  label: 'REPS',
                  onChanged: onReps,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s4),
          PrimaryButton(
            label: 'COMPLETE SET',
            size: AppButtonSize.md,
            onTap: onComplete,
          ),
        ],
      ),
    );
  }
}

class _AddSetButton extends StatelessWidget {
  const _AddSetButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: AppPalette.strokeSubtle),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Text(
          '+ ADD SET',
          style: AppType.label(color: AppPalette.textSecondary),
        ),
      ),
    );
  }
}

class _NextExerciseButton extends StatelessWidget {
  const _NextExerciseButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? AppPalette.teal : AppPalette.textMuted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: enabled
              ? [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 12)]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              enabled ? 'NEXT EXERCISE' : 'LOG A SET FIRST',
              style: AppType.label(color: color),
            ),
            if (enabled) ...[
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward, color: color, size: 16),
            ],
          ],
        ),
      ),
    );
  }
}

class _RestTimerBar extends StatelessWidget {
  const _RestTimerBar({
    required this.restSec,
    required this.onMinus,
    required this.onPlus,
    required this.onSkip,
  });

  final int restSec;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final progress = ((90 - restSec) / 90).clamp(0.0, 1.0);
    final mm = (restSec ~/ 60).toString();
    final ss = (restSec % 60).toString().padLeft(2, '0');

    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: AppPalette.carbon,
        border: Border(top: BorderSide(color: AppPalette.strokeHairline)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      AppPalette.teal.withValues(alpha: 0.2),
                      AppPalette.purple.withValues(alpha: 0.2),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _MiniBtn(label: '-30s', onTap: onMinus),
                const SizedBox(width: AppSpace.s3),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'REST',
                        style: AppType.label(color: AppPalette.textMuted)
                            .copyWith(fontSize: 9),
                      ),
                      Text(
                        '$mm:$ss',
                        style: AppType.monoLG(color: AppPalette.textPrimary)
                            .copyWith(fontSize: 22),
                      ),
                    ],
                  ),
                ),
                _MiniBtn(label: 'SKIP', onTap: onSkip),
                const SizedBox(width: AppSpace.s3),
                _MiniBtn(label: '+30s', onTap: onPlus),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBtn extends StatelessWidget {
  const _MiniBtn({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: AppPalette.strokeSubtle),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: AppType.label(color: AppPalette.textPrimary).copyWith(
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}
