import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/services/schedule_service.dart';
import '../state/player_state.dart';
import '../widgets/onboarding_radio_tile.dart';
import '../widgets/onboarding_scaffold.dart';
import '../widgets/progress_header.dart';

/// PRD §8 Section 5 Screen 18 — session length radio.
class SessionMinutesScreen extends StatefulWidget {
  const SessionMinutesScreen({super.key});

  @override
  State<SessionMinutesScreen> createState() => _SessionMinutesScreenState();
}

class _SessionMinutesScreenState extends State<SessionMinutesScreen> {
  int? _minutes;

  @override
  void initState() {
    super.initState();
    ScheduleService.get().then((s) {
      if (mounted && s?.sessionMinutes != null) {
        setState(() => _minutes = s!.sessionMinutes);
      }
    });
  }

  Future<void> _save() async {
    if (_minutes == null) return;
    final onboarded = context.read<PlayerState>().isOnboarded;
    await ScheduleService.patch(sessionMinutes: _minutes);
    if (!mounted) return;
    context.go(onboarded ? '/home' : '/calibrating/5');
  }

  static const _options = [
    (15, '15 – 30 min', 'Quick session'),
    (30, '30 – 45 min', 'Standard session'),
    (45, '45 – 60 min', 'Long session'),
    (60, '60 – 90 min', 'Extended session'),
  ];

  @override
  Widget build(BuildContext context) {
    final onboarded = context.watch<PlayerState>().isOnboarded;
    return OnboardingScaffold(
      section: OnboardingSection.operations,
      percent: 95,
      subtitle: 'Sizing session window…',
      title: 'How long are your typical workouts?',
      nextEnabled: _minutes != null,
      onBack: () => context.go(onboarded ? '/home' : '/training-days'),
      onNext: _save,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final o in _options)
            OnboardingRadioTile(
              label: o.$2,
              subtitle: o.$3,
              selected: _minutes == o.$1,
              onTap: () => setState(() => _minutes = o.$1),
            ),
        ],
      ),
    );
  }
}
