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
          const Center(child: _BodyFatFrame()),
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

/// Body figure inside a violet-bordered scan frame. Uses
/// [body-front.png] as the silhouette layer with a faint scan grid
/// behind it for the HUD aesthetic.
class _BodyFatFrame extends StatelessWidget {
  const _BodyFatFrame();

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
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: _BodyFatGridPainter()),
            Padding(
              padding: const EdgeInsets.all(4),
              child: Image.asset(
                'assets/body-front.png',
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Faint violet grid drawn behind the body image in the body-fat
/// scan frame.
class _BodyFatGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;
    final grid = Paint()
      ..color = AppPalette.purple.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      final y = h * i / 4;
      canvas.drawLine(Offset(0, y), Offset(w, y), grid);
    }
    canvas.drawLine(Offset(cx, 0), Offset(cx, h), grid);
  }

  @override
  bool shouldRepaint(covariant _BodyFatGridPainter old) => false;
}
