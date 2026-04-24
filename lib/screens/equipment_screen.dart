import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/services/experience_service.dart';
import '../state/player_state.dart';
import '../theme/tokens.dart';
import '../widgets/chips.dart';
import '../widgets/neon_card.dart';
import '../widgets/onboarding_scaffold.dart';
import '../widgets/progress_header.dart';

/// PRD §8 Section 3 Screen 10 — equipment multi-select (≥1 required).
class EquipmentScreen extends StatefulWidget {
  const EquipmentScreen({super.key});

  @override
  State<EquipmentScreen> createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends State<EquipmentScreen> {
  List<String> _selected = [];

  @override
  void initState() {
    super.initState();
    ExperienceService.get().then((e) {
      if (mounted && e != null && e.equipment.isNotEmpty) {
        setState(() => _selected = List.of(e.equipment));
      }
    });
  }

  Future<void> _save() async {
    if (_selected.isEmpty) return;
    final onboarded = context.read<PlayerState>().isOnboarded;
    await ExperienceService.patch(equipment: _selected);
    if (!mounted) return;
    context.go(onboarded ? '/home' : '/limitations');
  }

  static const _options = [
    ChipOption(value: 'barbell', label: 'BARBELL & PLATES'),
    ChipOption(value: 'dumbbell', label: 'DUMBBELLS'),
    ChipOption(value: 'kettlebell', label: 'KETTLEBELLS'),
    ChipOption(value: 'resistance_band', label: 'RESISTANCE BANDS'),
    ChipOption(value: 'pullup_bar', label: 'PULL-UP BAR'),
    ChipOption(value: 'cable_machine', label: 'CABLE MACHINE'),
    ChipOption(value: 'bench', label: 'BENCH'),
    ChipOption(value: 'squat_rack', label: 'SQUAT RACK'),
    ChipOption(value: 'bodyweight', label: 'BODYWEIGHT ONLY'),
  ];

  @override
  Widget build(BuildContext context) {
    final onboarded = context.watch<PlayerState>().isOnboarded;
    return OnboardingScaffold(
      section: OnboardingSection.experience,
      percent: 38,
      kicker: 'COMBAT EXPERIENCE',
      subtitle: '…scanning available armoury.',
      nextEnabled: _selected.isNotEmpty,
      onBack: () => context.go(onboarded ? '/home' : '/tenure'),
      onNext: _save,
      child: NeonCard(
        glow: GlowColor.yellow,
        padding: const EdgeInsets.all(AppSpace.s6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What equipment\ndo you have?',
              style: AppType.displayLG(color: AppPalette.textPrimary),
            ),
            const SizedBox(height: AppSpace.s1),
            Text(
              'WE WILL ONLY PRESCRIBE LIFTS YOU CAN ACTUALLY DO.',
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
