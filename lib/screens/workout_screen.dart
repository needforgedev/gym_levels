import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../state/player_state.dart';
import '../theme/tokens.dart';
import '../widgets/buttons.dart';
import '../widgets/neon_card.dart';
import '../widgets/numeric_stepper.dart';
import '../widgets/screen_base.dart';
import '../widgets/xp_toast.dart';

enum _SetState { pending, active, completed }

class _SetData {
  _SetData({
    required this.n,
    required this.targetReps,
    required this.targetWeight,
    required this.state,
    this.actualReps,
    this.actualWeight,
    this.diff,
  });

  final int n;
  final int targetReps;
  final int targetWeight;
  _SetState state;
  int? actualReps;
  int? actualWeight;
  String? diff;
}

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  final _sets = <_SetData>[
    _SetData(
      n: 1,
      targetReps: 8,
      targetWeight: 80,
      state: _SetState.completed,
      actualWeight: 80,
      actualReps: 8,
      diff: 'B',
    ),
    _SetData(
      n: 2,
      targetReps: 8,
      targetWeight: 85,
      state: _SetState.completed,
      actualWeight: 85,
      actualReps: 8,
      diff: 'C',
    ),
    _SetData(
      n: 3,
      targetReps: 8,
      targetWeight: 85,
      state: _SetState.active,
    ),
    _SetData(
      n: 4,
      targetReps: 8,
      targetWeight: 85,
      state: _SetState.pending,
    ),
  ];

  int _reps = 8;
  double _weight = 85;
  bool _resting = false;
  int _restSec = 90;
  Timer? _restTimer;
  int? _toastKey;

  @override
  void dispose() {
    _restTimer?.cancel();
    super.dispose();
  }

  void _startRest() {
    _restTimer?.cancel();
    _restSec = 90;
    _resting = true;
    _restTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _restSec = (_restSec - 1).clamp(0, 9999);
        if (_restSec == 0) {
          _restTimer?.cancel();
          _resting = false;
        }
      });
    });
  }

  void _completeSet() {
    setState(() {
      final idx = _sets.indexWhere((s) => s.state == _SetState.active);
      if (idx == -1) return;
      _sets[idx]
        ..state = _SetState.completed
        ..actualReps = _reps
        ..actualWeight = _weight.round()
        ..diff = 'B';
      if (idx + 1 < _sets.length) {
        _sets[idx + 1].state = _SetState.active;
      }
      _toastKey = DateTime.now().millisecondsSinceEpoch;
    });
    context.read<PlayerState>().addXp(25);
    _startRest();
    Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() => _toastKey = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScreenBase(
      child: Stack(
        children: [
          Column(
            children: [
              _Header(onBack: () => context.go('/home')),
              _TargetRow(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.s5,
                    AppSpace.s1,
                    AppSpace.s5,
                    AppSpace.s4,
                  ),
                  children: [
                    ..._sets.map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpace.s3),
                        child: _SetCard(
                          data: s,
                          reps: _reps,
                          weight: _weight,
                          onReps: (v) => setState(() => _reps = v.round()),
                          onWeight: (v) => setState(() => _weight = v.toDouble()),
                          onComplete: _completeSet,
                        ),
                      ),
                    ),
                    _AddSetButton(),
                  ],
                ),
              ),
              if (_resting)
                _RestTimer(
                  restSec: _restSec,
                  onMinus: () => setState(
                    () => _restSec = (_restSec - 30).clamp(0, 9999),
                  ),
                  onPlus: () => setState(() => _restSec += 30),
                  onSkip: () {
                    _restTimer?.cancel();
                    setState(() {
                      _resting = false;
                      _restSec = 90;
                    });
                  },
                ),
            ],
          ),
          if (_toastKey != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 120,
              child: Center(
                child: XPToast(key: ValueKey(_toastKey), amount: 25),
              ),
            ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.s5,
        AppSpace.s5,
        AppSpace.s5,
        AppSpace.s3,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppPalette.strokeHairline)),
      ),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onBack,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: AppPalette.strokeHairline),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: AppPalette.textSecondary,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: AppSpace.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EXERCISE 2 OF 6',
                  style: AppType.label(color: AppPalette.textMuted).copyWith(
                    fontSize: 10,
                  ),
                ),
                Text(
                  'BENCH PRESS',
                  style: AppType.displayMD(color: AppPalette.textPrimary),
                ),
              ],
            ),
          ),
          Text('18:42', style: AppType.monoMD(color: AppPalette.textMuted)),
        ],
      ),
    );
  }
}

class _TargetRow extends StatelessWidget {
  const _TargetRow();

