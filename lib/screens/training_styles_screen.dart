import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/services/experience_service.dart';
import '../widgets/onboarding_radio_tile.dart';
import '../widgets/onboarding_scaffold.dart';

/// PRD §8 Section 3 Screen 12 — training styles multi-select.
class TrainingStylesScreen extends StatefulWidget {
  const TrainingStylesScreen({super.key});

  @override
  State<TrainingStylesScreen> createState() => _TrainingStylesScreenState();
}

class _TrainingStylesScreenState extends State<TrainingStylesScreen> {
  List<String> _selected = [];

  @override
  void initState() {
    super.initState();
    ExperienceService.get().then((e) {
      if (mounted && e != null && e.styles.isNotEmpty) {
        setState(() => _selected = List.of(e.styles));
      }
    });
  }

  Future<void> _save() async {
    await ExperienceService.patch(styles: _selected);
    if (!mounted) return;
    context.go('/calibrating/3');
  }

  static const _options = [
    ('weightlifting', 'Weightlifting'),
    ('powerlifting', 'Powerlifting'),
    ('crossfit', 'CrossFit'),
    ('calisthenics', 'Calisthenics'),
    ('hiit', 'HIIT/Cardio'),
    ('never', 'Never trained formally'),
  ];

  void _toggle(String key) {
    final list = List<String>.from(_selected);
    if (list.contains(key)) {
      list.remove(key);
    } else {
      list.add(key);
    }
    setState(() => _selected = list);
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      section: OnboardingSection.experience,
      percent: 60,
      subtitle: 'Cross-referencing disciplines…',
      title: 'What training styles have you tried before?',
      onBack: () => context.go('/limitations'),
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
