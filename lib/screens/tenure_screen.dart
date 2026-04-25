import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/services/experience_service.dart';
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
    ('beginner', 'Complete Beginner', 'First time training'),
    ('starting', 'Just Starting Out', 'Under 6 months'),
    ('some', 'Some Experience', '6 months – 1 year'),
    ('experienced', 'Experienced', '1–3 years consistent'),
  ];

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      section: OnboardingSection.experience,
      percent: 42,
      subtitle: 'Estimating prior training payload…',
      title: 'Years under the bar:',
      onBack: () => context.go('/calibrating/2'),
      onNext: _save,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final o in _options)
            OnboardingRadioTile(
              label: o.$2,
              subtitle: o.$3,
              selected: _value == o.$1,
              onTap: () => setState(() => _value = o.$1),
            ),
        ],
      ),
    );
  }
}
