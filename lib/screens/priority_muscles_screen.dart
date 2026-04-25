import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/services/goals_service.dart';
import '../theme/tokens.dart';
import '../widgets/onboarding_radio_tile.dart';
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
    ('chest', 'Chest'),
    ('back', 'Back'),
    ('shoulders', 'Shoulders'),
    ('biceps', 'Biceps'),
    ('triceps', 'Triceps'),
    ('core', 'Core/Abs'),
    ('quads', 'Quads'),
    ('hamstrings', 'Hamstrings'),
    ('glutes', 'Glutes'),
    ('calves', 'Calves'),
  ];

  void _toggle(String key) {
    final list = List<String>.from(_selected);
    if (list.contains(key)) {
      list.remove(key);
    } else if (list.length < _cap) {
      list.add(key);
    } else {
      return;
    }
    setState(() => _selected = list);
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      section: OnboardingSection.objectives,
      percent: 30,
      subtitle: 'Prioritising target muscle groups…',
      title: 'Pick up to 3 muscle groups.',
      nextEnabled: _selected.isNotEmpty,
      onBack: () => context.go('/body-type'),
      onNext: _save,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: [
              for (final o in _options)
                OnboardingChip(
                  label: o.$2,
                  selected: _selected.contains(o.$1),
                  disabled: !_selected.contains(o.$1) &&
                      _selected.length >= _cap,
                  onTap: () => _toggle(o.$1),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${_selected.length} / $_cap selected · weighted 1.5× in rank math',
            style: AppType.system(color: AppPalette.textMuted),
          ),
        ],
      ),
    );
  }
}
