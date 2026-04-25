import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// Visual variants for [AppPill]. Matches the `variants` map in
/// `design/v2/shared.jsx`'s `Pill` component (violet, amber, teal, streak,
/// ghost). Use [AppPill] for chip-row labels — "Upper Body", "~60 min",
/// muscle tags, etc.
enum AppPillVariant { violet, amber, teal, streak, ghost }

class AppPill extends StatelessWidget {
  const AppPill({
    super.key,
    required this.label,
    this.variant = AppPillVariant.violet,
    this.icon,
    this.dense = false,
  });

  final String label;
  final AppPillVariant variant;
  final IconData? icon;

  /// Slightly tighter padding + smaller text used inside packed chip rows
  /// (e.g. the muscle tags under the Next Workout card).
  final bool dense;

  ({Color bg, Color border, Color fg}) _spec() {
    switch (variant) {
      case AppPillVariant.violet:
        return (
          bg: AppPalette.purple.withValues(alpha: 0.18),
          border: AppPalette.purple.withValues(alpha: 0.40),
          fg: const Color(0xFFC4B5FD),
        );
      case AppPillVariant.amber:
        return (
          bg: AppPalette.amber.withValues(alpha: 0.15),
          border: AppPalette.amber.withValues(alpha: 0.40),
          fg: AppPalette.amberSoft,
        );
      case AppPillVariant.teal:
        return (
          bg: AppPalette.teal.withValues(alpha: 0.12),
          border: AppPalette.teal.withValues(alpha: 0.40),
          fg: AppPalette.teal,
        );
      case AppPillVariant.streak:
        return (
          bg: AppPalette.streak.withValues(alpha: 0.15),
          border: AppPalette.streak.withValues(alpha: 0.40),
          fg: AppPalette.streak,
        );
      case AppPillVariant.ghost:
        return (
          bg: AppPalette.purple.withValues(alpha: 0.08),
          border: AppPalette.purple.withValues(alpha: 0.20),
          fg: AppPalette.purpleSoft,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _spec();
    final hPad = dense ? 8.0 : 12.0;
    final vPad = dense ? 3.0 : 6.0;
    final fontSize = dense ? 10.0 : 12.0;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: s.bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: s.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: s.fg, size: fontSize + 2),
            const SizedBox(width: 6),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: s.fg,
            ),
          ),
        ],
      ),
    );
  }
}

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
