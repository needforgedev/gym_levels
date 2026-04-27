import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// Onboarding slider — matches design v2 `OBSlider`
/// (`design/v2/onboarding-shell.jsx`).
///
/// Layout:
///   • 72px Bebas-Neue amber readout with glow + small unit label.
///   • 8px-tall track: violet ghost background; filled portion is a
///     left→right violet→amber linear gradient with an amber outer
///     glow.
///   • 24px amber thumb with a 3px obsidian (page bg) ring and an
///     outer amber halo.
///   • Min / max value labels at the ends.
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
                        text: ' ${unit!}',
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 8,
                trackShape: const _OBTrackShape(),
                thumbShape: const _OBThumbShape(),
                // Disable default overlay (design has none).
                overlayShape: SliderComponentShape.noOverlay,
                // The shapes paint the actual colors; these placeholders
                // satisfy the Flutter API but aren't visually used.
                activeTrackColor: AppPalette.amber,
                inactiveTrackColor:
                    AppPalette.purple.withValues(alpha: 0.15),
                thumbColor: AppPalette.amber,
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
          const SizedBox(height: 8),
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

/// Custom track: violet ghost background with violet border, filled
/// portion is a violet→amber gradient with an amber drop-glow underneath.
class _OBTrackShape extends SliderTrackShape {
  const _OBTrackShape();

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final trackHeight = sliderTheme.trackHeight ?? 8;
    final width = parentBox.size.width;
    final top = offset.dy + (parentBox.size.height - trackHeight) / 2;
    return Rect.fromLTWH(offset.dx, top, width, trackHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 0,
  }) {
    final canvas = context.canvas;
    final trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
    );
    final trackRRect = RRect.fromRectAndRadius(
      trackRect,
      Radius.circular(trackRect.height / 2),
    );

    // Drop glow under the filled portion (drawn first so it's behind).
    if (thumbCenter.dx > trackRect.left) {
      final glowPaint = Paint()
        ..color = AppPalette.amber.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      final glowRRect = RRect.fromRectAndRadius(
        Rect.fromLTRB(
          trackRect.left,
          trackRect.top,
          thumbCenter.dx,
          trackRect.bottom,
        ),
        Radius.circular(trackRect.height / 2),
      );
      canvas.drawRRect(glowRRect, glowPaint);
    }

    // Inactive (full) track — violet ghost with thin violet border.
    final inactivePaint = Paint()
      ..color = AppPalette.purple.withValues(alpha: 0.15);
    canvas.drawRRect(trackRRect, inactivePaint);
    final borderPaint = Paint()
      ..color = AppPalette.purple.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(trackRRect, borderPaint);

    // Active (filled) portion — violet→amber gradient.
    if (thumbCenter.dx > trackRect.left) {
      final activeRect = Rect.fromLTRB(
        trackRect.left,
        trackRect.top,
        thumbCenter.dx,
        trackRect.bottom,
      );
      final activeRRect = RRect.fromRectAndRadius(
        activeRect,
        Radius.circular(trackRect.height / 2),
      );
      final shader = const LinearGradient(
        colors: [AppPalette.purple, AppPalette.amber],
      ).createShader(activeRect);
      final activePaint = Paint()..shader = shader;
      canvas.save();
      canvas.clipRRect(activeRRect);
      canvas.drawRect(activeRect, activePaint);
      canvas.restore();
    }
  }
}

/// Custom thumb: 24px amber circle with a 3px obsidian (page bg) ring
/// and an outer amber halo.
class _OBThumbShape extends SliderComponentShape {
  const _OBThumbShape();

  static const double _radius = 12;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size.fromRadius(_radius + 3);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextLayoutDelegate labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;

    // Outer halo (large blurred amber circle).
    final halo = Paint()
      ..color = AppPalette.amber.withValues(alpha: 0.7)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);
    canvas.drawCircle(center, _radius, halo);

    // Obsidian ring — sits as a 3px halo OUTSIDE the amber inner circle so
    // the amber pops off the violet track.
    final ring = Paint()..color = AppPalette.voidBg;
    canvas.drawCircle(center, _radius, ring);

    // Amber inner.
    final inner = Paint()..color = AppPalette.amber;
    canvas.drawCircle(center, _radius - 3, inner);
  }
}

typedef TextLayoutDelegate = TextPainter;
