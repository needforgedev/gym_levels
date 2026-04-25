import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/services/goals_service.dart';
import '../widgets/onboarding_radio_tile.dart';
import '../widgets/onboarding_scaffold.dart';
import '../widgets/progress_header.dart';

/// PRD §8 Section 2 Screen 8 — reward style radio. Tunes notification copy.
class RewardStyleScreen extends StatefulWidget {
  const RewardStyleScreen({super.key});

  @override
  State<RewardStyleScreen> createState() => _RewardStyleScreenState();
}

class _RewardStyleScreenState extends State<RewardStyleScreen> {
  String? _value;

  @override
  void initState() {
    super.initState();
    GoalsService.get().then((g) {
      if (mounted && g?.rewardStyle != null) {
        setState(() => _value = g!.rewardStyle);
      }
    });
  }

  Future<void> _save() async {
    if (_value == null) return;
    await GoalsService.patch(rewardStyle: _value);
    if (!mounted) return;
    context.go('/calibrating/2');
  }

  static const _options = [
    ('achievements', 'Achievements & Badges', Icons.emoji_events),
    ('leveling', 'Leveling Up & Ranks', Icons.star),
    ('streaks', 'Daily Streaks', Icons.local_fire_department),
    ('challenges', 'Completing Challenges', Icons.gps_fixed),
  ];

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      section: OnboardingSection.objectives,
      percent: 36,
      subtitle: 'Calibrating reward protocol…',
      title: 'What excites you most?',
      nextEnabled: _value != null,
      onBack: () => context.go('/priority-muscles'),
      onNext: _save,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final o in _options)
            OnboardingRadioTile(
              label: o.$2,
              icon: Icon(o.$3),
              selected: _value == o.$1,
              onTap: () => setState(() => _value = o.$1),
            ),
        ],
      ),
    );
  }
}
