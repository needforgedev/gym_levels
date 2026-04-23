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
import '../widgets/segmented_toggle.dart';

/// PRD §8 Section 4 Screen 13 — current body weight slider 30–250 + KG/LBS.
class WeightScreen extends StatefulWidget {
  const WeightScreen({super.key});

  @override
  State<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends State<WeightScreen> {
  double _kg = 78;
  String _unit = 'kg';

  @override
  void initState() {
    super.initState();
    final existing = context.read<PlayerState>().player?.weightKg;
    if (existing != null && existing >= 30) _kg = existing;
  }

  Future<void> _save() async {
    final state = context.read<PlayerState>();
    await PlayerService.patch(weightKg: _kg);
    await state.refresh();
    if (!mounted) return;
    context.go('/weight-direction');
  }

  double get _displayed => _unit == 'kg' ? _kg : _kg * 2.20462;

  void _onSliderChanged(double v) {
    setState(() {
      _kg = _unit == 'kg' ? v : v / 2.20462;
    });
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      section: OnboardingSection.attributes,
      percent: 50,
      kicker: 'PHYSICAL ATTRIBUTES',
      subtitle: '…weighing in.',
      onBack: () => context.go('/calibrating/3'),
      onNext: _save,
      child: NeonCard(
        glow: GlowColor.teal,
        padding: const EdgeInsets.all(AppSpace.s6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current body\nweight',
              style: AppType.displayLG(color: AppPalette.textPrimary),
            ),
            const SizedBox(height: AppSpace.s5),
            SegmentedToggle<String>(
              options: const [
                SegmentOption(value: 'kg', label: 'KG'),
                SegmentOption(value: 'lbs', label: 'LBS'),
              ],
              value: _unit,
              onChanged: (v) => setState(() => _unit = v),
            ),
            const SizedBox(height: AppSpace.s6),
            BigSlider(
              value: _displayed,
              min: _unit == 'kg' ? 30 : 66,
              max: _unit == 'kg' ? 250 : 550,
              divisions: _unit == 'kg' ? 220 : 484,
              unit: _unit,
              themeColor: AppPalette.teal,
              onChanged: _onSliderChanged,
            ),
          ],
        ),
      ),
    );
  }
}
