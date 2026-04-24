import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/models/workout.dart';
import '../data/models/workout_set.dart';
import '../data/services/exercise_service.dart';
import '../data/services/sets_service.dart';
import '../data/services/workout_service.dart';
import '../game/game_handlers.dart';
import '../theme/tokens.dart';
import '../widgets/buttons.dart';
import '../widgets/neon_card.dart';
import '../widgets/screen_base.dart';
import '../widgets/system_header.dart';

class _DetailBundle {
  const _DetailBundle({
    required this.workout,
    required this.sets,
    required this.exerciseNames,
  });
  final Workout workout;
  final List<WorkoutSet> sets;
  final Map<int, String> exerciseNames;
}

/// Read-only detail of a finished workout. Shows per-set rows + aggregate
/// stats. "Delete" cascades via FK.
///
/// When navigated-to straight from a finished session, the `justFinished`
/// summary drives a one-time celebration banner at the top of the screen
/// (quests completed, quest-XP folded in, PRs hit). Navigating back and
/// re-entering without the `extra` clears the banner — it's a "just now"
/// moment, not persistent state.
class WorkoutDetailScreen extends StatefulWidget {
  const WorkoutDetailScreen({
    super.key,
    required this.workoutId,
    this.justFinished,
  });

  final int workoutId;
  final SessionSummary? justFinished;

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  late Future<_DetailBundle?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_DetailBundle?> _load() async {
    final w = await WorkoutService.byId(widget.workoutId);
    if (w == null) return null;
    final sets = await SetsService.forWorkout(widget.workoutId);
    final exIds = sets.map((s) => s.exerciseId).toSet();
    final names = <int, String>{};
    for (final id in exIds) {
      final ex = await ExerciseService.byId(id);
      if (ex != null) names[id] = ex.name;
    }
    return _DetailBundle(workout: w, sets: sets, exerciseNames: names);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppPalette.carbon,
        title: Text(
          'Delete this workout?',
          style: AppType.displaySM(color: AppPalette.textPrimary),
        ),
        content: Text(
          'This removes the session and every logged set. The catalog is not affected.',
          style: AppType.bodyMD(color: AppPalette.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('CANCEL',
                style: AppType.label(color: AppPalette.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('DELETE',
                style: AppType.label(color: AppPalette.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await WorkoutService.delete(widget.workoutId);
    if (!mounted) return;
    context.go('/workouts');
  }

  @override
  Widget build(BuildContext context) {
    return ScreenBase(
      child: FutureBuilder<_DetailBundle?>(
        future: _future,
        builder: (ctx, snap) {
          if (!snap.hasData && snap.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: AppPalette.teal),
            );
          }
          final bundle = snap.data;
          if (bundle == null) return const _NotFound();

          final w = bundle.workout;
          final sets = bundle.sets;
          final prCount = sets.where((s) => s.isPr).length;
          final summary = widget.justFinished;

          return Column(
            children: [
              _Header(onBack: () => context.go('/workouts')),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpace.s5),
                  children: [
                    if (summary != null) ...[
                      _CelebrationBanner(
                        summary: summary,
                        prCount: prCount,
                      ),
                      const SizedBox(height: AppSpace.s4),
                    ],
                    _SummaryCard(workout: w, setCount: sets.length),
                    const SizedBox(height: AppSpace.s5),
                    Text(
                      'SETS',
                      style: AppType.label(color: AppPalette.textMuted),
                    ),
                    const SizedBox(height: AppSpace.s3),
                    if (sets.isEmpty)
                      Text(
                        '> no sets recorded.',
                        style: AppType.system(color: AppPalette.textMuted),
                      ),
                    for (final s in sets)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpace.s3),
                        child: _SetRow(
                          set: s,
                          exerciseName: bundle.exerciseNames[s.exerciseId] ??
                              'Exercise #${s.exerciseId}',
                        ),
                      ),
                    const SizedBox(height: AppSpace.s6),
                    SecondaryButton(
                      label: 'RETURN HOME',
                      onTap: () => context.go('/home'),
                    ),
                    const SizedBox(height: AppSpace.s3),
                    _DeleteButton(onTap: _delete),
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
                  kicker: 'SESSION',
                  color: AppPalette.teal,
                ),
                const SizedBox(height: 2),
                Text('WORKOUT',
                    style: AppType.displayMD(color: AppPalette.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.workout, required this.setCount});
  final Workout workout;
  final int setCount;

  @override
  Widget build(BuildContext context) {
    final started = DateTime.fromMillisecondsSinceEpoch(
        workout.startedAt * 1000);
    final duration = workout.duration;
    return NeonCard(
      glow: GlowColor.teal,
      pulse: false,
      padding: const EdgeInsets.all(AppSpace.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${started.year}-${_dd(started.month)}-${_dd(started.day)} · ${_dd(started.hour)}:${_dd(started.minute)}',
            style: AppType.label(color: AppPalette.textMuted),
          ),
          const SizedBox(height: AppSpace.s4),
          Row(
            children: [
              _Stat(label: 'SETS', value: '$setCount'),
              const SizedBox(width: AppSpace.s5),
              _Stat(label: 'VOLUME', value: '${workout.volumeKg.round()} kg'),
              const SizedBox(width: AppSpace.s5),
              _Stat(label: 'DURATION', value: '${duration.inMinutes} min'),
            ],
          ),
          const SizedBox(height: AppSpace.s4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppPalette.xpGold.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppPalette.xpGold),
            ),
            child: Text(
              '+${workout.xpEarned} XP',
              style: AppType.monoMD(color: AppPalette.xpGold),
            ),
          ),
        ],
      ),
    );
  }

  String _dd(int n) => n.toString().padLeft(2, '0');
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppType.label(color: AppPalette.textMuted)
                .copyWith(fontSize: 9)),
        Text(value, style: AppType.monoMD(color: AppPalette.textPrimary)),
      ],
    );
  }
}

