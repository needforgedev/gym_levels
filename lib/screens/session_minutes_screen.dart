import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/services/schedule_service.dart';
import '../state/player_state.dart';
import '../theme/tokens.dart';
import '../widgets/neon_card.dart';
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
    (15, 'QUICK', '15 – 30 MIN'),
    (30, 'STANDARD', '30 – 45 MIN'),
    (45, 'LONG', '45 – 60 MIN'),
    (60, 'EXTENDED', '60 – 90 MIN'),
  ];

  @override
  Widget build(BuildContext context) {
    final onboarded = context.watch<PlayerState>().isOnboarded;
    return OnboardingScaffold(
      section: OnboardingSection.operations,
      percent: 70,
      kicker: 'DAILY OPERATIONS',
      subtitle: '…sizing session window.',
      nextEnabled: _minutes != null,
      onBack: () => context.go(onboarded ? '/home' : '/training-days'),
      onNext: _save,
      child: NeonCard(
        glow: GlowColor.green,
        padding: const EdgeInsets.all(AppSpace.s6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How long are your\ntypical workouts?',
              style: AppType.displayLG(color: AppPalette.textPrimary),
            ),
            const SizedBox(height: AppSpace.s6),
            ..._options.map(
              (o) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.s3),
                child: OnboardingRadioTile(
                  label: o.$2,
                  subtitle: o.$3,
                  selected: _minutes == o.$1,
                  themeColor: AppPalette.green,
                  onTap: () => setState(() => _minutes = o.$1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
