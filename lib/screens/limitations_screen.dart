import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/services/experience_service.dart';
import '../widgets/onboarding_radio_tile.dart';
import '../widgets/onboarding_scaffold.dart';

/// PRD §8 Section 3 Screen 11 — injury/limitation multi-select.
/// Rule: "None" is exclusive (selecting it clears the others; selecting any
/// other clears "None").
class LimitationsScreen extends StatefulWidget {
  const LimitationsScreen({super.key});

  @override
  State<LimitationsScreen> createState() => _LimitationsScreenState();
}

class _LimitationsScreenState extends State<LimitationsScreen> {
  List<String> _selected = ['none'];

  static const _none = 'none';

  @override
  void initState() {
    super.initState();
    ExperienceService.get().then((e) {
      if (mounted && e != null && e.limitations.isNotEmpty) {
        setState(() => _selected = List.of(e.limitations));
      }
    });
  }

  Future<void> _save() async {
    if (_selected.isEmpty) return;
    await ExperienceService.patch(limitations: _selected);
    if (!mounted) return;
    // Skip /training-styles — removed from the linear onboarding.
    // /calibrating/3 transitions to Section 4 (physical attrs).
    context.go('/calibrating/3');
  }

  static const _options = [
    (_none, 'None'),
    ('lower_back', 'Lower Back'),
    ('knee', 'Knee'),
    ('shoulder', 'Shoulder'),
    ('wrist_elbow', 'Wrist / Elbow'),
    ('hip', 'Hip'),
    ('neck', 'Neck'),
    ('other_joint', 'Other Joint'),
    ('chronic', 'Chronic Condition'),
  ];

  void _toggle(String key) {
    final list = List<String>.from(_selected);
    if (key == _none) {
      // Selecting `none` clears every other selection.
      setState(() => _selected = [_none]);
      return;
    }
    list.remove(_none);
    if (list.contains(key)) {
      list.remove(key);
    } else {
      list.add(key);
    }
    if (list.isEmpty) list.add(_none);
    setState(() => _selected = list);
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      section: OnboardingSection.experience,
      percent: 54,
      subtitle: 'Mapping constraint flags…',
      title: 'Do you have any injuries or limitations?',
      nextEnabled: _selected.isNotEmpty,
      onBack: () => context.go('/tenure'),
      onNext: _save,
      child: Wrap(
        spacing: 8,
        runSpacing: 10,
        children: [
          for (final o in _options)
            OnboardingChip(
              label: o.$2,
              selected: _selected.contains(o.$1),
              onTap: () => _toggle(o.$1),
            ),
        ],
      ),
    );
  }
}
