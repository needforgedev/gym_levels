import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// Big-mono-readout slider used across onboarding for age / height / weight /
/// body fat. Design-system §3.6 (`<SliderPicker bigLabel />`).
class BigSlider extends StatelessWidget {
  const BigSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    this.unit,
    this.label,
    this.themeColor = AppPalette.teal,
    required this.onChanged,
  });

  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String? unit;

  /// Optional caption below the big number (e.g. "VERY LEAN" for body fat).
  final String? label;

  final Color themeColor;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final isWhole = value == value.roundToDouble();
    final readout = isWhole ? value.round().toString() : value.toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: AppType.monoXL(color: themeColor).copyWith(
                fontSize: 72,
                height: 1,
                shadows: [
                  Shadow(
                    color: themeColor.withValues(alpha: 0.5),
                    blurRadius: 12,
                  ),
                ],
              ),
              children: [
                TextSpan(text: readout),
                if (unit != null)
                  TextSpan(
                    text: ' ${unit!}',
                    style: AppType.monoLG(color: AppPalette.textSecondary)
                        .copyWith(fontSize: 22),
                  ),
              ],
            ),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: AppSpace.s3),
          Center(
            child: Text(
              label!.toUpperCase(),
              style: AppType.label(color: themeColor).copyWith(letterSpacing: 2),
            ),
          ),
        ],
        const SizedBox(height: AppSpace.s5),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            activeTrackColor: themeColor,
            inactiveTrackColor: AppPalette.slate,
            thumbColor: themeColor,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            overlayColor: themeColor.withValues(alpha: 0.15),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
            valueIndicatorColor: themeColor,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isWhole ? min.round().toString() : min.toStringAsFixed(1),
              style: AppType.label(color: AppPalette.textMuted).copyWith(
                fontSize: 10,
              ),
            ),
            Text(
              isWhole ? max.round().toString() : max.toStringAsFixed(1),
              style: AppType.label(color: AppPalette.textMuted).copyWith(
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
