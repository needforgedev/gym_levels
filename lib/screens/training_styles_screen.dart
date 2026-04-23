import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/services/experience_service.dart';
import '../theme/tokens.dart';
import '../widgets/chips.dart';
import '../widgets/neon_card.dart';
import '../widgets/onboarding_scaffold.dart';
import '../widgets/progress_header.dart';

/// PRD §8 Section 3 Screen 12 — training styles multi-select.
class TrainingStylesScreen extends StatefulWidget {
  const TrainingStylesScreen({super.key});

  @override
  State<TrainingStylesScreen> createState() => _TrainingStylesScreenState();
}

class _TrainingStylesScreenState extends State<TrainingStylesScreen> {
  List<String> _selected = [];

  @override
  void initState() {
    super.initState();
    ExperienceService.get().then((e) {
      if (mounted && e != null && e.styles.isNotEmpty) {
        setState(() => _selected = List.of(e.styles));
      }
    });
  }

  Future<void> _save() async {
    await ExperienceService.patch(styles: _selected);
    if (!mounted) return;
    context.go('/calibrating/3');
  }

  static const _options = [
    ChipOption(value: 'weightlifting', label: 'WEIGHTLIFTING'),
    ChipOption(value: 'powerlifting', label: 'POWERLIFTING'),
    ChipOption(value: 'crossfit', label: 'CROSSFIT'),
    ChipOption(value: 'calisthenics', label: 'CALISTHENICS'),
    ChipOption(value: 'hiit', label: 'HIIT / CARDIO'),
    ChipOption(value: 'never', label: 'NEVER TRAINED FORMALLY'),
  ];

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      section: OnboardingSection.experience,
      percent: 45,
      kicker: 'COMBAT EXPERIENCE',
      subtitle: '…profiling prior disciplines.',
      onBack: () => context.go('/limitations'),
      onNext: _save,
      child: NeonCard(
        glow: GlowColor.yellow,
        padding: const EdgeInsets.all(AppSpace.s6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Training styles\nyou have tried',
              style: AppType.displayLG(color: AppPalette.textPrimary),
            ),
            const SizedBox(height: AppSpace.s1),
            Text(
              'HELPS US PICK THE RIGHT STARTING INTENSITY.',
              style: AppType.bodySM(color: AppPalette.textMuted),
            ),
            const SizedBox(height: AppSpace.s6),
            AppChipGroup<String>(
              options: _options,
              value: _selected,
              mode: ChipMode.multi,
              themeColor: AppPalette.yellow,
              themeGlow: GlowColor.yellow,
              onChanged: (v) => setState(
                () => _selected = List<String>.from(v as List),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
