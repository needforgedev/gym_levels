import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/services/player_service.dart';
import '../state/player_state.dart';
import '../theme/tokens.dart';
import '../widgets/big_slider.dart';
import '../widgets/onboarding_scaffold.dart';
import '../widgets/progress_header.dart';

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
      percent: 66,
      subtitle: 'Calibrating mass index…',
      title: 'Current body weight:',
      onBack: () => context.go('/calibrating/3'),
      onNext: _save,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: _UnitToggle(unit: _unit, onChanged: (v) => setState(() => _unit = v))),
          const SizedBox(height: 8),
          BigSlider(
            value: _displayed,
            min: _unit == 'kg' ? 30 : 66,
            max: _unit == 'kg' ? 250 : 550,
            divisions: _unit == 'kg' ? 220 : 484,
            unit: _unit,
            onChanged: _onSliderChanged,
          ),
        ],
      ),
    );
  }
}

/// KG / LBS pill toggle — matches design v2's unit selector.
class _UnitToggle extends StatelessWidget {
  const _UnitToggle({required this.unit, required this.onChanged});
  final String unit;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: AppPalette.purple.withValues(alpha: 0.10),
        border: Border.all(color: AppPalette.purple.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (key, label) in const [('kg', 'KG'), ('lbs', 'LBS')])
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onChanged(key),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: unit == key
                        ? AppPalette.amber.withValues(alpha: 0.25)
                        : Colors.transparent,
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: unit == key ? AppPalette.amber : AppPalette.textMuted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
