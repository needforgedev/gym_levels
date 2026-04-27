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
import '../widgets/screen_base.dart';

/// Live workout logger — matches design v2's logger layout
/// (`design/v2/screens-workout.jsx`). One workout row spans every queued
/// exercise; a session is finalized via the top-right `Finish` button.
///
/// Header: red X (left), elapsed timer chip, VOL kg chip, +XP chip,
/// `Finish` teal text button (right).
///
/// Active set card: amber-bordered glowing card with `EXERCISE n / total`
/// kicker, big exercise name, `SET n` amber pill, vertical WEIGHT/REPS
/// stepper rows, full-width `✓ COMPLETE SET` amber CTA.
///
/// Remaining + Up Next sections show the rest of the planned sets and
/// the next queued exercise.
enum _SetState { active, completed }

class _SetData {
  _SetData({required this.n, required this.state});
  final int n;
  _SetState state;
  double? weight;
  int? reps;
}

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({
    super.key,
    required this.exerciseId,
    this.queue = const [],
  });

  final int exerciseId;

  /// Remaining exercise IDs after the current one. Walked through under a
  /// single workouts row so a 3-exercise prescription tracks as one
  /// session.
  final List<int> queue;

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  static const int _defaultSetCount = 4;
  static const int _defaultReps = 10;
  static const double _defaultWeight = 80;

  Exercise? _exercise;
  Exercise? _nextExercise; // first item in _remaining (if any)
  int? _workoutId;
  bool _loading = true;

  /// All planned sets for the current exercise. The first un-completed
  /// entry is the "active" one shown in the big card. Completed entries
  /// are kept so we can render their logged values if needed (and for the
  /// finalize summary).
  final _sets = <_SetData>[
    for (var i = 1; i <= _defaultSetCount; i++)
      _SetData(n: i, state: _SetState.active),
  ];

  // Active set inputs (mirror the user-edited values for the current set).
  int _reps = _defaultReps;
  double _weight = _defaultWeight;

  bool _resting = false;
  int _restSec = 90;
  Timer? _restTimer;
  Timer? _elapsedTicker;
  int _sessionXp = 0;
  DateTime? _startedAt;

  // Multi-exercise session state.
  late int _currentExerciseId;
  late List<int> _remaining;
  int _exerciseIndex = 0;
  late final int _totalExercises;

  // Live-updated VOL roll-up (sum across all completed sets in this
  // workout, not just the current exercise).
  double _liveVolume = 0;

  @override
  void initState() {
    super.initState();
    _currentExerciseId = widget.exerciseId;
    _remaining = List<int>.from(widget.queue);
    _totalExercises = 1 + widget.queue.length;
    _boot();
    _elapsedTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _boot() async {
    final ex = await ExerciseService.byId(_currentExerciseId);
    if (!mounted) return;
    if (ex == null) {
      context.go('/home');
      return;
    }
    final id = await WorkoutService.start();
    Exercise? next;
    if (_remaining.isNotEmpty) {
      next = await ExerciseService.byId(_remaining.first);
    }
    if (!mounted) return;
    setState(() {
      _exercise = ex;
      _nextExercise = next;
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
    Exercise? following;
    if (_remaining.isNotEmpty) {
      following = await ExerciseService.byId(_remaining.first);
    }
    _restTimer?.cancel();
    setState(() {
      _currentExerciseId = nextId;
      _exercise = ex;
      _nextExercise = following;
      _exerciseIndex += 1;
      _sets
        ..clear()
        ..addAll([
          for (var i = 1; i <= _defaultSetCount; i++)
            _SetData(n: i, state: _SetState.active),
        ]);
      _reps = _defaultReps;
      _weight = _defaultWeight;
      _resting = false;
      _restSec = 90;
    });
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    _elapsedTicker?.cancel();
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

    // PR detection — out-volumes the prior best set?
    final prior = await SetsService.bestFor(_currentExerciseId);
    final priorVolume =
        prior == null ? 0 : (prior.weightKg ?? 0) * prior.reps;
    final thisVolume = _weight * _reps;
    final isPr = prior != null && thisVolume > priorVolume;

    final xpEarned = await GameHandlers.xpForSet(
      exerciseId: _currentExerciseId,
      rpe: null,
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
      _liveVolume += thisVolume;
    });

    context.read<PlayerState>().addXp(xpEarned);
    _startRest();
  }

  void _addSet() {
    setState(() {
      _sets.add(
        _SetData(n: _sets.length + 1, state: _SetState.active),
      );
    });
  }

  Future<void> _finishAndGo(String fallbackRoute) async {
    if (_workoutId == null) {
      if (!mounted) return;
      context.go(fallbackRoute);
      return;
    }
    final state = context.read<PlayerState>();

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
    final summary = await GameHandlers.onWorkoutFinished(_workoutId!);
    await state.refresh();

    if (!mounted) return;
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
          child: CircularProgressIndicator(color: AppPalette.amber),
        ),
      );
    }
    final ex = _exercise!;
    final activeSet = _sets.firstWhere(
      (s) => s.state == _SetState.active,
      orElse: () => _sets.last,
    );
    final remaining = _sets
        .where((s) => s.state == _SetState.active && s != activeSet)
        .toList();
    final hasNext = _remaining.isNotEmpty && _nextExercise != null;
    final completedCount =
        _sets.where((s) => s.state == _SetState.completed).length;
    final allCurrentDone = !_sets.any((s) => s.state == _SetState.active);

    return ScreenBase(
      background: AppPalette.voidBg,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(
              elapsed: _elapsed,
              volumeKg: _liveVolume,
              xp: _sessionXp,
              onClose: () => _finishAndGo('/home'),
              onFinish: () => _finishAndGo('/workouts/$_workoutId'),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  _ActiveSetCard(
                    exerciseName: ex.name,
                    exerciseIndex: _exerciseIndex + 1,
                    totalExercises: _totalExercises,
                    setNumber: activeSet.n,
                    weight: _weight,
                    reps: _reps,
                    onWeightChanged: (v) => setState(() => _weight = v),
                    onRepsChanged: (v) => setState(() => _reps = v),
                    onComplete: allCurrentDone ? null : _completeSet,
                  ),
                  if (allCurrentDone) ...[
                    const SizedBox(height: 16),
                    _AllSetsDoneRow(
                      hasNext: hasNext,
                      onAddSet: _addSet,
                      onNextExercise: _advanceToNextExercise,
                    ),
                  ],
                  if (remaining.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    _SectionLabel(text: 'REMAINING SETS'),
                    const SizedBox(height: 10),
                    for (final s in remaining) ...[
                      _RemainingSetRow(
                        setNumber: s.n,
                        weight: _weight,
                        reps: _reps,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                  if (completedCount > 0) ...[
                    const SizedBox(height: 22),
                    _SectionLabel(
                      text: 'COMPLETED · $completedCount / ${_sets.length}',
                    ),
                    const SizedBox(height: 10),
                    for (final s
                        in _sets.where((s) => s.state == _SetState.completed))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _CompletedSetRow(
                          setNumber: s.n,
                          weight: s.weight ?? 0,
                          reps: s.reps ?? 0,
                        ),
                      ),
                  ],
                  if (hasNext) ...[
                    const SizedBox(height: 22),
                    _SectionLabel(text: 'UP NEXT'),
                    const SizedBox(height: 10),
                    _UpNextCard(
                      name: _nextExercise!.name,
                      remainingCount: _remaining.length,
                      totalCount: _totalExercises,
                      currentIndex: _exerciseIndex + 1,
                    ),
                  ],
                  if (_resting) ...[
                    const SizedBox(height: 22),
                    _RestBar(
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Top header ────────────────────────────────────────────
class _Header extends StatelessWidget {
  const _Header({
    required this.elapsed,
    required this.volumeKg,
    required this.xp,
    required this.onClose,
    required this.onFinish,
  });

  final String elapsed;
  final double volumeKg;
  final int xp;
  final VoidCallback onClose;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          // Red X close button.
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onClose,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppPalette.danger.withValues(alpha: 0.15),
                  border: Border.all(
                    color: AppPalette.danger.withValues(alpha: 0.40),
                    width: 1,
                  ),
                ),
                child: Icon(Icons.close,
                    size: 18, color: AppPalette.danger),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Timer chip.
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _MetricChip(
                  icon: Icons.timer_outlined,
                  text: elapsed,
                  tint: AppPalette.purpleSoft,
                ),
                const SizedBox(width: 6),
                _MetricChip(
                  text: 'VOL ${volumeKg.round()}kg',
                  tint: AppPalette.purpleSoft,
                ),
                const SizedBox(width: 6),
                _MetricChip(
                  text: '+$xp XP',
                  tint: AppPalette.amber,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Finish text button.
          TextButton(
            onPressed: onFinish,
            style: TextButton.styleFrom(
              foregroundColor: AppPalette.teal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            child: const Text(
              'Finish',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.text,
    required this.tint,
    this.icon,
  });

  final String text;
  final Color tint;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: tint.withValues(alpha: 0.13),
        border: Border.all(
          color: tint.withValues(alpha: 0.40),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: tint),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              fontFamily: 'JetBrainsMono',
              color: tint,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Active set card ───────────────────────────────────────
class _ActiveSetCard extends StatelessWidget {
  const _ActiveSetCard({
    required this.exerciseName,
    required this.exerciseIndex,
    required this.totalExercises,
    required this.setNumber,
    required this.weight,
    required this.reps,
    required this.onWeightChanged,
    required this.onRepsChanged,
    required this.onComplete,
  });

  final String exerciseName;
  final int exerciseIndex;
  final int totalExercises;
  final int setNumber;
  final double weight;
  final int reps;
  final ValueChanged<double> onWeightChanged;
  final ValueChanged<int> onRepsChanged;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppPalette.amber.withValues(alpha: 0.10),
            AppPalette.bgCard.withValues(alpha: 0.85),
          ],
        ),
        border: Border.all(
          color: AppPalette.amber.withValues(alpha: 0.55),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppPalette.amber.withValues(alpha: 0.30),
            blurRadius: 24,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top row: kicker + SET pill.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EXERCISE $exerciseIndex / $totalExercises',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: AppPalette.purpleSoft,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      exerciseName.toUpperCase(),
                      style: TextStyle(
                        fontSize: 26,
                        fontFamily: 'BebasNeue',
                        letterSpacing: 1,
                        height: 1,
                        color: AppPalette.textPrimary,
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: AppPalette.amber.withValues(alpha: 0.18),
                      border: Border.all(
                        color: AppPalette.amber.withValues(alpha: 0.50),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'SET $setNumber',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: AppPalette.amber,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: AppPalette.amber.withValues(alpha: 0.20),
                      border: Border.all(
                        color: AppPalette.amber.withValues(alpha: 0.50),
                        width: 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'A',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppPalette.amber,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Weight stepper row.
          _StepperRow(
            label: 'WEIGHT',
            value: weight % 1 == 0
                ? '${weight.round()}'
                : weight.toStringAsFixed(1),
            unit: 'kg',
            onMinus: () =>
                onWeightChanged((weight - 2.5).clamp(0, 1000).toDouble()),
            onPlus: () =>
                onWeightChanged((weight + 2.5).clamp(0, 1000).toDouble()),
          ),
          const SizedBox(height: 16),
          _StepperRow(
            label: 'REPS',
            value: '$reps',
            onMinus: () => onRepsChanged((reps - 1).clamp(0, 999)),
            onPlus: () => onRepsChanged((reps + 1).clamp(0, 999)),
          ),
          const SizedBox(height: 18),
          _CompleteSetButton(onTap: onComplete),
        ],
      ),
    );
  }
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.label,
    required this.value,
    this.unit,
    required this.onMinus,
    required this.onPlus,
  });

  final String label;
  final String value;
  final String? unit;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: AppPalette.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _StepBtn(icon: Icons.remove, onTap: onMinus),
            Expanded(
              child: Center(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: value,
                        style: TextStyle(
                          fontSize: 38,
                          fontFamily: 'BebasNeue',
                          height: 1,
                          color: AppPalette.textPrimary,
                        ),
                      ),
                      if (unit != null)
                        TextSpan(
                          text: ' $unit',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppPalette.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            _StepBtn(icon: Icons.add, onTap: onPlus),
          ],
        ),
      ],
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 56,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: AppPalette.purple.withValues(alpha: 0.15),
            border: Border.all(
              color: AppPalette.purple.withValues(alpha: 0.30),
              width: 1,
            ),
          ),
          child: Icon(icon, size: 20, color: AppPalette.purpleSoft),
        ),
      ),
    );
  }
}