  static const _items = [
    ('TARGET', '4 × 8'),
    ('WEIGHT', '85 KG'),
    ('REST', '90s'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.s5,
        AppSpace.s4,
        AppSpace.s5,
        0,
      ),
      child: Row(
        children: _items.map((x) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: x == _items.last ? 0 : AppSpace.s3,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppPalette.carbon,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppPalette.strokeHairline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      x.$1,
                      style: AppType.label(color: AppPalette.textMuted)
                          .copyWith(fontSize: 9),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      x.$2,
                      style: AppType.monoMD(color: AppPalette.textPrimary),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SetCard extends StatelessWidget {
  const _SetCard({
    required this.data,
    required this.reps,
    required this.weight,
    required this.onReps,
    required this.onWeight,
    required this.onComplete,
  });

  final _SetData data;
  final int reps;
  final double weight;
  final ValueChanged<num> onReps;
  final ValueChanged<num> onWeight;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    switch (data.state) {
      case _SetState.pending:
        return Container(
          padding: const EdgeInsets.all(AppSpace.s4),
          decoration: BoxDecoration(
            color: AppPalette.carbon,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppPalette.strokeHairline),
          ),
          child: Opacity(
            opacity: 0.5,
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    '#${data.n}',
                    style: AppType.monoMD(color: AppPalette.textMuted),
                  ),
                ),
                Expanded(
                  child: Text(
                    'PENDING · ${data.targetReps} × ${data.targetWeight}kg',
                    style: AppType.bodySM(color: AppPalette.textMuted),
                  ),
                ),
              ],
            ),
          ),
        );
      case _SetState.completed:
        return Container(
          padding: const EdgeInsets.all(AppSpace.s4),
          decoration: BoxDecoration(
            color: AppPalette.carbon,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppPalette.green.withValues(alpha: 0.33)),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppPalette.green.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: AppPalette.green,
                  size: 16,
                ),
              ),
              const SizedBox(width: AppSpace.s4),
              Text(
                '#${data.n}',
                style: AppType.monoMD(color: AppPalette.textPrimary),
              ),
              const SizedBox(width: AppSpace.s4),
              Expanded(
                child: Text(
                  '${data.actualReps} × ${data.actualWeight}kg',
                  style: AppType.bodyMD(color: AppPalette.textPrimary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppPalette.green.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  data.diff ?? 'B',
                  style: AppType.monoMD(color: AppPalette.green).copyWith(
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        );
      case _SetState.active:
        return NeonCard(
          glow: GlowColor.purple,
          padding: const EdgeInsets.all(AppSpace.s5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    '#${data.n}',
                    style: AppType.monoMD(color: AppPalette.purple),
                  ),
                  const SizedBox(width: AppSpace.s3),
                  Text(
                    'ACTIVE SET',
                    style: AppType.label(color: AppPalette.purple),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppPalette.xpGold.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '+25 XP',
                      style: AppType.label(color: AppPalette.xpGold).copyWith(
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.s4),
              Row(
                children: [
                  Expanded(
                    child: NumericStepper(
                      value: weight,
                      step: 2.5,
                      label: 'WEIGHT',
                      unit: 'kg',
                      onChanged: onWeight,
                    ),
                  ),
                  const SizedBox(width: AppSpace.s3),
                  Expanded(
                    child: NumericStepper(
                      value: reps,
                      label: 'REPS',
                      onChanged: onReps,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.s4),
              PrimaryButton(
                label: 'COMPLETE SET',
                size: AppButtonSize.md,
                onTap: onComplete,
              ),
            ],
          ),
        );
    }
  }
}

class _AddSetButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: DottedBorderBox(
        child: Text(
          '+ ADD SET',
          style: AppType.label(color: AppPalette.textSecondary),
        ),
      ),
    );
  }
}

class DottedBorderBox extends StatelessWidget {
  const DottedBorderBox({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Simple dashed rectangle via DashedRectPainter.
    return CustomPaint(
      painter: _DashedRectPainter(color: AppPalette.strokeSubtle),
      child: Container(
        padding: const EdgeInsets.all(12),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  _DashedRectPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    const dash = 6.0;
    const gap = 4.0;
    final radius = const Radius.circular(AppRadius.md);
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      radius,
    );
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();
    for (final m in metrics) {
      double dist = 0;
      while (dist < m.length) {
        final next = (dist + dash).clamp(0.0, m.length);
        canvas.drawPath(m.extractPath(dist, next), paint);
        dist = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRectPainter oldDelegate) => false;
}

class _RestTimer extends StatelessWidget {
  const _RestTimer({
    required this.restSec,
    required this.onMinus,
    required this.onPlus,
    required this.onSkip,
  });

  final int restSec;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final progress = ((90 - restSec) / 90).clamp(0.0, 1.0);
    final mm = (restSec ~/ 60).toString();
    final ss = (restSec % 60).toString().padLeft(2, '0');

    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: AppPalette.carbon,
        border: Border(top: BorderSide(color: AppPalette.strokeHairline)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      AppPalette.teal.withValues(alpha: 0.2),
                      AppPalette.purple.withValues(alpha: 0.2),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _RestButton(label: '-30s', onTap: onMinus),
                const SizedBox(width: AppSpace.s3),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'REST',
                        style:
                            AppType.label(color: AppPalette.textMuted).copyWith(
                          fontSize: 9,
                        ),
                      ),
                      Text(
                        '$mm:$ss',
                        style: AppType.monoLG(color: AppPalette.textPrimary)
                            .copyWith(fontSize: 22),
                      ),
                    ],
                  ),
                ),
                _RestButton(label: 'SKIP', onTap: onSkip),
                const SizedBox(width: AppSpace.s3),
                _RestButton(label: '+30s', onTap: onPlus),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RestButton extends StatelessWidget {
  const _RestButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: AppPalette.strokeSubtle),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: AppType.label(color: AppPalette.textPrimary).copyWith(
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}
