import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class NumericStepper extends StatelessWidget {
  const NumericStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.step = 1,
    this.label,
    this.unit,
  });

  final num value;
  final ValueChanged<num> onChanged;
  final num step;
  final String? label;
  final String? unit;

  String _format(num v) => v is int || v == v.roundToDouble()
      ? v.round().toString()
      : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppPalette.slate,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          _StepBtn(
            icon: Icons.remove,
            onTap: () => onChanged(value - step),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (label != null)
                  Text(
                    label!.toUpperCase(),
                    style: AppType.label(color: AppPalette.textMuted).copyWith(
                      fontSize: 10,
                      height: 1.1,
                    ),
                  ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: RichText(
                    maxLines: 1,
                    softWrap: false,
                    text: TextSpan(
                      style: AppType.monoLG(color: AppPalette.textPrimary)
                          .copyWith(height: 1.1),
                      children: [
                        TextSpan(text: _format(value)),
                        if (unit != null)
                          TextSpan(
                            text: ' ${unit!}',
                            style: AppType.monoMD(
                              color: AppPalette.textSecondary,
                            ).copyWith(height: 1.1),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _StepBtn(icon: Icons.add, onTap: () => onChanged(value + step)),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppPalette.carbon,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            border: Border.all(color: AppPalette.strokeSubtle),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppPalette.textPrimary, size: 18),
        ),
      ),
    );
  }
}
