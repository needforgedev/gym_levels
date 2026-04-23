import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/services/goals_service.dart';
import '../theme/tokens.dart';
import '../widgets/chips.dart';
import '../widgets/neon_card.dart';
import '../widgets/onboarding_scaffold.dart';
import '../widgets/progress_header.dart';

/// PRD §8 Section 2 Screen 7 — priority muscles (multi-select, cap 3).
class PriorityMusclesScreen extends StatefulWidget {
  const PriorityMusclesScreen({super.key});

  @override
  State<PriorityMusclesScreen> createState() => _PriorityMusclesScreenState();
}

class _PriorityMusclesScreenState extends State<PriorityMusclesScreen> {
  List<String> _selected = [];
  static const _cap = 3;

  @override
  void initState() {
    super.initState();
    GoalsService.get().then((g) {
      if (mounted && g != null && g.priorityMuscles.isNotEmpty) {
        setState(() => _selected = List.of(g.priorityMuscles));
      }
    });
  }

  Future<void> _save() async {
    if (_selected.isEmpty) return;
    await GoalsService.patch(priorityMuscles: _selected);
    if (!mounted) return;
    context.go('/reward-style');
  }

  static const _options = [
    ChipOption(value: 'chest', label: 'CHEST'),
    ChipOption(value: 'back', label: 'BACK'),
    ChipOption(value: 'shoulders', label: 'SHOULDERS'),
    ChipOption(value: 'biceps', label: 'BICEPS'),
    ChipOption(value: 'triceps', label: 'TRICEPS'),
    ChipOption(value: 'core', label: 'CORE / ABS'),
    ChipOption(value: 'quads', label: 'QUADS'),
    ChipOption(value: 'hamstrings', label: 'HAMSTRINGS'),
    ChipOption(value: 'glutes', label: 'GLUTES'),
    ChipOption(value: 'calves', label: 'CALVES'),
  ];

  void _onChanged(Object? v) {
    final list = List<String>.from(v as List);
    if (list.length > _cap) return;
    setState(() => _selected = list);
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      section: OnboardingSection.objectives,
      percent: 20,
      kicker: 'MISSION OBJECTIVES',
      subtitle: '…prioritising target muscle groups.',
      nextEnabled: _selected.isNotEmpty,
      onBack: () => context.go('/body-type'),
      onNext: _save,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NeonCard(
            glow: GlowColor.purple,
            padding: const EdgeInsets.all(AppSpace.s6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pick up to 3\nmuscle groups',
                  style: AppType.displayLG(color: AppPalette.textPrimary),
                ),
                const SizedBox(height: AppSpace.s1),
                Text(
                  'THESE GET WEIGHTED 1.5× IN YOUR RANK MATH.',
                  style: AppType.bodySM(color: AppPalette.textMuted),
                ),
                const SizedBox(height: AppSpace.s6),
                AppChipGroup<String>(
                  options: _options,
                  value: _selected,
                  mode: ChipMode.multi,
                  themeColor: AppPalette.purple,
                  themeGlow: GlowColor.purple,
                  onChanged: _onChanged,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.s4),
          NeonCard(
            glow: GlowColor.none,
            padding: const EdgeInsets.all(AppSpace.s4),
            pulse: false,
            child: Text(
              '> priority slots: ${_selected.length} / $_cap',
              style: AppType.system(color: AppPalette.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
