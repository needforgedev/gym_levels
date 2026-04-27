import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/services/player_service.dart';
import '../state/player_state.dart';
import '../theme/tokens.dart';
import '../widgets/onboarding_scaffold.dart';
import '../widgets/progress_header.dart';

/// PRD §8 Section 4 Screen 16 — body fat estimate slider.
/// Matches design v2 (`design/v2/onboarding-questions.jsx` QBodyFat):
/// big level label at top, scan-frame body figure that morphs with
/// selection, "estimate only · not medical advice" caption, big number
/// readout, 0..3 slider with stop labels at the ends.
class BodyFatScreen extends StatefulWidget {
  const BodyFatScreen({super.key});

  @override
  State<BodyFatScreen> createState() => _BodyFatScreenState();
}

class _BodyFatScreenState extends State<BodyFatScreen> {
  int _stop = 1; // 0..3 (lean by default per design)

  static const _labels = <int, String>{
    0: 'VERY LEAN',
    1: 'LEAN',
    2: 'AVERAGE',
    3: 'ABOVE AVERAGE',
  };

  static const _keys = <int, String>{
    0: 'very_lean',
    1: 'lean',
    2: 'average',
    3: 'above',
  };

  static const _reverseKeys = <String, int>{
    'very_lean': 0,
    'lean': 1,
    'average': 2,
    'above': 3,
  };

  static const _tints = <int, Color>{
    0: AppPalette.teal,
    1: AppPalette.purpleSoft,
    2: AppPalette.amber,
    3: AppPalette.flame,
  };

  @override
  void initState() {
    super.initState();
    final existing = context.read<PlayerState>().player?.bodyFatEstimate;
    final mapped = _reverseKeys[existing];
    if (mapped != null) _stop = mapped;
  }

  Future<void> _save() async {
    final state = context.read<PlayerState>();
    await PlayerService.patch(bodyFatEstimate: _keys[_stop]);
    await state.refresh();
    if (!mounted) return;
    context.go('/calibrating/4');
  }

