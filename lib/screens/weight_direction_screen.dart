import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/services/goals_service.dart';
import '../widgets/onboarding_radio_tile.dart';
import '../widgets/onboarding_scaffold.dart';
import '../widgets/progress_header.dart';

/// PRD §8 Section 4 Screen 14 — weight direction radio (Gain / Lose / Maintain).
/// Selecting "Maintain" skips Screen 15 (target weight) in the router flow.
class WeightDirectionScreen extends StatefulWidget {
  const WeightDirectionScreen({super.key});

  @override
  State<WeightDirectionScreen> createState() => _WeightDirectionScreenState();
}

class _WeightDirectionScreenState extends State<WeightDirectionScreen> {
  String? _value;

  @override
  void initState() {
    super.initState();
    GoalsService.get().then((g) {
      if (mounted && g?.weightDirection != null) {
        setState(() => _value = g!.weightDirection);
      }
    });
  }

  Future<void> _save() async {
    if (_value == null) return;
    await GoalsService.patch(weightDirection: _value);
    if (!mounted) return;
    if (_value == 'maintain') {
      context.go('/body-fat');
    } else {
      context.go('/target-weight');
    }
  }

  static const _options = [
    ('gain', 'Gain Weight', 'Build mass and strength', Icons.arrow_upward),
    ('lose', 'Lose Weight', 'Cut body fat', Icons.arrow_downward),
    ('maintain', 'Maintain', 'Stay at current weight', Icons.gps_fixed),
  ];

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      section: OnboardingSection.attributes,
      percent: 72,
      subtitle: 'Setting mission directive…',
      title: 'Do you have a target weight goal?',
      nextEnabled: _value != null,
      onBack: () => context.go('/weight'),
      onNext: _save,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final o in _options)
            OnboardingRadioTile(
              label: o.$2,
              subtitle: o.$3,
              icon: Icon(o.$4),
              selected: _value == o.$1,
              onTap: () => setState(() => _value = o.$1),
            ),
        ],
      ),
    );
  }
}
