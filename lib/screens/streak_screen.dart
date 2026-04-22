import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/player_state.dart';
import '../theme/tokens.dart';
import '../widgets/big_flame.dart';
import '../widgets/in_app_shell.dart';
import '../widgets/neon_card.dart';
import '../widgets/tab_bar.dart';

enum _DayType { workout, rest, miss, freeze, today }

class StreakScreen extends StatelessWidget {
  const StreakScreen({super.key});

  List<_DayType> _generateCells() {
    final cells = <_DayType>[];
    for (var i = 0; i < 30; i++) {
      if (i == 27) {
        cells.add(_DayType.today);
      } else if (i == 25) {
        cells.add(_DayType.freeze);
      } else if (i == 18 || i == 12) {
        cells.add(_DayType.miss);
      } else if (i % 7 == 3 || i % 7 == 6) {
        cells.add(_DayType.rest);
      } else {
        cells.add(_DayType.workout);
      }
    }
    return cells;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<PlayerState>();
    final cells = _generateCells();
    return InAppShell(
      active: AppTab.streak,
      title: 'STREAK',
      child: ListView(
        padding: const EdgeInsets.all(AppSpace.s5),
        children: [
          // Flame hero
          NeonCard(
            glow: GlowColor.flame,
            padding: const EdgeInsets.all(AppSpace.s7),
            child: Row(
              children: [
                SizedBox(
                  width: 96,
                  height: 96,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const BigFlame(),
                      Text(
                        '${s.streak}',
                        style: AppType.monoXL(color: AppPalette.obsidian)
                            .copyWith(
                          fontSize: 36,
                          height: 1,
                          shadows: [
                            Shadow(
                              color: AppPalette.flame,
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpace.s6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DAY STREAK',
                        style: AppType.label(color: AppPalette.flame),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ON FIRE',
                        style: AppType.displayLG(color: AppPalette.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      Text.rich(
                        TextSpan(
                          style: AppType.bodySM(color: AppPalette.textSecondary),
                          children: [
                            const TextSpan(text: 'Next milestone: '),
                            TextSpan(
                              text: '30 days',
                              style: AppType.bodySM(color: AppPalette.xpGold),
                            ),
                            const TextSpan(text: ' — unlocks the '),
                            TextSpan(
                              text: 'Iron Heart',
                              style: AppType.bodySM(
                                color: AppPalette.textPrimary,
                              ).copyWith(fontWeight: FontWeight.bold),
                            ),
                            const TextSpan(text: ' buff.'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.s4),

          // Calendar
          NeonCard(
            glow: GlowColor.none,
            padding: const EdgeInsets.all(AppSpace.s4),
            pulse: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'APR 2026',
                      style: AppType.label(color: AppPalette.textMuted),
                    ),
                    Text(
                      '21 / 30 DAYS',
                      style: AppType.label(color: AppPalette.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: const ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((d) {
                    return Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: AppType.label(color: AppPalette.textMuted)
                              .copyWith(fontSize: 10),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 4),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 7,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  children: cells.map((c) => _DayCell(type: c)).toList(),
                ),
                const SizedBox(height: AppSpace.s4),
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  children: const [
                    _Legend(color: AppPalette.xpGold, label: 'WORKOUT'),
                    _Legend(
                      color: Colors.transparent,
                      borderColor: AppPalette.purple,
                      label: 'REST',
                    ),
                    _Legend(color: AppPalette.carbon, label: 'MISSED'),
                    _Legend(
                      color: Colors.transparent,
                      borderColor: AppPalette.teal,
                      label: 'TODAY',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.s4),

          // Freeze card
          NeonCard(
            glow: GlowColor.teal,
            padding: const EdgeInsets.all(AppSpace.s5),
            pulse: false,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppPalette.teal.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppPalette.teal),
                  ),
                  child: const Icon(
                    Icons.ac_unit,
                    color: AppPalette.teal,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpace.s4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'STREAK FREEZE × 2',
                        style: AppType.label(color: AppPalette.teal),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Auto-saves your streak on a missed day.',
                        style: AppType.bodySM(color: AppPalette.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.type});
  final _DayType type;

  @override
  Widget build(BuildContext context) {
    final base = BoxDecoration(borderRadius: BorderRadius.circular(4));
    switch (type) {
      case _DayType.workout:
        return Container(
          decoration: base.copyWith(
            color: AppPalette.xpGold,
            boxShadow: [
              BoxShadow(
                color: AppPalette.xpGold.withValues(alpha: 0.5),
                blurRadius: 4,
              ),
            ],
          ),
        );
      case _DayType.rest:
        return Container(
          decoration: base.copyWith(
            color: AppPalette.purple.withValues(alpha: 0.07),
            border: Border.all(color: AppPalette.purple),
          ),
        );
      case _DayType.miss:
        return Container(
          decoration: base.copyWith(
            color: AppPalette.carbon,
            border: Border.all(color: AppPalette.strokeHairline),
          ),
        );
      case _DayType.freeze:
        return Container(
          decoration: base.copyWith(
            color: AppPalette.carbon,
            border: Border.all(color: AppPalette.teal),
          ),
          child: const Icon(Icons.ac_unit, color: AppPalette.teal, size: 12),
        );
      case _DayType.today:
        return Container(
          decoration: base.copyWith(
            border: Border.all(color: AppPalette.teal, width: 2),
            boxShadow: [
              BoxShadow(color: AppPalette.teal, blurRadius: 10),
            ],
          ),
        );
    }
  }
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.color,
    required this.label,
    this.borderColor,
  });

  final Color color;
  final Color? borderColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: borderColor != null ? Border.all(color: borderColor!) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style:
              AppType.label(color: AppPalette.textMuted).copyWith(fontSize: 9),
        ),
      ],
    );
  }
}
