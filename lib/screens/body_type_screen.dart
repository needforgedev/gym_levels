import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/services/goals_service.dart';
import '../theme/tokens.dart';
import '../widgets/onboarding_scaffold.dart';
import '../widgets/progress_header.dart';

/// PRD §8 Section 2 Screen 6 — body type with scan-frame figure + 4 cards.
/// Matches design v2 (`design/v2/onboarding-questions.jsx` QBodyType).
class BodyTypeScreen extends StatefulWidget {
  const BodyTypeScreen({super.key});

  @override
  State<BodyTypeScreen> createState() => _BodyTypeScreenState();
}

class _BodyTypeScreenState extends State<BodyTypeScreen> {
  String? _value;

  @override
  void initState() {
    super.initState();
    GoalsService.get().then((g) {
      if (mounted && g?.bodyType != null) {
        setState(() => _value = g!.bodyType);
      }
    });
  }

  Future<void> _save() async {
    if (_value == null) return;
    await GoalsService.patch(bodyType: _value);
    if (!mounted) return;
    // Skip /priority-muscles + /reward-style — removed from the
    // linear onboarding per the design's 12-question flow. Both
    // routes still exist for Settings → Edit Onboarding (S7).
    context.go('/calibrating/2');
  }

  static const _options = [
    ('lean', 'Lean & Toned', 'Defined muscle, low body fat'),
    ('muscular', 'Muscular & Defined', 'Visible size with shape'),
    ('powerful', 'Strong & Powerful', 'Max strength + mass'),
    ('balanced', 'Balanced & Functional', 'Athletic and versatile'),
  ];

  String _selectedLabel() {
    final hit = _options.firstWhere(
      (o) => o.$1 == _value,
      orElse: () => _options[3],
    );
    return hit.$2;
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      section: OnboardingSection.objectives,
      percent: 24,
      subtitle: 'Selecting combat archetype…',
      title: 'Which body type represents your goal?',
      nextEnabled: _value != null,
      onBack: () => context.go('/calibrating/1'),
      onNext: _save,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Scan-frame body figure.
          Center(
            child: _ScanFrame(
              label: _value == null ? 'AWAITING' : _selectedLabel(),
            ),
          ),
          const SizedBox(height: 20),
          // 2x2 grid of cards.
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.6,
            children: _options
                .map(
                  (o) => _BodyTypeCard(
                    key: ValueKey(o.$1),
                    label: o.$2,
                    desc: o.$3,
                    selected: _value == o.$1,
                    onTap: () => setState(() => _value = o.$1),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

/// Scan-frame container with green corner brackets, a top-left
/// `[SCAN] {label}` chip, and a placeholder body silhouette inside.
class _ScanFrame extends StatelessWidget {
  const _ScanFrame({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF22E06B);
    return SizedBox(
      width: 200,
      height: 220,
      child: Stack(
        children: [
          // Inner scan content (body image + faint grid).
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: AppPalette.purple.withValues(alpha: 0.06),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(painter: _ScanGridPainter()),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Image.asset(
                        'assets/body-front.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Corner brackets.
          ..._corners(accent),
          // [SCAN] label chip.
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: accent.withValues(alpha: 0.15),
                border: Border.all(
                  color: accent.withValues(alpha: 0.55),
                  width: 1,
                ),
              ),
              child: Text(
                '[SCAN] ${label.toUpperCase()}',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: accent,
                  fontFamily: 'JetBrainsMono',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _corners(Color color) {
    Widget bracket({
      required AlignmentGeometry alignment,
      required bool top,
      required bool left,
    }) {
      return Align(
        alignment: alignment,
        child: SizedBox(
          width: 22,
          height: 22,
          child: CustomPaint(
            painter: _CornerBracketPainter(color: color, top: top, left: left),
          ),
        ),
      );
    }

    return [
      bracket(alignment: Alignment.topLeft, top: true, left: true),
      bracket(alignment: Alignment.topRight, top: true, left: false),
      bracket(alignment: Alignment.bottomLeft, top: false, left: true),
      bracket(alignment: Alignment.bottomRight, top: false, left: false),
    ];
  }
}

class _CornerBracketPainter extends CustomPainter {
  _CornerBracketPainter({
    required this.color,
    required this.top,
    required this.left,
  });
  final Color color;
  final bool top;
  final bool left;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final path = Path();
    if (top && left) {
      path.moveTo(0, h * 0.5);
      path.lineTo(0, 0);
      path.lineTo(w * 0.5, 0);
    } else if (top && !left) {
      path.moveTo(w * 0.5, 0);
      path.lineTo(w, 0);
      path.lineTo(w, h * 0.5);
    } else if (!top && left) {
      path.moveTo(0, h * 0.5);
      path.lineTo(0, h);
      path.lineTo(w * 0.5, h);
    } else {
      path.moveTo(w * 0.5, h);
      path.lineTo(w, h);
      path.lineTo(w, h * 0.5);
    }
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant _CornerBracketPainter old) =>
      old.color != color;
}

/// Faint green scan grid drawn behind the body image — preserves the
/// `[SCAN] …` HUD aesthetic from the design.
class _ScanGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;
    final grid = Paint()
      ..color = const Color(0xFF22E06B).withValues(alpha: 0.10)
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      final y = h * i / 4;
      canvas.drawLine(Offset(0, y), Offset(w, y), grid);
    }
    canvas.drawLine(Offset(cx, 0), Offset(cx, h), grid);
  }

  @override
  bool shouldRepaint(covariant _ScanGridPainter old) => false;
}

/// Card with label + small description, amber gradient when selected.
class _BodyTypeCard extends StatelessWidget {
  const _BodyTypeCard({
    super.key,
    required this.label,
    required this.desc,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String desc;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: selected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppPalette.amber.withValues(alpha: 0.16),
                      AppPalette.purple.withValues(alpha: 0.12),
                    ],
                  )
                : null,
            color: selected
                ? null
                : AppPalette.bgCard.withValues(alpha: 0.7),
            border: Border.all(
              color: selected
                  ? AppPalette.amber.withValues(alpha: 0.55)
                  : AppPalette.purple.withValues(alpha: 0.18),
              width: 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppPalette.amber.withValues(alpha: 0.45),
                      blurRadius: 18,
                      spreadRadius: -4,
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppPalette.textMuted,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
