import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/models/exercise.dart';
import '../data/models/workout.dart';
import '../data/models/workout_set.dart';
import '../data/services/exercise_service.dart';
import '../data/services/sets_service.dart';
import '../data/services/workout_service.dart';
import '../game/game_handlers.dart';
import '../theme/tokens.dart';
import '../widgets/muscle_body.dart';
import '../widgets/screen_base.dart';

/// Workout Complete summary screen — matches design v2
/// (`screens-workout.jsx` `WorkoutCompleteScreen`).
///
/// Shown straight after the logger's Finish button. Lays out:
///   • "Workout Complete! 🎉" headline + "You crushed it." subtitle.
///   • Total Volume card with big number + violet dumbbell graphic.
///   • Duration + Calories 2-up.
///   • Exercise Breakdown card with painted front/back body silhouettes
///     showing muscle activation + per-muscle intensity chips.
///   • XP Earned banner with "+XP" + "New PRs" count.
///   • BACK TO HOME secondary button.
///
/// Receives the `SessionSummary` via go_router `extra`. The workout id
/// is passed as a path param so we can re-fetch sets if needed.
class WorkoutCompleteScreen extends StatefulWidget {
  const WorkoutCompleteScreen({
    super.key,
    required this.workoutId,
    this.summary,
  });

  final int workoutId;
  final SessionSummary? summary;

  @override
  State<WorkoutCompleteScreen> createState() => _WorkoutCompleteScreenState();
}

class _Bundle {
  const _Bundle({
    required this.workout,
    required this.sets,
    required this.muscleSplit,
    required this.breakdown,
    required this.prCount,
  });
  final Workout workout;
  final List<WorkoutSet> sets;
  final List<({String muscle, int pct})> muscleSplit;
  final List<_ExerciseSummary> breakdown;
  final int prCount;
}

class _ExerciseSummary {
  const _ExerciseSummary({
    required this.exercise,
    required this.sets,
    required this.volumeKg,
    required this.xp,
    required this.avgRpe,
  });
  final Exercise exercise;
  final List<WorkoutSet> sets;
  final double volumeKg;
  final int xp;
  final double? avgRpe;
}

