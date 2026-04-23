import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/models/notification_prefs.dart';
import '../data/services/notification_prefs_service.dart';
import '../theme/tokens.dart';
import '../widgets/neon_card.dart';
import '../widgets/onboarding_scaffold.dart';
import '../widgets/progress_header.dart';

/// PRD §8 Section 6 Screen 19 — notification toggles (3).
/// All default ON. Triggers OS permission prompt on CONTINUE (wired in
/// Phase 2.5's `NotificationsService`).
class NotificationPrefsScreen extends StatefulWidget {
  const NotificationPrefsScreen({super.key});

  @override
  State<NotificationPrefsScreen> createState() =>
      _NotificationPrefsScreenState();
}

class _NotificationPrefsScreenState extends State<NotificationPrefsScreen> {
  bool _workoutReminders = true;
  bool _streakWarnings = true;
  bool _weeklyReports = true;

  @override
  void initState() {
    super.initState();
    NotificationPrefsService.get().then((p) {
      if (mounted && p != null) {
        setState(() {
          _workoutReminders = p.workoutReminders;
          _streakWarnings = p.streakWarnings;
          _weeklyReports = p.weeklyReports;
        });
      }
    });
  }

  Future<void> _save() async {
    await NotificationPrefsService.upsert(NotificationPrefs(
      workoutReminders: _workoutReminders,
      streakWarnings: _streakWarnings,
      weeklyReports: _weeklyReports,
    ));
    // OS permission prompt lands here in Phase 2.5 via NotificationsService.
    if (!mounted) return;
    context.go('/calibrating/6');
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      section: OnboardingSection.settings,
      percent: 87,
      kicker: 'SYSTEM SETTINGS',
      subtitle: '…configuring broadcast channels.',
      onBack: () => context.go('/calibrating/5'),
      onNext: _save,
      child: NeonCard(
        glow: GlowColor.none,
        padding: const EdgeInsets.all(AppSpace.s6),
        pulse: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Which alerts do\nyou want?',
              style: AppType.displayLG(color: AppPalette.textPrimary),
            ),
            const SizedBox(height: AppSpace.s5),
            _PrefRow(
              label: 'WORKOUT REMINDERS',
              subtitle: 'Nudge ~1h before your typical log time',
              value: _workoutReminders,
              onChanged: (v) => setState(() => _workoutReminders = v),
            ),
            const SizedBox(height: AppSpace.s3),
            _PrefRow(
              label: 'STREAK WARNINGS',
              subtitle: '7pm local on a scheduled day with no log',
              value: _streakWarnings,
              onChanged: (v) => setState(() => _streakWarnings = v),
            ),
            const SizedBox(height: AppSpace.s3),
            _PrefRow(
              label: 'WEEKLY PROGRESS REPORTS',
              subtitle: 'Sunday 8pm recap of rank moves + PRs',
              value: _weeklyReports,
              onChanged: (v) => setState(() => _weeklyReports = v),
            ),
            const SizedBox(height: AppSpace.s4),
            Text(
              '> all notifications are local · no server push.',
              style: AppType.system(color: AppPalette.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrefRow extends StatelessWidget {
  const _PrefRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.s4),
      decoration: BoxDecoration(
        color: AppPalette.slate,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppPalette.strokeSubtle),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppType.label(color: AppPalette.textPrimary)),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppType.bodySM(color: AppPalette.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.s3),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppPalette.obsidian,
            activeTrackColor: AppPalette.teal,
            inactiveThumbColor: AppPalette.textMuted,
            inactiveTrackColor: AppPalette.slate,
          ),
        ],
      ),
    );
  }
}
