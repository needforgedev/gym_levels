import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/services/goals_service.dart';
import '../theme/tokens.dart';
import '../widgets/neon_card.dart';
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
    ('achievements', 'ACHIEVEMENTS & BADGES', 'Show me the trophies'),
    ('leveling', 'LEVELING UP & RANKS', 'Climb the ladder'),
    ('streaks', 'DAILY STREAKS', 'Never break the chain'),
    ('challenges', 'COMPLETING CHALLENGES', 'Give me bosses to fight'),
  ];

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      section: OnboardingSection.objectives,
      percent: 25,
      kicker: 'MISSION OBJECTIVES',
      subtitle: '…calibrating reward protocol.',
      nextEnabled: _value != null,
      onBack: () => context.go('/priority-muscles'),
      onNext: _save,
      child: NeonCard(
        glow: GlowColor.purple,
        padding: const EdgeInsets.all(AppSpace.s6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What rewards\nexcite you most?',
              style: AppType.displayLG(color: AppPalette.textPrimary),
            ),
            const SizedBox(height: AppSpace.s6),
            ..._options.map(
              (o) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.s3),
                child: OnboardingRadioTile(
                  label: o.$2,
                  subtitle: o.$3,
                  selected: _value == o.$1,
                  themeColor: AppPalette.purple,
                  onTap: () => setState(() => _value = o.$1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
