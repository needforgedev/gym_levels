import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import 'buttons.dart';
import 'progress_header.dart';
import 'screen_base.dart';

/// Shared onboarding scaffold — header + scrollable body + back/continue bar.
class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    super.key,
    required this.section,
    required this.percent,
    this.kicker,
    this.subtitle,
    required this.onBack,
    required this.onNext,
    this.nextEnabled = true,
    required this.child,
  });

  final OnboardingSection section;
  final double percent;
  final String? kicker;
  final String? subtitle;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final bool nextEnabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ScreenBase(
      background: AppPalette.obsidian,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.s6,
          AppSpace.s5,
          AppSpace.s6,
          AppSpace.s6,
        ),
        child: Column(
          children: [
            ProgressHeader(
              section: section,
              label: kicker,
              percent: percent,
              subtitle: subtitle,
            ),
            const SizedBox(height: AppSpace.s6),
            Expanded(
              child: SingleChildScrollView(child: child),
            ),
            const SizedBox(height: AppSpace.s4),
            Row(
              children: [
                Expanded(
                  flex: 4,
                  child: SecondaryButton(label: 'BACK', onTap: onBack),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 6,
                  child: Opacity(
                    opacity: nextEnabled ? 1 : 0.4,
                    child: IgnorePointer(
                      ignoring: !nextEnabled,
                      child: PrimaryButton(label: 'CONTINUE', onTap: onNext),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
