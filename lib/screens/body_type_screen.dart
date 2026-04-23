import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/services/goals_service.dart';
import '../theme/tokens.dart';
import '../widgets/neon_card.dart';
import '../widgets/onboarding_scaffold.dart';
import '../widgets/placeholder_block.dart';
import '../widgets/progress_header.dart';

/// PRD §8 Section 2 Screen 6 — 4 anime avatar cards (body type goal).
class BodyTypeScreen extends StatefulWidget {
  const BodyTypeScreen({super.key});

  @override
  State<BodyTypeScreen> createState() => _BodyTypeScreenState();
}

class _BodyTypeScreenState extends State<BodyTypeScreen> {
  String? _value;

  @override
  void initState() {
    super.initState();
    GoalsService.get().then((g) {
      if (mounted && g?.bodyType != null) {
        setState(() => _value = g!.bodyType);
      }
    });
  }

  Future<void> _save() async {
    if (_value == null) return;
    await GoalsService.patch(bodyType: _value);
    if (!mounted) return;
    context.go('/priority-muscles');
  }

  static const _options = [
    ('lean', 'LEAN &\nTONED'),
    ('muscular', 'MUSCULAR &\nDEFINED'),
    ('strong', 'STRONG &\nPOWERFUL'),
    ('balanced', 'BALANCED &\nFUNCTIONAL'),
  ];

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      section: OnboardingSection.objectives,
      percent: 15,
      kicker: 'MISSION OBJECTIVES',
      subtitle: '…locking target silhouette.',
      nextEnabled: _value != null,
      onBack: () => context.go('/calibrating/1'),
      onNext: _save,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NeonCard(
            glow: GlowColor.purple,
            padding: const EdgeInsets.all(AppSpace.s6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Which body type\nrepresents your goal?',
                  style: AppType.displayMD(color: AppPalette.textPrimary),
                ),
                const SizedBox(height: AppSpace.s5),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSpace.s3,
                  crossAxisSpacing: AppSpace.s3,
                  childAspectRatio: 0.75,
                  children: _options
                      .map(
                        (o) => _BodyCard(
                          key: ValueKey(o.$1),
                          label: o.$2,
                          selected: _value == o.$1,
                          onTap: () => setState(() => _value = o.$1),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BodyCard extends StatelessWidget {
  const _BodyCard({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(AppSpace.s3),
          decoration: BoxDecoration(
            color: selected
                ? AppPalette.purple.withValues(alpha: 0.12)
                : AppPalette.slate,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selected ? AppPalette.purple : AppPalette.strokeSubtle,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppPalette.purple.withValues(alpha: 0.4),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Expanded(
                child: PlaceholderBlock(
                  label: label.replaceAll('\n', ' '),
                  height: 999,
                  color: AppPalette.purple,
                  border: false,
                ),
              ),
              const SizedBox(height: AppSpace.s3),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppType.label(
                  color: selected
                      ? AppPalette.purple
                      : AppPalette.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
