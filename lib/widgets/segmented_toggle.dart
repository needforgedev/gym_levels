import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class SegmentOption<T> {
  const SegmentOption({required this.value, required this.label});
  final T value;
  final String label;
}

class SegmentedToggle<T> extends StatelessWidget {
  const SegmentedToggle({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.color = AppPalette.teal,
  });

  final List<SegmentOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppPalette.slate,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: options.map((o) {
          final selected = o.value == value;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onChanged(o.value),
                  borderRadius: BorderRadius.circular(8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: selected
                          ? color.withValues(alpha: 0.20)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected ? color : Colors.transparent,
                        width: 1,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.5),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        o.label.toUpperCase(),
                        style: AppType.label(
                          color: selected ? color : AppPalette.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
