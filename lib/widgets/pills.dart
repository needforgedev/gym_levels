import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class _Pill extends StatelessWidget {
  const _Pill({
    required this.color,
    required this.icon,
    required this.label,
    this.glow = true,
  });

  final Color color;
  final Widget icon;
  final String label;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color, width: 1),
        boxShadow: glow
            ? [BoxShadow(color: color.withValues(alpha: 0.33), blurRadius: 8)]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconTheme(data: IconThemeData(color: color, size: 12), child: icon),
          const SizedBox(width: 6),
          Text(label, style: AppType.monoMD(color: color).copyWith(fontSize: 13)),
        ],
      ),
    );
  }
}

class LevelPill extends StatelessWidget {
  const LevelPill({super.key, required this.level});
  final int level;
  @override
  Widget build(BuildContext context) {
    return _Pill(
      color: AppPalette.xpGold,
      icon: const Icon(Icons.bolt),
      label: 'LVL $level',
    );
  }
}

class XPPill extends StatelessWidget {
  const XPPill({super.key, required this.xp, this.max});
  final int xp;
  final int? max;
  @override
  Widget build(BuildContext context) {
    final label = max == null ? '$xp XP' : '$xp / $max XP';
    return _Pill(
      color: AppPalette.purple,
      glow: false,
      icon: const Icon(Icons.brightness_1_outlined),
      label: label,
    );
  }
}

class StreakPill extends StatelessWidget {
  const StreakPill({super.key, required this.count, this.frozen = false});
  final int count;
  final bool frozen;
  @override
  Widget build(BuildContext context) {
    final color = frozen ? AppPalette.teal : AppPalette.flame;
    return _Pill(
      color: color,
      icon: Icon(frozen ? Icons.ac_unit : Icons.local_fire_department),
      label: '$count',
    );
  }
}