  @override
  Widget build(BuildContext context) {
    final tint = _tints[_stop]!;
    return OnboardingScaffold(
      section: OnboardingSection.attributes,
      percent: 82,
      subtitle: 'Estimating adipose composition…',
      title: 'Estimate your current body fat level:',
      onBack: () => context.go('/weight-direction'),
      onNext: _save,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Big level label.
          Center(
            child: Text(
              _labels[_stop]!,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                color: tint,
                shadows: [
                  Shadow(
                    color: tint.withValues(alpha: 0.5),
                    blurRadius: 16,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text(
              'estimate only · not medical advice',
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: AppPalette.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Scan-frame body figure (similar to body-type screen).
          Center(child: _BodyFatFrame(stop: _stop, tint: tint)),
          const SizedBox(height: 20),
          // Big amber readout.
          Center(
            child: Text(
              '${_stop + 1}',
              style: TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.w700,
                fontFamily: 'BebasNeue',
                color: AppPalette.amber,
                height: 1,
                shadows: [
                  Shadow(
                    color: AppPalette.amber.withValues(alpha: 0.5),
                    blurRadius: 30,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          // 0..3 slider with custom track + thumb (we lean on the same
          // SliderTheme primitives the BigSlider uses, but inline here so
          // we keep the screen-specific tick-mark labels).
          SliderTheme(
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
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(
              value: _stop.toDouble(),
              min: 0,
              max: 3,
              divisions: 3,
              onChanged: (v) => setState(() => _stop = v.round()),
            ),
          ),
          const SizedBox(height: 4),
          // Stop labels at the four divisions.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < 4; i++)
                  Text(
                    _labels[i]!,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: i == _stop
                          ? AppPalette.amber
                          : AppPalette.textDim,
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

/// Body figure inside a violet-bordered scan frame. The body's stance
/// width and pec/quad tint shifts subtly with the selected stop.
class _BodyFatFrame extends StatelessWidget {
  const _BodyFatFrame({required this.stop, required this.tint});
  final int stop;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 200,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: AppPalette.purple.withValues(alpha: 0.06),
        border: Border.all(
          color: AppPalette.purple.withValues(alpha: 0.30),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: CustomPaint(
          painter: _BodyFatBodyPainter(stop: stop, tint: tint),
        ),
      ),
    );
  }
}

class _BodyFatBodyPainter extends CustomPainter {
  _BodyFatBodyPainter({required this.stop, required this.tint});
  final int stop;
  final Color tint;

  /// Width modifier per stop — leaner stops are narrower, heavier wider.
  double get _waistScale {
    switch (stop) {
      case 0:
        return 0.85; // very lean
      case 1:
        return 0.95;
      case 2:
        return 1.05;
      case 3:
        return 1.20;
      default:
        return 1.0;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;
    final scale = _waistScale;

    // Faint scan grid.
    final grid = Paint()
      ..color = AppPalette.purple.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      final y = h * i / 4;
      canvas.drawLine(Offset(0, y), Offset(w, y), grid);
    }
    canvas.drawLine(Offset(cx, 0), Offset(cx, h), grid);

    // Body silhouette.
    final body = Paint()
      ..color = AppPalette.purple.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;

    // Head.
    canvas.drawCircle(Offset(cx, h * 0.13), w * 0.075, body);

    // Torso.
    final torso = Path()
      ..moveTo(cx - w * 0.15 * scale, h * 0.24)
      ..quadraticBezierTo(
        cx - w * 0.20 * scale,
        h * 0.30,
        cx - w * 0.20 * scale,
        h * 0.40,
      )
      ..quadraticBezierTo(
        cx - w * 0.22 * scale,
        h * 0.50,
        cx - w * 0.16 * scale,
        h * 0.58,
      )
      ..lineTo(cx - w * 0.10, h * 0.65)
      ..lineTo(cx + w * 0.10, h * 0.65)
      ..lineTo(cx + w * 0.16 * scale, h * 0.58)
      ..quadraticBezierTo(
        cx + w * 0.22 * scale,
        h * 0.50,
        cx + w * 0.20 * scale,
        h * 0.40,
      )
      ..quadraticBezierTo(
        cx + w * 0.20 * scale,
        h * 0.30,
        cx + w * 0.15 * scale,
        h * 0.24,
      )
      ..close();
    canvas.drawPath(torso, body);

    // Tinted pec / waist accent (visualises the selected stop).
    final tintPaint = Paint()..color = tint.withValues(alpha: 0.55);
    final pec = Path()
      ..moveTo(cx - w * 0.13 * scale, h * 0.27)
      ..quadraticBezierTo(
        cx,
        h * 0.31,
        cx + w * 0.13 * scale,
        h * 0.27,
      )
      ..quadraticBezierTo(
        cx + w * 0.10 * scale,
        h * 0.36,
        cx,
        h * 0.38,
      )
      ..quadraticBezierTo(
        cx - w * 0.10 * scale,
        h * 0.36,
        cx - w * 0.13 * scale,
        h * 0.27,
      )
      ..close();
    canvas.drawPath(pec, tintPaint);

    // Arms.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - w * 0.30 * scale, h * 0.27, w * 0.10, h * 0.32),
        const Radius.circular(8),
      ),
      body,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + w * 0.20 * scale, h * 0.27, w * 0.10, h * 0.32),
        const Radius.circular(8),
      ),
      body,
    );

    // Legs.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - w * 0.13, h * 0.65, w * 0.11, h * 0.32),
        const Radius.circular(6),
      ),
      body,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + w * 0.02, h * 0.65, w * 0.11, h * 0.32),
        const Radius.circular(6),
      ),
      body,
    );
  }

  @override
  bool shouldRepaint(covariant _BodyFatBodyPainter old) =>
      old.stop != stop || old.tint != tint;
}
