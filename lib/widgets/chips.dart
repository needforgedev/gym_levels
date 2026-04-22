import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.icon,
    this.selected = false,
    required this.onTap,
    this.themeColor = AppPalette.teal,
    this.themeGlow = GlowColor.teal,
  });

  final String label;
  final Widget? icon;
  final bool selected;
  final VoidCallback onTap;
  final Color themeColor;
  final GlowColor themeGlow;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected
                ? themeColor.withValues(alpha: 0.18)
                : AppPalette.slate,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: selected ? themeColor : AppPalette.strokeSubtle,
              width: 1,
            ),
            boxShadow: selected
                ? AppGlow.shadow(themeGlow, intensity: 0.6, alpha: 0.3, blur: 10)
                : const [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                IconTheme(
                  data: IconThemeData(
                    color: selected ? themeColor : AppPalette.textSecondary,
                    size: 14,
                  ),
                  child: icon!,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label.toUpperCase(),
                style: AppType.label(
                  color: selected ? themeColor : AppPalette.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChipOption<T> {
  const ChipOption({required this.value, required this.label, this.icon});
  final T value;
  final String label;
  final Widget? icon;
}

enum ChipMode { single, multi }

class AppChipGroup<T> extends StatelessWidget {
  const AppChipGroup({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.mode = ChipMode.single,
    this.themeColor = AppPalette.teal,
    this.themeGlow = GlowColor.teal,
  });

  final List<ChipOption<T>> options;

  /// `T` for single, `List<T>` for multi.
  final Object? value;
  final ValueChanged<Object?> onChanged;
  final ChipMode mode;
  final Color themeColor;
  final GlowColor themeGlow;

  bool _isSelected(T v) {
    if (mode == ChipMode.single) return value == v;
    final list = (value as List?) ?? const [];
    return list.contains(v);
  }

  void _toggle(T v) {
    if (mode == ChipMode.single) {
      onChanged(v);
    } else {
      final list = List<T>.from((value as List?) ?? const []);
      if (list.contains(v)) {
        list.remove(v);
      } else {
        list.add(v);
      }
      onChanged(list);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpace.s3,
      runSpacing: AppSpace.s3,
      children: options
          .map(
            (o) => AppChip(
              label: o.label,
              icon: o.icon,
              selected: _isSelected(o.value),
              onTap: () => _toggle(o.value),
              themeColor: themeColor,
              themeGlow: themeGlow,
            ),
          )
          .toList(),
    );
  }
}
