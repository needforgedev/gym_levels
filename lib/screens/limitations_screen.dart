import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/services/experience_service.dart';
import '../theme/tokens.dart';
import '../widgets/chips.dart';
import '../widgets/neon_card.dart';
import '../widgets/onboarding_scaffold.dart';
import '../widgets/progress_header.dart';

/// PRD §8 Section 3 Screen 11 — injury/limitation multi-select.
/// Rule: "None" is exclusive (selecting it clears the others; selecting any
/// other clears "None").
class LimitationsScreen extends StatefulWidget {
  const LimitationsScreen({super.key});

  @override
  State<LimitationsScreen> createState() => _LimitationsScreenState();
}

class _LimitationsScreenState extends State<LimitationsScreen> {
  List<String> _selected = ['none'];

  static const _none = 'none';

  @override
  void initState() {
    super.initState();
    ExperienceService.get().then((e) {
      if (mounted && e != null && e.limitations.isNotEmpty) {
        setState(() => _selected = List.of(e.limitations));
      }
    });
  }

  Future<void> _save() async {
    if (_selected.isEmpty) return;
    await ExperienceService.patch(limitations: _selected);
    if (!mounted) return;
    context.go('/training-styles');
  }

  static const _options = [
    ChipOption(value: _none, label: 'NONE'),
    ChipOption(value: 'lower_back', label: 'LOWER BACK'),
    ChipOption(value: 'knee', label: 'KNEE'),
    ChipOption(value: 'shoulder', label: 'SHOULDER'),
    ChipOption(value: 'wrist_elbow', label: 'WRIST / ELBOW'),
    ChipOption(value: 'hip', label: 'HIP'),
    ChipOption(value: 'neck', label: 'NECK'),
    ChipOption(value: 'other_joint', label: 'OTHER JOINT'),
    ChipOption(value: 'chronic', label: 'CHRONIC CONDITION'),
  ];

  void _onChanged(Object? v) {
    final next = List<String>.from(v as List);
    // Selecting `none` clears everything else; selecting any other removes `none`.
    if (next.contains(_none) && !_selected.contains(_none)) {
      setState(() => _selected = [_none]);
    } else if (next.length > 1 && next.contains(_none)) {
      setState(() => _selected = next.where((e) => e != _none).toList());
    } else {
      setState(() => _selected = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      section: OnboardingSection.experience,
      percent: 42,
      kicker: 'COMBAT EXPERIENCE',
      subtitle: '…logging injury history.',
      nextEnabled: _selected.isNotEmpty,
      onBack: () => context.go('/equipment'),
      onNext: _save,
      child: NeonCard(
        glow: GlowColor.yellow,
        padding: const EdgeInsets.all(AppSpace.s6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Any injuries\nor limitations?',
              style: AppType.displayLG(color: AppPalette.textPrimary),
            ),
            const SizedBox(height: AppSpace.s1),
            Text(
              'WE WILL SWAP EXERCISES AROUND THESE.',
              style: AppType.bodySM(color: AppPalette.textMuted),
            ),
            const SizedBox(height: AppSpace.s6),
            AppChipGroup<String>(
              options: _options,
              value: _selected,
              mode: ChipMode.multi,
              themeColor: AppPalette.yellow,
              themeGlow: GlowColor.yellow,
              onChanged: _onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