class _CompleteSetButton extends StatelessWidget {
  const _CompleteSetButton({required this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: enabled
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppPalette.amber, AppPalette.amberSoft],
                  )
                : null,
            color: enabled
                ? null
                : AppPalette.amber.withValues(alpha: 0.20),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: AppPalette.amber.withValues(alpha: 0.50),
                      blurRadius: 18,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check, size: 16, color: AppPalette.voidBg),
              const SizedBox(width: 8),
              Text(
                'COMPLETE SET',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: AppPalette.voidBg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Section label ────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
        color: AppPalette.textMuted,
      ),
    );
  }
}

// ─── Remaining set row (dim, planned) ─────────────────────
class _RemainingSetRow extends StatelessWidget {
  const _RemainingSetRow({
    required this.setNumber,
    required this.weight,
    required this.reps,
  });

  final int setNumber;
  final double weight;
  final int reps;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppPalette.bgCard.withValues(alpha: 0.6),
        border: Border.all(
          color: AppPalette.purple.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Set $setNumber',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppPalette.textDim,
              ),
            ),
          ),
          Text(
            '${weight % 1 == 0 ? weight.round() : weight.toStringAsFixed(1)}kg × $reps',
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'JetBrainsMono',
              color: AppPalette.textDim,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Completed set row ─────────────────────────────────────
class _CompletedSetRow extends StatelessWidget {
  const _CompletedSetRow({
    required this.setNumber,
    required this.weight,
    required this.reps,
  });

  final int setNumber;
  final double weight;
  final int reps;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppPalette.success.withValues(alpha: 0.06),
        border: Border.all(
          color: AppPalette.success.withValues(alpha: 0.30),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppPalette.success.withValues(alpha: 0.18),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.check, size: 12, color: AppPalette.success),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Set $setNumber',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppPalette.textPrimary,
              ),
            ),
          ),
          Text(
            '${weight % 1 == 0 ? weight.round() : weight.toStringAsFixed(1)}kg × $reps',
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'JetBrainsMono',
              fontWeight: FontWeight.w700,
              color: AppPalette.success,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Up-Next card ──────────────────────────────────────────
class _UpNextCard extends StatelessWidget {
  const _UpNextCard({
    required this.name,
    required this.remainingCount,
    required this.totalCount,
    required this.currentIndex,
  });

  final String name;
  final int remainingCount;
  final int totalCount;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final progressDone = currentIndex; // 1-based
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppPalette.bgCard.withValues(alpha: 0.85),
        border: Border.all(
          color: AppPalette.purple.withValues(alpha: 0.20),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: AppPalette.purple.withValues(alpha: 0.13),
              border: Border.all(
                color: AppPalette.purple.withValues(alpha: 0.30),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.fitness_center,
              size: 16,
              color: AppPalette.purpleSoft,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppPalette.textPrimary,
              ),
            ),
          ),
          Text(
            '$progressDone/$totalCount',
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'JetBrainsMono',
              fontWeight: FontWeight.w700,
              color: AppPalette.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── All-sets-done row (Add set + Next exercise CTAs) ─────
class _AllSetsDoneRow extends StatelessWidget {
  const _AllSetsDoneRow({
    required this.hasNext,
    required this.onAddSet,
    required this.onNextExercise,
  });

  final bool hasNext;
  final VoidCallback onAddSet;
  final VoidCallback onNextExercise;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SecondaryAction(
            icon: Icons.add,
            label: '+ ADD SET',
            onTap: onAddSet,
          ),
        ),
        if (hasNext) ...[
          const SizedBox(width: 10),
          Expanded(
            child: _SecondaryAction(
              icon: Icons.arrow_forward,
              label: 'NEXT EXERCISE',
              onTap: onNextExercise,
              accent: AppPalette.teal,
            ),
          ),
        ],
      ],
    );
  }
}

