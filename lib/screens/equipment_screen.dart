import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/services/experience_service.dart';
import '../state/player_state.dart';
import '../widgets/onboarding_radio_tile.dart';
import '../widgets/onboarding_scaffold.dart';
import '../widgets/progress_header.dart';

/// PRD §8 Section 3 Screen 10 — equipment multi-select (≥1 required).
class EquipmentScreen extends StatefulWidget {
  const EquipmentScreen({super.key});

  @override
  State<EquipmentScreen> createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends State<EquipmentScreen> {
  List<String> _selected = [];

  @override
  void initState() {
    super.initState();
    ExperienceService.get().then((e) {
      if (mounted && e != null && e.equipment.isNotEmpty) {
        setState(() => _selected = List.of(e.equipment));
      }
    });
  }

  Future<void> _save() async {
    if (_selected.isEmpty) return;
    final onboarded = context.read<PlayerState>().isOnboarded;
    await ExperienceService.patch(equipment: _selected);
    if (!mounted) return;
    context.go(onboarded ? '/home' : '/limitations');
  }

  static const _options = [
    ('barbell', 'Barbell & Plates'),
    ('dumbbell', 'Dumbbells'),
    ('kettlebell', 'Kettlebells'),
    ('resistance_band', 'Resistance Bands'),
    ('pullup_bar', 'Pull-up Bar'),
    ('cable_machine', 'Cable Machine'),
    ('bench', 'Bench'),
    ('squat_rack', 'Squat Rack'),
    ('bodyweight', 'Bodyweight Only'),
  ];

  void _toggle(String key) {
    final list = List<String>.from(_selected);
    if (list.contains(key)) {
      list.remove(key);
    } else {
      list.add(key);
    }
    setState(() => _selected = list);
  }

  @override
  Widget build(BuildContext context) {
    final onboarded = context.watch<PlayerState>().isOnboarded;
    return OnboardingScaffold(
      section: OnboardingSection.experience,
      percent: 48,
      subtitle: 'Scanning available armoury…',
      title: 'What equipment do you have?',
      nextEnabled: _selected.isNotEmpty,
      onBack: () => context.go(onboarded ? '/home' : '/tenure'),
      onNext: _save,
      child: Wrap(
        spacing: 8,
        runSpacing: 10,
        children: [
          for (final o in _options)
            OnboardingChip(
              label: o.$2,
              selected: _selected.contains(o.$1),
              onTap: () => _toggle(o.$1),
            ),
        ],
      ),
    );
  }
}
