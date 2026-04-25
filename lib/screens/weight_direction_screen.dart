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
    ('gain', 'Gain', 'Bulk up, build mass'),
    ('lose', 'Lose', 'Cut, reveal the work'),
    ('maintain', 'Maintain', 'Hold steady, get stronger'),
  ];

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      section: OnboardingSection.attributes,
      percent: 72,
      subtitle: 'Setting mass objective…',
      title: 'Target weight goal?',
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
              selected: _value == o.$1,
              onTap: () => setState(() => _value = o.$1),
            ),
        ],
      ),
    );
  }
}
