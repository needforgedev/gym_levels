import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// Onboarding slider — matches design v2 `OBSlider`
/// (`design/v2/onboarding-shell.jsx`).
///
/// Layout: huge amber Bebas-Neue readout (72px) + small unit on the
/// right, then an 8px violet-track / amber→violet gradient fill bar with
/// a 24px amber knob (3px obsidian ring + amber glow). Min/Max labels
/// at the ends. Used for age / height / weight / body fat / target.
class BigSlider extends StatelessWidget {
  const BigSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    this.unit,
    this.label,
    this.themeColor = AppPalette.amber,
    required this.onChanged,
  });

  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String? unit;

  /// Optional caption below the big number (e.g. "VERY LEAN" for body fat).
  final String? label;

  /// Kept for compat — design v2's slider always reads in amber. Pass-through
  /// hint for callers that want a teal/green tint.
  final Color themeColor;

  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final isWhole = value == value.roundToDouble();
    final readout =
        isWhole ? value.round().toString() : value.toStringAsFixed(1);
    final readoutColor = themeColor == AppPalette.amber
        ? AppPalette.amber
        : themeColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Big amber readout.
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: AppType.displayXL(color: readoutColor).copyWith(
                    fontSize: 72,
                    height: 1,
                    shadows: [
                      Shadow(
                        color: readoutColor.withValues(alpha: 0.5),
                        blurRadius: 30,
                      ),
                    ],
                  ),
                  children: [
                    TextSpan(text: readout),
                    if (unit != null)
                      TextSpan(
                        text: '  ${unit!}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppPalette.textMuted,
                          shadows: [],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (label != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Center(
                child: Text(
                  label!.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: readoutColor,
                  ),
                ),
              ),
            ),
          // Track + knob via SliderTheme (design's gradient is approximated
          // by setting active = amber and inactive = violet ghost).
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 8,
                activeTrackColor: AppPalette.amber,
                inactiveTrackColor:
                    AppPalette.purple.withValues(alpha: 0.15),
                thumbColor: AppPalette.amber,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 12,
                  elevation: 0,
                ),
                overlayColor: AppPalette.amber.withValues(alpha: 0.2),
                overlayShape:
                    const RoundSliderOverlayShape(overlayRadius: 22),
                valueIndicatorColor: AppPalette.amber,
              ),
              child: Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                divisions: divisions,
                onChanged: onChanged,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isWhole ? min.round().toString() : min.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppPalette.textDim,
                  ),
                ),
                Text(
                  isWhole ? max.round().toString() : max.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppPalette.textDim,
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
