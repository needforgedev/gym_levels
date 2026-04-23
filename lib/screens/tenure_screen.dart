import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/services/experience_service.dart';
import '../theme/tokens.dart';
import '../widgets/neon_card.dart';
import '../widgets/onboarding_radio_tile.dart';
import '../widgets/onboarding_scaffold.dart';
import '../widgets/progress_header.dart';

/// PRD §8 Section 3 Screen 9 — "How long have you been training?".
class TenureScreen extends StatefulWidget {
  const TenureScreen({super.key});

  @override
  State<TenureScreen> createState() => _TenureScreenState();
}

class _TenureScreenState extends State<TenureScreen> {
  String _value = 'starting';

  @override
  void initState() {
    super.initState();
    ExperienceService.get().then((e) {
      if (mounted && e?.tenure != null) {
        setState(() => _value = e!.tenure!);
      }
    });
  }

  Future<void> _save() async {
    await ExperienceService.patch(tenure: _value);
    if (!mounted) return;
    context.go('/equipment');
  }

  static const _options = [
    ('beginner', 'COMPLETE BEGINNER', 'Never trained formally'),
    ('starting', 'JUST STARTING OUT', '0–6 months'),
    ('some', 'SOME EXPERIENCE', '6–24 months'),
    ('experienced', 'EXPERIENCED', '1–3+ years'),
  ];

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      section: OnboardingSection.experience,
      percent: 32,
      kicker: 'COMBAT EXPERIENCE',
      subtitle: '…estimating prior training payload.',
      onBack: () => context.go('/calibrating/2'),
      onNext: _save,
      child: NeonCard(
        glow: GlowColor.yellow,
        padding: const EdgeInsets.all(AppSpace.s6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Years under\nthe bar',
              style: AppType.displayLG(color: AppPalette.textPrimary),
            ),
            const SizedBox(height: AppSpace.s6),
            ..._options.map(
              (o) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.s3),
                child: OnboardingRadioTile(
                  label: o.$2,
                  subtitle: o.$3,
                  selected: _value == o.$1,
                  themeColor: AppPalette.yellow,
                  onTap: () => setState(() => _value = o.$1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
