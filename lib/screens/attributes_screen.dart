import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/tokens.dart';
import '../widgets/neon_card.dart';
import '../widgets/numeric_stepper.dart';
import '../widgets/onboarding_scaffold.dart';
import '../widgets/progress_header.dart';
import '../widgets/segmented_toggle.dart';

class AttributesScreen extends StatefulWidget {
  const AttributesScreen({super.key});

  @override
  State<AttributesScreen> createState() => _AttributesScreenState();
}

class _AttributesScreenState extends State<AttributesScreen> {
  int _age = 27;
  int _weight = 78;
  int _height = 178;
  String _unit = 'metric';

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      section: OnboardingSection.attributes,
      percent: 75,
      kicker: 'PHYSICAL ATTRIBUTES',
      subtitle: '…recording baseline physical metrics.',
      onBack: () => context.go('/experience'),
      onNext: () => context.go('/loader-pre-home'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NeonCard(
            glow: GlowColor.teal,
            padding: const EdgeInsets.all(AppSpace.s6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Baseline\nmetrics',
                  style: AppType.displayLG(color: AppPalette.textPrimary),
                ),
                const SizedBox(height: AppSpace.s4),
                SegmentedToggle<String>(
                  options: const [
                    SegmentOption(value: 'metric', label: 'METRIC'),
                    SegmentOption(value: 'imperial', label: 'IMPERIAL'),
                  ],
                  value: _unit,
                  onChanged: (v) => setState(() => _unit = v),
                ),
                const SizedBox(height: AppSpace.s5),
                Row(
                  children: [
                    Expanded(
                      child: NumericStepper(
                        value: _age,
                        label: 'AGE',
                        unit: 'yrs',
                        onChanged: (v) => setState(() => _age = v.round()),
                      ),
                    ),
                    const SizedBox(width: AppSpace.s3),
                    Expanded(
                      child: NumericStepper(
                        value: _weight,
                        label: 'WEIGHT',
                        unit: _unit == 'metric' ? 'kg' : 'lb',
                        onChanged: (v) => setState(() => _weight = v.round()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.s3),
                NumericStepper(
                  value: _height,
                  label: 'HEIGHT',
                  unit: _unit == 'metric' ? 'cm' : 'in',
                  onChanged: (v) => setState(() => _height = v.round()),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.s4),
          NeonCard(
            glow: GlowColor.none,
            padding: const EdgeInsets.all(AppSpace.s4),
            pulse: false,
            child: Text(
              '> biometric packet queued for transmission…',
              style: AppType.system(color: AppPalette.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
