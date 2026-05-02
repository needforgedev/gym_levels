import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/services/player_service.dart';
import '../state/player_state.dart';
import '../theme/tokens.dart';
import '../widgets/big_slider.dart';
import '../widgets/onboarding_scaffold.dart';

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
      percent: 18,
      subtitle: 'Measuring spatial dimensions…',
      title: 'Height measurement:',
      onBack: () => context.go('/age'),
      onNext: _save,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Pill-style unit toggle (matches design's CM / FT-IN switch).
          Center(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: AppPalette.purple.withValues(alpha: 0.10),
                border: Border.all(
                  color: AppPalette.purple.withValues(alpha: 0.20),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final (key, label) in const [
                    ('cm', 'CM'),
                    ('ft-in', 'FT/IN'),
                  ])
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => setState(() => _unit = key),
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            color: _unit == key
                                ? AppPalette.amber.withValues(alpha: 0.25)
                                : Colors.transparent,
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                              color: _unit == key
                                  ? AppPalette.amber
                                  : AppPalette.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          BigSlider(
            value: _cm,
            min: 140,
            max: 220,
            divisions: 80,
            unit: _unit == 'cm' ? 'cm' : _imperialLabel(),
            onChanged: (v) => setState(() => _cm = v),
          ),
        ],
      ),
    );
  }
}