class _SecondaryAction extends StatelessWidget {
  const _SecondaryAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.accent = AppPalette.purpleSoft,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: accent.withValues(alpha: 0.10),
            border: Border.all(
              color: accent.withValues(alpha: 0.40),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: accent),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Rest timer ────────────────────────────────────────────
class _RestBar extends StatelessWidget {
  const _RestBar({
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
    final mm = (restSec ~/ 60).toString();
    final ss = (restSec % 60).toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppPalette.teal.withValues(alpha: 0.10),
            AppPalette.purple.withValues(alpha: 0.10),
          ],
        ),
        border: Border.all(
          color: AppPalette.teal.withValues(alpha: 0.30),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _MiniBtn(label: '-30s', onTap: onMinus),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              children: [
                Text(
                  'REST',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: AppPalette.textMuted,
                  ),
                ),
                Text(
                  '$mm:$ss',
                  style: TextStyle(
                    fontSize: 22,
                    fontFamily: 'JetBrainsMono',
                    fontWeight: FontWeight.w700,
                    color: AppPalette.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          _MiniBtn(label: 'SKIP', onTap: onSkip),
          const SizedBox(width: 6),
          _MiniBtn(label: '+30s', onTap: onPlus),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppPalette.purple.withValues(alpha: 0.30),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppPalette.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
