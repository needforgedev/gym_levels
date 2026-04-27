import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/services/schedule_service.dart';
import '../state/player_state.dart';
import '../theme/tokens.dart';
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
      percent: 90,
      subtitle: 'Scheduling operations…',
      title: 'Which days can you train?',
      nextEnabled: _days.length >= 2,
      onBack: () => context.go(onboarded ? '/home' : '/calibrating/4'),
      onNext: _save,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const SizedBox(height: AppSpace.s6),
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
          Center(
            child: Text(
              _days.length >= 2
                  ? '${_days.length} day${_days.length == 1 ? "" : "s"} selected'
                  : 'pick at least 2 days',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _days.length >= 2
                    ? AppPalette.textMuted
                    : AppPalette.danger,
              ),
            ),
          ),
        ],
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
                  ? AppPalette.amber.withValues(alpha: 0.18)
                  : AppPalette.purple.withValues(alpha: 0.08),
              border: Border.all(
                color: active
                    ? AppPalette.amber.withValues(alpha: 0.55)
                    : AppPalette.purple.withValues(alpha: 0.25),
              ),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: active ? AppPalette.amber : AppPalette.textSecondary,
              ),
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
            color: selected
                ? AppPalette.amber
                : AppPalette.purple.withValues(alpha: 0.08),
            shape: BoxShape.circle,
            border: Border.all(
              color: selected
                  ? AppPalette.amber
                  : AppPalette.purple.withValues(alpha: 0.30),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppPalette.amber.withValues(alpha: 0.55),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Text(
            letter,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: selected ? AppPalette.voidBg : AppPalette.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