class _WorkoutCompleteScreenState extends State<WorkoutCompleteScreen> {
  late Future<_Bundle?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_Bundle?> _load() async {
    final w = await WorkoutService.byId(widget.workoutId);
    if (w == null) return null;
    final sets = await SetsService.forWorkout(widget.workoutId);

    // Cache exercises so we hit the DB once per unique id.
    final exCache = <int, Exercise?>{};
    Future<Exercise?> exFor(int id) async {
      if (exCache.containsKey(id)) return exCache[id];
      final ex = await ExerciseService.byId(id);
      exCache[id] = ex;
      return ex;
    }

    // Per-primary-muscle volume share for the breakdown card.
    final perMuscle = <String, double>{};
    var totalVol = 0.0;
    var prs = 0;
    for (final s in sets) {
      if (s.isPr) prs += 1;
      final ex = await exFor(s.exerciseId);
      final v = (s.weightKg ?? 0) * s.reps;
      totalVol += v;
      final m = ex?.primaryMuscle ?? 'other';
      perMuscle[m] = (perMuscle[m] ?? 0) + v;
    }

    final split = <({String muscle, int pct})>[];
    if (totalVol > 0) {
      final entries = perMuscle.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (final e in entries.take(3)) {
        split.add((
          muscle: e.key,
          pct: ((e.value / totalVol) * 100).round(),
        ));
      }
    }

    // Per-exercise breakdown — preserves the order in which each exercise
    // was first logged.
    final order = <int>[];
    final byExercise = <int, List<WorkoutSet>>{};
    for (final s in sets) {
      if (!byExercise.containsKey(s.exerciseId)) order.add(s.exerciseId);
      byExercise.putIfAbsent(s.exerciseId, () => []).add(s);
    }
    final breakdown = <_ExerciseSummary>[];
    for (final id in order) {
      final ex = await exFor(id);
      if (ex == null) continue;
      final exSets = byExercise[id]!;
      final volume = exSets.fold<double>(
        0,
        (sum, s) => sum + (s.weightKg ?? 0) * s.reps,
      );
      final xp = exSets.fold<int>(0, (sum, s) => sum + s.xpEarned);
      final rpes = exSets
          .where((s) => s.rpe != null)
          .map((s) => s.rpe!)
          .toList();
      final avgRpe = rpes.isEmpty
          ? null
          : rpes.reduce((a, b) => a + b) / rpes.length;
      breakdown.add(_ExerciseSummary(
        exercise: ex,
        sets: exSets,
        volumeKg: volume,
        xp: xp,
        avgRpe: avgRpe,
      ));
    }

    return _Bundle(
      workout: w,
      sets: sets,
      muscleSplit: split,
      breakdown: breakdown,
      prCount: prs,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScreenBase(
      background: AppPalette.voidBg,
      child: SafeArea(
        bottom: false,
        child: FutureBuilder<_Bundle?>(
          future: _future,
          builder: (ctx, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(color: AppPalette.purple),
              );
            }
            final bundle = snap.data;
            if (bundle == null) {
              return _NotFound(
                onHome: () => context.go('/home'),
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
              children: [
                const _HeaderBlock(),
                const SizedBox(height: 16),
                _TotalVolumeCard(volumeKg: bundle.workout.volumeKg),
                const SizedBox(height: 12),
                _DurationCaloriesRow(
                  duration: bundle.workout.duration,
                  volumeKg: bundle.workout.volumeKg,
                ),
                const SizedBox(height: 16),
                _ExerciseBreakdownCard(
                  split: bundle.muscleSplit,
                  onViewFull: () => showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (_) => _FullBreakdownSheet(
                      breakdown: bundle.breakdown,
                      totalXp: bundle.workout.xpEarned,
                      prCount: bundle.prCount,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _XpEarnedBanner(
                  xp: bundle.workout.xpEarned,
                  prs: bundle.prCount,
                ),
                const SizedBox(height: 16),
                _BackToHomeButton(onTap: () => context.go('/home')),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─── Header ────────────────────────────────────────────────
class _HeaderBlock extends StatelessWidget {
  const _HeaderBlock();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(4, 0, 4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Workout Complete! ',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: AppPalette.textPrimary,
                  ),
                ),
                TextSpan(
                  text: '🎉',
                  style: TextStyle(fontSize: 26),
                ),
              ],
            ),
          ),
          SizedBox(height: 4),
          Text(
            'You crushed it.',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppPalette.purpleSoft,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Total volume card ────────────────────────────────────
class _TotalVolumeCard extends StatelessWidget {
  const _TotalVolumeCard({required this.volumeKg});
  final double volumeKg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xE61A0F2B), Color(0xE6120A1F)],
        ),
        border: Border.all(
          color: AppPalette.purple.withValues(alpha: 0.20),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Volume',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppPalette.textMuted,
                  ),
                ),
                const SizedBox(height: 10),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: _format(volumeKg.round()),
                        style: const TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                          color: AppPalette.textPrimary,
                          height: 1,
                        ),
                      ),
                      const TextSpan(
                        text: '  kg',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppPalette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Session committed.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppPalette.purpleSoft,
                  ),
                ),
              ],
            ),
          ),
          const _DumbbellGraphic(),
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

class _DumbbellGraphic extends StatelessWidget {
  const _DumbbellGraphic();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      height: 80,
      child: CustomPaint(painter: _DumbbellPainter()),
    );
  }
}

class _DumbbellPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFC4B5FD), AppPalette.purple],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final lighter = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFC4B5FD), AppPalette.purple],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..color = paint.color.withValues(alpha: 0.8);

    // Handle.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(20, 36, 50, 8),
        const Radius.circular(2),
      ),
      paint,
    );
    // Left plates.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(12, 24, 10, 32),
        const Radius.circular(3),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(6, 30, 8, 20),
        const Radius.circular(2),
      ),
      lighter,
    );
    // Right plates.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(68, 24, 10, 32),
        const Radius.circular(3),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(76, 30, 8, 20),
        const Radius.circular(2),
      ),
      lighter,
    );
  }

  @override
  bool shouldRepaint(covariant _DumbbellPainter old) => false;
}

