import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/services/goals_service.dart';
import '../state/player_state.dart';
import '../theme/tokens.dart';
import '../widgets/big_slider.dart';
import '../widgets/onboarding_scaffold.dart';
import '../widgets/progress_header.dart';

/// PRD §8 Section 4 Screen 15 — target weight. Skipped if Maintain.
/// Validation: must differ from the current weight by ≥2kg in the chosen
/// direction.
class TargetWeightScreen extends StatefulWidget {
  const TargetWeightScreen({super.key});

  @override
  State<TargetWeightScreen> createState() => _TargetWeightScreenState();
}

class _TargetWeightScreenState extends State<TargetWeightScreen> {
  double _currentKg = 78;
  String _direction = 'gain';
  double? _target;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _currentKg = context.read<PlayerState>().player?.weightKg ?? 78;
    GoalsService.get().then((g) {
      if (!mounted) return;
      setState(() {
        _direction = g?.weightDirection ?? 'gain';
        _target = g?.targetWeightKg ??
            (_direction == 'lose' ? _currentKg - 5 : _currentKg + 5);
        _loaded = true;
      });
    });
  }

  bool get _valid {
    final t = _target;
    if (t == null) return false;
    final delta = t - _currentKg;
    if (_direction == 'gain') return delta >= 2;
    if (_direction == 'lose') return delta <= -2;
    return true;
  }

  String get _hint {
    final t = _target;
    if (t == null) return '…awaiting input.';
    final delta = t - _currentKg;
    if (_valid) return '…delta: ${delta.toStringAsFixed(1)} kg.';
    final wanted = _direction == 'gain' ? 'above' : 'below';
    return '⚠ target must be ≥2 kg $wanted current.';
  }

  Future<void> _save() async {
    if (!_valid || _target == null) return;
    await GoalsService.patch(targetWeightKg: _target);
    if (!mounted) return;
    context.go('/body-fat');
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      section: OnboardingSection.attributes,
      percent: 78,
      subtitle: 'Locking target mass…',
      title: 'Target body weight:',
      nextEnabled: _valid,
      onBack: () => context.go('/weight-direction'),
      onNext: _save,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CURRENT: ${_currentKg.round()} KG',
            style: AppType.label(color: AppPalette.textMuted),
          ),
          const SizedBox(height: AppSpace.s4),
          if (_loaded && _target != null)
            BigSlider(
              value: _target!,
              min: 30,
              max: 250,
              divisions: 220,
              unit: 'kg',
              onChanged: (v) => setState(() => _target = v),
            )
          else
            const SizedBox(height: 200),
          const SizedBox(height: AppSpace.s3),
          Text(
            _hint,
            style: AppType.system(
              color: _valid ? AppPalette.textMuted : AppPalette.danger,
            ),
          ),
        ],
      ),
    );
  }
}
