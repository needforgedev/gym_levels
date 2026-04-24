import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/services/schedule_service.dart';
import '../state/player_state.dart';
import '../theme/tokens.dart';
import '../widgets/neon_card.dart';
import '../widgets/onboarding_scaffold.dart';
import '../widgets/progress_header.dart';

/// PRD §8 Section 5 Screen 17 — training days.
/// Presets (3 / 5 / every day) auto-tick the 7 day toggles.
/// Validation: ≥2 days required.
class TrainingDaysScreen extends StatefulWidget {
  const TrainingDaysScreen({super.key});

  @override
  State<TrainingDaysScreen> createState() => _TrainingDaysScreenState();
}

class _TrainingDaysScreenState extends State<TrainingDaysScreen> {
  // 0 = Mon, 6 = Sun.
  Set<int> _days = {0, 2, 4};

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  void initState() {
    super.initState();
    ScheduleService.get().then((s) {
      if (mounted && s != null && s.days.isNotEmpty) {
        setState(() => _days = s.days.toSet());
      }
    });
  }

  Future<void> _save() async {
    if (_days.length < 2) return;
    final onboarded = context.read<PlayerState>().isOnboarded;
    await ScheduleService.patch(days: _days.toList()..sort());
    if (!mounted) return;
    context.go(onboarded ? '/home' : '/session-minutes');
  }

  void _applyPreset(String preset) {
    setState(() {
      switch (preset) {
        case '3':
          _days = {0, 2, 4};
        case '5':
          _days = {0, 1, 2, 3, 4};
        case 'every':
          _days = {0, 1, 2, 3, 4, 5, 6};
      }
    });
  }

  void _toggleDay(int i) {
    setState(() {
      if (_days.contains(i)) {
        _days.remove(i);
      } else {
        _days.add(i);
      }
    });
  }

  bool _activePreset(String preset) {
    switch (preset) {
      case '3':
        return _days.length == 3 && _days.containsAll({0, 2, 4});
      case '5':
        return _days.length == 5 && _days.containsAll({0, 1, 2, 3, 4});
      case 'every':
        return _days.length == 7;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final onboarded = context.watch<PlayerState>().isOnboarded;
    return OnboardingScaffold(
      section: OnboardingSection.operations,
      percent: 65,
      kicker: 'DAILY OPERATIONS',
      subtitle: '…locking weekly tempo.',
      nextEnabled: _days.length >= 2,
      onBack: () => context.go(onboarded ? '/home' : '/calibrating/4'),
      onNext: _save,
      child: NeonCard(
        glow: GlowColor.green,
        padding: const EdgeInsets.all(AppSpace.s6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Which days\ncan you train?',
              style: AppType.displayLG(color: AppPalette.textPrimary),
            ),
            const SizedBox(height: AppSpace.s5),
            Row(
              children: [
                _PresetButton(
                  label: '3 DAYS',
                  active: _activePreset('3'),
                  onTap: () => _applyPreset('3'),
                ),
                const SizedBox(width: 8),
                _PresetButton(
                  label: '5 DAYS',
                  active: _activePreset('5'),
                  onTap: () => _applyPreset('5'),
                ),
                const SizedBox(width: 8),
                _PresetButton(
                  label: 'EVERY DAY',
                  active: _activePreset('every'),
                  onTap: () => _applyPreset('every'),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.s5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final on = _days.contains(i);
                return _DayToggle(
                  letter: _dayLabels[i],
                  selected: on,
                  onTap: () => _toggleDay(i),
                );
              }),
            ),
            const SizedBox(height: AppSpace.s4),
            Text(
              '> ${_days.length} / 7 days selected · min 2',
              style: AppType.system(
                color: _days.length >= 2
                    ? AppPalette.textMuted
                    : AppPalette.danger,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetButton extends StatelessWidget {
  const _PresetButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active
                  ? AppPalette.green.withValues(alpha: 0.15)
                  : AppPalette.slate,
              border: Border.all(
                color: active ? AppPalette.green : AppPalette.strokeSubtle,
              ),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Text(
              label,
              style: AppType.label(
                color: active ? AppPalette.green : AppPalette.textSecondary,
              ).copyWith(fontSize: 11),
            ),
          ),
        ),
      ),
    );
  }
}

class _DayToggle extends StatelessWidget {
  const _DayToggle({
    required this.letter,
    required this.selected,
    required this.onTap,
  });

  final String letter;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppPalette.green : AppPalette.slate,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? AppPalette.green : AppPalette.strokeSubtle,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppPalette.green.withValues(alpha: 0.5),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
          child: Text(
            letter,
            style: AppType.label(
              color: selected ? AppPalette.obsidian : AppPalette.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