// ─── Duration + Calories row ───────────────────────────────
class _DurationCaloriesRow extends StatelessWidget {
  const _DurationCaloriesRow({
    required this.duration,
    required this.volumeKg,
  });
  final Duration duration;
  final double volumeKg;

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  /// Rough estimate: ~0.05 kcal per kg of volume moved + 5 kcal per minute.
  /// Keep this transparent so users don't think it's a clinical reading.
  int _estimatedKcal() =>
      (volumeKg * 0.05 + duration.inMinutes * 5).round();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.timer_outlined,
            label: 'Duration',
            value: _formatDuration(duration),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            icon: Icons.gps_fixed,
            label: 'Calories',
            value: '${_estimatedKcal()}',
            valueSuffix: ' kcal',
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueSuffix,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? valueSuffix;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppPalette.bgCard.withValues(alpha: 0.7),
        border: Border.all(
          color: AppPalette.purple.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppPalette.textMuted),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppPalette.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppPalette.textPrimary,
                  ),
                ),
                if (valueSuffix != null)
                  TextSpan(
                    text: valueSuffix,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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

// ─── Exercise breakdown card ───────────────────────────────
class _ExerciseBreakdownCard extends StatelessWidget {
  const _ExerciseBreakdownCard({
    required this.split,
    required this.onViewFull,
  });
  final List<({String muscle, int pct})> split;
  final VoidCallback onViewFull;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xF21A0F2B), Color(0xF2120A1F)],
        ),
        border: Border.all(
          color: AppPalette.purple.withValues(alpha: 0.28),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppPalette.purple.withValues(alpha: 0.30),
            blurRadius: 24,
            spreadRadius: -8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Exercise Breakdown',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: AppPalette.purple.withValues(alpha: 0.18),
                  border: Border.all(
                    color: AppPalette.purple.withValues(alpha: 0.40),
                    width: 1,
                  ),
                ),
                child: Text(
                  'MUSCLES HIT · ${split.length}',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: Color(0xFFC4B5FD),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Primary activation zones',
            style: TextStyle(
              fontSize: 11,
              color: AppPalette.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          // Front + Back painted bodies.
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: AppPalette.purple.withValues(alpha: 0.06),
              border: Border.all(
                color: AppPalette.purple.withValues(alpha: 0.18),
                width: 1,
              ),
            ),
            child: _BreakdownBodies(split: split),
          ),
          const SizedBox(height: 14),
          // Muscle intensity chips.
          if (split.isEmpty)
            const Text(
              'No sets logged yet.',
              style: TextStyle(
                fontSize: 12,
                color: AppPalette.textMuted,
              ),
            )
          else
            Row(
              children: [
                for (var i = 0; i < split.length; i++) ...[
                  Expanded(
                    child: _IntensityChip(
                      muscle: split[i].muscle,
                      pct: split[i].pct,
                      high: i < 2,
                    ),
                  ),
                  if (i < split.length - 1) const SizedBox(width: 6),
                ],
              ],
            ),
          const SizedBox(height: 14),
          _ViewFullBreakdownButton(onTap: onViewFull),
        ],
      ),
    );
  }
}

/// Picks one front-view and one back-view muscle from the workout's
/// `muscleSplit` and renders the matching panels side-by-side. If the
/// workout only hit muscles on one side (push day → all front), the
/// other side falls back to a neutral panel selection so the layout
/// stays balanced; the muscle-intensity chips below the figures still
/// carry the real per-muscle activation data.
class _BreakdownBodies extends StatelessWidget {
  const _BreakdownBodies({required this.split});

  final List<({String muscle, int pct})> split;