class _SetRow extends StatelessWidget {
  const _SetRow({required this.set, required this.exerciseName});
  final WorkoutSet set;
  final String exerciseName;

  @override
  Widget build(BuildContext context) {
    final weight = set.weightKg ?? 0;
    return Container(
      padding: const EdgeInsets.all(AppSpace.s4),
      decoration: BoxDecoration(
        color: AppPalette.carbon,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppPalette.strokeHairline),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text('#${set.setNumber}',
                style: AppType.monoMD(color: AppPalette.textMuted)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exerciseName,
                    style: AppType.bodyMD(color: AppPalette.textPrimary)),
                Text(
                  '${set.reps} reps × ${weight == weight.roundToDouble() ? weight.round() : weight.toStringAsFixed(1)} kg',
                  style: AppType.bodySM(color: AppPalette.textMuted),
                ),
              ],
            ),
          ),
          if (set.isPr)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppPalette.xpGold.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppPalette.xpGold),
              ),
              child: Text('PR',
                  style: AppType.label(color: AppPalette.xpGold)
                      .copyWith(fontSize: 9)),
            ),
        ],
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      label: 'DELETE WORKOUT',
      onTap: onTap,
      background: AppPalette.danger,
      foreground: AppPalette.white,
      glow: GlowColor.flame,
    );
  }
}

/// One-time banner rendered at the top of the detail screen right after a
/// session finishes. Summarizes quest completions, quest-XP folded in, and
/// PR count. Hidden on subsequent visits to the same workout.
class _CelebrationBanner extends StatelessWidget {
  const _CelebrationBanner({
    required this.summary,
    required this.prCount,
  });

  final SessionSummary summary;
  final int prCount;

  @override
  Widget build(BuildContext context) {
    final questCount = summary.completedQuests.length;
    final questXp = summary.questXpAwarded;
    final streakGained = summary.streakAfter > summary.streakBefore;

    final parts = <({IconData icon, Color color, String text})>[];
    if (questCount > 0) {
      parts.add((
        icon: Icons.check_circle,
        color: AppPalette.green,
        text: questCount == 1
            ? '1 QUEST · +$questXp XP'
            : '$questCount QUESTS · +$questXp XP',
      ));
    }
    if (prCount > 0) {
      parts.add((
        icon: Icons.emoji_events,
        color: AppPalette.xpGold,
        text: prCount == 1 ? '1 NEW PR · +25 XP' : '$prCount NEW PRS',
      ));
    }
    if (streakGained) {
      parts.add((
        icon: Icons.local_fire_department,
        color: AppPalette.flame,
        text: 'STREAK · ${summary.streakAfter} DAYS',
      ));
    }

    // Nothing worth celebrating — skip the banner entirely so we don't show
    // a green card for a ho-hum session.
    if (parts.isEmpty) return const SizedBox.shrink();

    return NeonCard(
      glow: GlowColor.green,
      padding: const EdgeInsets.all(AppSpace.s4),
      pulse: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SESSION COMPLETE',
            style: AppType.label(color: AppPalette.green),
          ),
          const SizedBox(height: 4),
          Text(
            parts.length == 1
                ? 'One highlight from this session:'
                : 'Highlights from this session:',
            style: AppType.bodySM(color: AppPalette.textSecondary),
          ),
          const SizedBox(height: AppSpace.s3),
          for (final p in parts) ...[
            Row(
              children: [
                Icon(p.icon, color: p.color, size: 16),
                const SizedBox(width: 8),
                Text(p.text, style: AppType.label(color: p.color)),
              ],
            ),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.s7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('> workout not found',
                style: AppType.monoMD(color: AppPalette.textMuted)),
            const SizedBox(height: AppSpace.s4),
            PrimaryButton(
              label: 'BACK TO HISTORY',
              onTap: () => context.go('/workouts'),
            ),
          ],
        ),
      ),
    );
  }
}
