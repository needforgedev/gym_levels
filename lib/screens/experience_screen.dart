import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/tokens.dart';
import '../widgets/neon_card.dart';
import '../widgets/onboarding_scaffold.dart';
import '../widgets/progress_header.dart';

class ExperienceScreen extends StatefulWidget {
  const ExperienceScreen({super.key});

  @override
  State<ExperienceScreen> createState() => _ExperienceScreenState();
}

class _ExperienceScreenState extends State<ExperienceScreen> {
  String _value = 'intermediate';

  static const _options = [
    ('rookie', 'ROOKIE — 0-6 MONTHS'),
    ('intermediate', 'INTERMEDIATE — 6-24 MONTHS'),
    ('veteran', 'VETERAN — 2-5 YEARS'),
    ('master', 'MASTER — 5+ YEARS'),
  ];

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      section: OnboardingSection.experience,
      percent: 55,
      kicker: 'COMBAT EXPERIENCE',
      subtitle: '…estimating prior training payload.',
      onBack: () => context.go('/objectives'),
      onNext: () => context.go('/attributes'),
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
                child: _OptionTile(
                  label: o.$2,
                  selected: _value == o.$1,
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

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? AppPalette.yellow.withValues(alpha: 0.12)
                : AppPalette.slate,
            border: Border.all(
              color: selected ? AppPalette.yellow : AppPalette.strokeSubtle,
            ),
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppPalette.yellow.withValues(alpha: 0.4),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppType.label(
                    color: selected
                        ? AppPalette.yellow
                        : AppPalette.textPrimary,
                  ),
                ),
              ),
              if (selected)
                const Icon(Icons.check, color: AppPalette.yellow, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
