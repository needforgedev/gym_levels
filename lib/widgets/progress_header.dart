import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import 'progress_bar.dart';

enum OnboardingSection { registration, objectives, experience, attributes, operations, settings }

Color sectionAccent(OnboardingSection s) {
  switch (s) {
    case OnboardingSection.registration:
    case OnboardingSection.attributes:
      return AppPalette.teal;
    case OnboardingSection.objectives:
      return AppPalette.purple;
    case OnboardingSection.experience:
      return AppPalette.yellow;
    case OnboardingSection.operations:
      return AppPalette.green;
    case OnboardingSection.settings:
      return AppPalette.white;
  }
}

String sectionKicker(OnboardingSection s) {
  switch (s) {
    case OnboardingSection.registration:
      return 'PLAYER REGISTRATION';
    case OnboardingSection.objectives:
      return 'MISSION OBJECTIVES';
    case OnboardingSection.experience:
      return 'COMBAT EXPERIENCE';
    case OnboardingSection.attributes:
      return 'PHYSICAL ATTRIBUTES';
    case OnboardingSection.operations:
      return 'DAILY OPERATIONS';
    case OnboardingSection.settings:
      return 'SYSTEM SETTINGS';
  }
}

class ProgressHeader extends StatelessWidget {
  const ProgressHeader({
    super.key,
    required this.section,
    this.label,
    required this.percent,
    this.subtitle,
  });

  final OnboardingSection section;
  final String? label;
  final double percent; // 0-100
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final color = sectionAccent(section);
    final kicker = label ?? sectionKicker(section);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(kicker, style: AppType.displaySM(color: color)),
              Text('${percent.round()}%', style: AppType.monoMD(color: color)),
            ],
          ),
          const SizedBox(height: AppSpace.s3),
          Bar(percent: percent, color: color, height: 2, glowOn: true),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpace.s3),
            Text(subtitle!, style: AppType.system(color: AppPalette.textSecondary)),
          ],
        ],
      ),
    );
  }
}
