import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/tokens.dart';
import '../widgets/chips.dart';
import '../widgets/neon_card.dart';
import '../widgets/onboarding_scaffold.dart';
import '../widgets/progress_header.dart';

class ObjectivesScreen extends StatefulWidget {
  const ObjectivesScreen({super.key});

  @override
  State<ObjectivesScreen> createState() => _ObjectivesScreenState();
}

class _ObjectivesScreenState extends State<ObjectivesScreen> {
  List<String> _selected = ['build_muscle'];

  static const _options = [
    ChipOption(value: 'build_muscle', label: 'BUILD MUSCLE'),
    ChipOption(value: 'lose_fat', label: 'LOSE FAT'),
    ChipOption(value: 'strength', label: 'GAIN STRENGTH'),
    ChipOption(value: 'endurance', label: 'ENDURANCE'),
    ChipOption(value: 'consistency', label: 'CONSISTENCY'),
    ChipOption(value: 'mobility', label: 'MOBILITY'),
  ];

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      section: OnboardingSection.objectives,
      percent: 35,
      kicker: 'MISSION OBJECTIVES',
      subtitle: '…define primary combat doctrine.',
      nextEnabled: _selected.isNotEmpty,
      onBack: () => context.go('/'),
      onNext: () => context.go('/experience'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NeonCard(
            glow: GlowColor.purple,
            padding: const EdgeInsets.all(AppSpace.s6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select your\nobjectives',
                  style: AppType.displayLG(color: AppPalette.textPrimary),
                ),
                const SizedBox(height: AppSpace.s1),
                Text(
                  'PICK UP TO 3 — THESE SHAPE YOUR QUESTS',
                  style: AppType.bodySM(color: AppPalette.textMuted),
                ),
                const SizedBox(height: AppSpace.s6),
                AppChipGroup<String>(
                  options: _options,
                  value: _selected,
                  mode: ChipMode.multi,
                  themeColor: AppPalette.purple,
                  themeGlow: GlowColor.purple,
                  onChanged: (v) =>
                      setState(() => _selected = List<String>.from(v as List)),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.s5),
          NeonCard(
            glow: GlowColor.none,
            padding: const EdgeInsets.all(AppSpace.s4),
            pulse: false,
            child: Text(
              '> selected: ${_selected.length} / 3',
              style: AppType.system(color: AppPalette.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
