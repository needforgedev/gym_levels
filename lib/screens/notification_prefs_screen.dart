import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/models/notification_prefs.dart';
import '../data/services/notification_prefs_service.dart';
import '../theme/tokens.dart';
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
      percent: 100,
      subtitle: 'Configuring alert channels…',
      title: 'Which notifications would you like?',
      onBack: () => context.go('/calibrating/5'),
      onNext: _save,
      continueLabel: 'FINALIZE SETUP',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PrefRow(
            label: 'Workout Reminders',
            subtitle: 'Nudge 1hr before your usual time',
            value: _workoutReminders,
            onChanged: (v) => setState(() => _workoutReminders = v),
          ),
          const SizedBox(height: 10),
          _PrefRow(
            label: 'Streak Warnings',
            subtitle: 'Alert before your streak breaks',
            value: _streakWarnings,
            onChanged: (v) => setState(() => _streakWarnings = v),
          ),
          const SizedBox(height: 10),
          _PrefRow(
            label: 'Weekly Progress Reports',
            subtitle: 'Sunday summary of gains',
            value: _weeklyReports,
            onChanged: (v) => setState(() => _weeklyReports = v),
          ),
        ],
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
        color: value
            ? AppPalette.amber.withValues(alpha: 0.06)
            : AppPalette.bgCard.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value
              ? AppPalette.amber.withValues(alpha: 0.40)
              : AppPalette.purple.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppPalette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.s3),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppPalette.voidBg,
            activeTrackColor: AppPalette.amber,
            inactiveThumbColor: AppPalette.textMuted,
            inactiveTrackColor: AppPalette.purple.withValues(alpha: 0.15),
          ),
        ],
      ),
    );
  }
}
