import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/services/player_service.dart';
import '../state/player_state.dart';
import '../theme/tokens.dart';
import '../widgets/big_slider.dart';
import '../widgets/onboarding_scaffold.dart';
import '../widgets/placeholder_block.dart';
import '../widgets/progress_header.dart';

/// PRD §8 Section 4 Screen 16 — body fat estimate slider.
/// PRD calls for a "morphing avatar". v1 MVP uses a PlaceholderBlock that
/// re-labels by the selected stop; commissioned avatars come with the art
/// pass in Phase 3.
class BodyFatScreen extends StatefulWidget {
  const BodyFatScreen({super.key});

  @override
  State<BodyFatScreen> createState() => _BodyFatScreenState();
}

class _BodyFatScreenState extends State<BodyFatScreen> {
  int _stop = 2; // 1..4

  static const _labels = <int, String>{
    1: 'VERY LEAN',
    2: 'LEAN',
    3: 'AVERAGE',
    4: 'ABOVE AVERAGE',
  };

  static const _keys = <int, String>{
    1: 'very_lean',
    2: 'lean',
    3: 'average',
    4: 'above',
  };

  static const _reverseKeys = <String, int>{
    'very_lean': 1,
    'lean': 2,
    'average': 3,
    'above': 4,
  };

  @override
  void initState() {
    super.initState();
    final existing = context.read<PlayerState>().player?.bodyFatEstimate;
    final mapped = _reverseKeys[existing];
    if (mapped != null) _stop = mapped;
  }

  Future<void> _save() async {
    final state = context.read<PlayerState>();
    await PlayerService.patch(bodyFatEstimate: _keys[_stop]);
    await state.refresh();
    if (!mounted) return;
    context.go('/calibrating/4');
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      section: OnboardingSection.attributes,
      percent: 84,
      subtitle: 'Estimating composition (not medical advice)…',
      title: 'Estimate your body fat:',
      onBack: () => context.go('/weight-direction'),
      onNext: _save,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: SizedBox(
              height: 180,
              width: 160,
              child: PlaceholderBlock(
                label: _labels[_stop]!,
                height: 180,
                color: AppPalette.amber,
              ),
            ),
          ),
          const SizedBox(height: AppSpace.s5),
          BigSlider(
            value: _stop.toDouble(),
            min: 1,
            max: 4,
            divisions: 3,
            label: _labels[_stop],
            onChanged: (v) => setState(() => _stop = v.round()),
          ),
        ],
      ),
    );
  }
}
