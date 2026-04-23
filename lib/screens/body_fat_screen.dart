import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/services/player_service.dart';
import '../state/player_state.dart';
import '../theme/tokens.dart';
import '../widgets/big_slider.dart';
import '../widgets/neon_card.dart';
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
      percent: 57,
      kicker: 'PHYSICAL ATTRIBUTES',
      subtitle: '…estimating composition. (not medical advice)',
      onBack: () => context.go('/weight-direction'),
      onNext: _save,
      child: NeonCard(
        glow: GlowColor.teal,
        padding: const EdgeInsets.all(AppSpace.s6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estimate your\nbody fat',
              style: AppType.displayLG(color: AppPalette.textPrimary),
            ),
            const SizedBox(height: AppSpace.s5),
            Center(
              child: SizedBox(
                height: 160,
                width: 140,
                child: PlaceholderBlock(
                  label: _labels[_stop]!,
                  height: 160,
                  color: AppPalette.teal,
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
              themeColor: AppPalette.teal,
              onChanged: (v) => setState(() => _stop = v.round()),
            ),
            const SizedBox(height: AppSpace.s3),
            Text(
              '> key: ${_keys[_stop]}',
              style: AppType.system(color: AppPalette.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
