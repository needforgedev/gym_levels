import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/models/workout.dart';
import '../data/services/workout_service.dart';
import '../theme/tokens.dart';
import '../widgets/buttons.dart';
import '../widgets/neon_card.dart';
import '../widgets/screen_base.dart';
import '../widgets/system_header.dart';

String _formatDate(int epochSeconds) {
  final dt = DateTime.fromMillisecondsSinceEpoch(epochSeconds * 1000);
  final now = DateTime.now();
  final days = now.difference(dt).inDays;
  if (days == 0) return 'Today · ${_hm(dt)}';
  if (days == 1) return 'Yesterday · ${_hm(dt)}';
  if (days < 7) return '$days days ago';
  return '${dt.year}-${_dd(dt.month)}-${_dd(dt.day)}';
}

String _hm(DateTime dt) {
  return '${_dd(dt.hour)}:${_dd(dt.minute)}';
}

String _dd(int n) => n.toString().padLeft(2, '0');

/// Workout history — reverse-chronological list of finished sessions.
/// Pull-to-refresh reloads. Swipe a row left to delete (cascades sets).
class WorkoutHistoryScreen extends StatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  late Future<List<Workout>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Workout>> _load() async {
    return (await WorkoutService.recent(limit: 50))
        .where((w) => w.isFinished)
        .toList();
  }

  Future<void> _reload() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _deleteWorkout(Workout w) async {
    if (w.id == null) return;
    await WorkoutService.delete(w.id!);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenBase(
      child: Column(
        children: [
          _Header(onBack: () => context.go('/home')),
          Expanded(
            child: FutureBuilder<List<Workout>>(
              future: _future,
              builder: (ctx, snap) {
                if (!snap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppPalette.teal),
                  );
                }
                final list = snap.data!;
                if (list.isEmpty) return const _EmptyState();
                return RefreshIndicator(
                  color: AppPalette.teal,
                  backgroundColor: AppPalette.carbon,
                  onRefresh: _reload,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpace.s5),
                    itemCount: list.length,
                    itemBuilder: (ctx, i) {
                      final w = list[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpace.s3),
                        child: Dismissible(
                          key: ValueKey('workout-${w.id}'),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (_) => _confirmDelete(context),
                          onDismissed: (_) => _deleteWorkout(w),
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            decoration: BoxDecoration(
                              color: AppPalette.danger.withValues(alpha: 0.3),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.lg),
                            ),
                            child: const Icon(Icons.delete,
                                color: AppPalette.danger),
                          ),
                          child: _WorkoutRow(
                            workout: w,
                            onTap: () => context.go('/workouts/${w.id}'),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
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
        AppSpace.s4,
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
                  kicker: 'WORKOUT LOG',
                  color: AppPalette.teal,
                ),
                const SizedBox(height: 2),
                Text('HISTORY',
                    style: AppType.displayMD(color: AppPalette.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutRow extends StatelessWidget {
  const _WorkoutRow({required this.workout, required this.onTap});
  final Workout workout;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final duration = workout.duration;
    final mins = duration.inMinutes;
    return NeonCard(
      glow: GlowColor.none,
      pulse: false,
      padding: const EdgeInsets.all(AppSpace.s5),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _formatDate(workout.startedAt),
                  style: AppType.label(color: AppPalette.textMuted),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppPalette.xpGold.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppPalette.xpGold),
                ),
                child: Text(
                  '+${workout.xpEarned} XP',
                  style: AppType.monoMD(color: AppPalette.xpGold)
                      .copyWith(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s3),
          Row(
            children: [
              _Stat(label: 'VOLUME', value: '${workout.volumeKg.round()} kg'),
              const SizedBox(width: AppSpace.s5),
              _Stat(label: 'DURATION', value: '$mins min'),
            ],
          ),
        ],
      ),
    );
  }
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.s7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '> no workouts logged',
              style: AppType.monoMD(color: AppPalette.textMuted),
            ),
            const SizedBox(height: AppSpace.s3),
            Text(
              '…awaiting first data packet.',
              style: AppType.system(color: AppPalette.textSecondary),
            ),
            const SizedBox(height: AppSpace.s6),
            PrimaryButton(
              label: 'LOG FIRST WORKOUT',
              onTap: () => context.go('/exercise-picker'),
            ),
          ],
        ),
      ),
    );
  }
}
