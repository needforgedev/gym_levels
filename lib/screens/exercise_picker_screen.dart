import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/models/exercise.dart';
import '../data/services/exercise_service.dart';
import '../theme/tokens.dart';
import '../widgets/neon_card.dart';
import '../widgets/screen_base.dart';
import '../widgets/system_header.dart';

/// Pick one exercise to start logging against. Entry point for real workout
/// sessions until the plan generator lands in Phase 2.
class ExercisePickerScreen extends StatefulWidget {
  const ExercisePickerScreen({super.key});

  @override
  State<ExercisePickerScreen> createState() => _ExercisePickerScreenState();
}

class _ExercisePickerScreenState extends State<ExercisePickerScreen> {
  late Future<List<Exercise>> _future;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = ExerciseService.getAll();
  }

  void _start(Exercise e) {
    context.go('/workout/new/${e.id}');
  }

  Map<String, List<Exercise>> _group(List<Exercise> list) {
    final grouped = <String, List<Exercise>>{};
    for (final e in list) {
      grouped.putIfAbsent(e.primaryMuscle, () => []).add(e);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return ScreenBase(
      child: Column(
        children: [
          _Header(onBack: () => context.go('/home')),
          _SearchBar(
            value: _query,
            onChanged: (v) => setState(() => _query = v),
          ),
          Expanded(
            child: FutureBuilder<List<Exercise>>(
              future: _future,
              builder: (ctx, snap) {
                if (!snap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppPalette.teal,
                    ),
                  );
                }
                final all = snap.data!;
                final filtered = _query.isEmpty
                    ? all
                    : all
                        .where((e) => e.name
                            .toLowerCase()
                            .contains(_query.toLowerCase()))
                        .toList();
                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      '> no exercises matched "$_query"',
                      style: AppType.system(color: AppPalette.textMuted),
                    ),
                  );
                }
                final grouped = _group(filtered);
                final items = <Widget>[];
                for (final entry in grouped.entries) {
                  items.add(_MuscleHeader(muscle: entry.key));
                  for (final e in entry.value) {
                    items.add(_ExerciseTile(
                      exercise: e,
                      onTap: () => _start(e),
                    ));
                  }
                  items.add(const SizedBox(height: AppSpace.s4));
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.s5,
                    AppSpace.s3,
                    AppSpace.s5,
                    AppSpace.s6,
                  ),
                  children: items,
                );
              },
            ),
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
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: AppPalette.textSecondary,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: AppSpace.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SystemHeader(
                  kicker: 'SELECT EXERCISE',
                  color: AppPalette.teal,
                ),
                const SizedBox(height: 2),
                Text(
                  'PICK YOUR LIFT',
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

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.s5,
        AppSpace.s4,
        AppSpace.s5,
        0,
      ),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppPalette.slate,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppPalette.strokeSubtle),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: AppPalette.textMuted, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                onChanged: onChanged,
                cursorColor: AppPalette.teal,
                style: AppType.bodyMD(color: AppPalette.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search 80 exercises…',
                  hintStyle: AppType.bodyMD(color: AppPalette.textMuted),
                  border: InputBorder.none,
                  isCollapsed: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MuscleHeader extends StatelessWidget {
  const _MuscleHeader({required this.muscle});
  final String muscle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpace.s5,
        bottom: AppSpace.s3,
      ),
      child: Text(
        muscle.toUpperCase(),
        style: AppType.label(color: AppPalette.teal).copyWith(
          letterSpacing: 2,
        ),
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile({required this.exercise, required this.onTap});
  final Exercise exercise;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isCompound = exercise.baseXp >= 5;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s3),
      child: NeonCard(
        glow: GlowColor.none,
        pulse: false,
        padding: const EdgeInsets.all(AppSpace.s4),
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (isCompound ? AppPalette.teal : AppPalette.purple)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isCompound ? AppPalette.teal : AppPalette.purple,
                ),
              ),
              child: Center(
                child: Text(
                  '${exercise.baseXp}',
                  style: AppType.monoMD(
                    color: isCompound ? AppPalette.teal : AppPalette.purple,
                  ),
                ),
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
                  const SizedBox(height: 2),
                  Text(
                    exercise.equipment.isEmpty
                        ? 'bodyweight'
                        : exercise.equipment.join(' · '),
                    style: AppType.bodySM(color: AppPalette.textMuted),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppPalette.textMuted,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}
