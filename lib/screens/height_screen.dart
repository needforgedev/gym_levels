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

/// PRD §8 Section 1 Screen 5 — height slider + CM/FT-IN toggle.
class HeightScreen extends StatefulWidget {
  const HeightScreen({super.key});

  @override
  State<HeightScreen> createState() => _HeightScreenState();
}

class _HeightScreenState extends State<HeightScreen> {
  double _cm = 175;
  String _unit = 'cm';

  @override
  void initState() {
    super.initState();
    final existing = context.read<PlayerState>().player?.heightCm;
    if (existing != null && existing >= 130) _cm = existing;
  }

  Future<void> _save() async {
    final state = context.read<PlayerState>();
    await PlayerService.patch(heightCm: _cm);
    await state.refresh();
    if (!mounted) return;
    context.go('/calibrating/1');
  }

  String _imperialLabel() {
    final totalInches = (_cm / 2.54).round();
    final feet = totalInches ~/ 12;
    final inches = totalInches % 12;
    return "$feet' $inches\"";
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      section: OnboardingSection.registration,
      percent: 10,
      kicker: 'PLAYER REGISTRATION',
      subtitle: '…measuring frame.',
      onBack: () => context.go('/age'),
      onNext: _save,
      child: NeonCard(
        glow: GlowColor.teal,
        padding: const EdgeInsets.all(AppSpace.s6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Height\nmeasurement',
              style: AppType.displayLG(color: AppPalette.textPrimary),
            ),
            const SizedBox(height: AppSpace.s5),
            SegmentedToggle<String>(
              options: const [
                SegmentOption(value: 'cm', label: 'CM'),
                SegmentOption(value: 'ft-in', label: 'FT / IN'),
              ],
              value: _unit,
              onChanged: (v) => setState(() => _unit = v),
            ),
            const SizedBox(height: AppSpace.s6),
            if (_unit == 'cm')
              BigSlider(
                value: _cm,
                min: 130,
                max: 220,
                divisions: 90,
                unit: 'cm',
                themeColor: AppPalette.teal,
                onChanged: (v) => setState(() => _cm = v),
              )
            else
              Column(
                children: [
                  Center(
                    child: Text(
                      _imperialLabel(),
                      style: AppType.monoXL(color: AppPalette.teal).copyWith(
                        fontSize: 72,
                        height: 1,
                        shadows: [
                          Shadow(
                            color: AppPalette.teal.withValues(alpha: 0.5),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpace.s5),
                  Slider(
                    value: _cm.clamp(130, 220),
                    min: 130,
                    max: 220,
                    divisions: 90,
                    activeColor: AppPalette.teal,
                    inactiveColor: AppPalette.slate,
                    onChanged: (v) => setState(() => _cm = v),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
