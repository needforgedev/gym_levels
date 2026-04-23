import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/services/player_service.dart';
import '../state/player_state.dart';
import '../theme/tokens.dart';
import '../widgets/big_slider.dart';
import '../widgets/neon_card.dart';
import '../widgets/onboarding_scaffold.dart';
import '../widgets/progress_header.dart';

/// PRD §8 Section 1 Screen 4 — age slider 16–80.
class AgeScreen extends StatefulWidget {
  const AgeScreen({super.key});

  @override
  State<AgeScreen> createState() => _AgeScreenState();
}

class _AgeScreenState extends State<AgeScreen> {
  double _age = 27;

  @override
  void initState() {
    super.initState();
    final existing = context.read<PlayerState>().player?.age;
    if (existing != null && existing >= 16) {
      _age = existing.toDouble();
    }
  }

  Future<void> _save() async {
    final state = context.read<PlayerState>();
    await PlayerService.patch(age: _age.round());
    await state.refresh();
    if (!mounted) return;
    context.go('/height');
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      section: OnboardingSection.registration,
      percent: 6,
      kicker: 'PLAYER REGISTRATION',
      subtitle: '…scanning biological age.',
      onBack: () => context.go('/register'),
      onNext: _save,
      child: NeonCard(
        glow: GlowColor.teal,
        padding: const EdgeInsets.all(AppSpace.s6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current age\ndetected',
              style: AppType.displayLG(color: AppPalette.textPrimary),
            ),
            const SizedBox(height: AppSpace.s6),
            BigSlider(
              value: _age,
              min: 16,
              max: 80,
              divisions: 64,
              unit: 'yrs',
              themeColor: AppPalette.teal,
              onChanged: (v) => setState(() => _age = v),
            ),
          ],
        ),
      ),
    );
  }
}
