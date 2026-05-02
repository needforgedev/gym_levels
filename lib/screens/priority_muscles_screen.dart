import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/services/goals_service.dart';
import '../theme/tokens.dart';
import '../widgets/onboarding_radio_tile.dart';
import '../widgets/onboarding_scaffold.dart';

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
      subtitle: 'Prioritizing target zones…',
      title: 'Select up to 3 muscle groups to prioritize:',
      nextEnabled: _selected.isNotEmpty,
      onBack: () => context.go('/body-type'),
      onNext: _save,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Centered "X / 3 SELECTED" header — amber when any picked,
          // muted otherwise. Matches design v2 onboarding-questions.jsx.
          Center(
            child: Text(
              '${_selected.length} / $_cap SELECTED',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: _selected.isEmpty
                    ? AppPalette.textMuted
                    : AppPalette.amber,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
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
        ],
      ),
    );
  }
}