  @override
  Widget build(BuildContext context) {
    String? frontMuscle;
    String? backMuscle;
    for (final s in split) {
      if (!MuscleBody.has(s.muscle)) continue;
      final view = MuscleBody.viewFor(s.muscle);
      if (view == BodyView.front && frontMuscle == null) {
        frontMuscle = s.muscle;
      } else if (view == BodyView.back && backMuscle == null) {
        backMuscle = s.muscle;
      }
    }

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 2.2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: MuscleBody(muscle: frontMuscle ?? 'core'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: MuscleBody(muscle: backMuscle ?? 'back'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: const [
            Text(
              'FRONT',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: AppPalette.textMuted,
              ),
            ),
            Text(
              'BACK',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: AppPalette.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ViewFullBreakdownButton extends StatelessWidget {
  const _ViewFullBreakdownButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppPalette.purple, AppPalette.purpleSoft],
            ),
            boxShadow: [
              BoxShadow(
                color: AppPalette.purple.withValues(alpha: 0.45),
                blurRadius: 18,
                spreadRadius: -2,
              ),
            ],
          ),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'View Full Breakdown',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 16, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IntensityChip extends StatelessWidget {
  const _IntensityChip({
    required this.muscle,
    required this.pct,
    required this.high,
  });
  final String muscle;
  final int pct;
  final bool high;

  @override
  Widget build(BuildContext context) {
    final bg = AppPalette.purpleSoft.withValues(alpha: high ? 0.18 : 0.08);
    final border =
        AppPalette.purpleSoft.withValues(alpha: high ? 0.45 : 0.25);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: bg,
        border: Border.all(color: border, width: 1),
      ),
      child: Column(
        children: [
          Text(
            muscle.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: Color(0xFFC4B5FD),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$pct%',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFamily: 'JetBrainsMono',
              color: AppPalette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}


// ─── XP earned banner ──────────────────────────────────────
class _XpEarnedBanner extends StatelessWidget {
  const _XpEarnedBanner({required this.xp, required this.prs});
  final int xp;
  final int prs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppPalette.amber.withValues(alpha: 0.20),
            AppPalette.amber.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(
          color: AppPalette.amber.withValues(alpha: 0.40),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppPalette.amber.withValues(alpha: 0.20),
            ),
            child: const Icon(Icons.bolt, size: 22, color: AppPalette.amber),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'XP Earned',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppPalette.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '+ $xp XP',
                  style: TextStyle(
                    fontSize: 28,
                    fontFamily: 'BebasNeue',
                    height: 1,
                    color: AppPalette.amber,
                    shadows: [
                      Shadow(
                        color: AppPalette.amber.withValues(alpha: 0.5),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'New PRs',
                style: TextStyle(
                  fontSize: 11,
                  color: AppPalette.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$prs',
                style: const TextStyle(
                  fontSize: 22,
                  fontFamily: 'BebasNeue',
                  color: AppPalette.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Bottom CTA ────────────────────────────────────────────
class _BackToHomeButton extends StatelessWidget {
  const _BackToHomeButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
            color: AppPalette.purple.withValues(alpha: 0.15),
            border: Border.all(
              color: AppPalette.purple.withValues(alpha: 0.40),
              width: 1,
            ),
          ),
          child: const Text(
            'BACK TO HOME',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              fontFamily: 'BebasNeue',
              color: AppPalette.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound({required this.onHome});
  final VoidCallback onHome;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Workout summary unavailable.',
            style: TextStyle(color: AppPalette.textMuted),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onHome, child: const Text('BACK TO HOME')),
        ],
      ),
    );
  }
}

// ─── Full breakdown bottom sheet ───────────────────────────
class _FullBreakdownSheet extends StatelessWidget {
  const _FullBreakdownSheet({
    required this.breakdown,
    required this.totalXp,
    required this.prCount,
  });

  final List<_ExerciseSummary> breakdown;
  final int totalXp;
  final int prCount;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, controller) => Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A0F2B), Color(0xFF0A0612)],
          ),
        ),
        child: Column(
          children: [
            // Drag handle.
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'FULL BREAKDOWN',
                          style: TextStyle(
                            fontSize: 22,
                            fontFamily: 'BebasNeue',
                            letterSpacing: 1,
                            color: AppPalette.textPrimary,
                          ),
                        ),
                        Text(
                          '${breakdown.length} exercise${breakdown.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppPalette.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: AppPalette.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                itemCount: breakdown.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _ExerciseBreakdownRow(s: breakdown[i]),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: _XpEarnedBanner(xp: totalXp, prs: prCount),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseBreakdownRow extends StatelessWidget {
  const _ExerciseBreakdownRow({required this.s});
  final _ExerciseSummary s;

  @override
  Widget build(BuildContext context) {
    final muscles = <String>[
      s.exercise.primaryMuscle,
      ...s.exercise.secondaryMuscles,
    ];
    final musclesLabel = muscles.length <= 3
        ? muscles.join(', ')
        : '${muscles.take(2).join(', ')}, +${muscles.length - 2} more';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppPalette.bgCard.withValues(alpha: 0.85),
        border: Border.all(
          color: AppPalette.purple.withValues(alpha: 0.22),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.exercise.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      musclesLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppPalette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '+${s.xp} XP',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'JetBrainsMono',
                  color: AppPalette.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final set in s.sets) _SetPill(set: set),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MetaText(
                  label: 'Volume',
                  value: '${_formatVolume(s.volumeKg)} kg',
                ),
              ),
              if (s.avgRpe != null)
                _MetaText(
                  label: 'Avg RPE',
                  value: s.avgRpe!.toStringAsFixed(1),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatVolume(double v) {
    final n = v.round();
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

class _SetPill extends StatelessWidget {
  const _SetPill({required this.set});
  final WorkoutSet set;

  @override
  Widget build(BuildContext context) {
    final w = set.weightKg ?? 0;
    final wText = w % 1 == 0 ? w.round().toString() : w.toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: AppPalette.purple.withValues(alpha: 0.15),
        border: Border.all(
          color: AppPalette.purple.withValues(alpha: 0.30),
          width: 1,
        ),
      ),
      child: Text(
        '$wText×${set.reps}',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          fontFamily: 'JetBrainsMono',
          color: AppPalette.purpleSoft,
        ),
      ),
    );
  }
}

class _MetaText extends StatelessWidget {
  const _MetaText({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(
              fontSize: 11,
              color: AppPalette.textMuted,
            ),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              fontFamily: 'JetBrainsMono',
              color: AppPalette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
