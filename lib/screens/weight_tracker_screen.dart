import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/goal.dart';
import '../data/models/weight_log.dart';
import '../data/services/goals_service.dart';
import '../data/services/weight_log_service.dart';
import '../state/player_state.dart';
import '../theme/tokens.dart';
import '../widgets/screen_base.dart';

/// Weight Tracker drill-down — matches design v2 (`screens-progress.jsx`
/// `WeightScreen`). Renders the player's current weight, the start /
/// current / target segmented stats, and a 30D/90D/1Y line chart fed
/// from `weight_logs`.
///
/// Data sources:
///   • Current weight = latest `weight_logs` row, or `Player.weightKg`
///     fallback (set during onboarding).
///   • Start weight = the oldest log within the active range, or the
///     onboarding-time weight when no logs exist.
///   • Target = `goals.target_weight_kg`.
class WeightTrackerScreen extends StatefulWidget {
  const WeightTrackerScreen({super.key});

  @override
  State<WeightTrackerScreen> createState() => _WeightTrackerScreenState();
}

enum _Range { d30, d90, y1 }

class _ChartPoint {
  const _ChartPoint({required this.epoch, required this.kg});
  final int epoch;
  final double kg;
}

class _WeightTrackerBundle {
  const _WeightTrackerBundle({
    required this.logs,
    required this.goal,
    required this.fallbackWeightKg,
    required this.startWeightKg,
    required this.chartPoints,
  });
  final List<WeightLog> logs;
  final Goal? goal;

  /// Onboarding-time weight (`Player.weightKg`). Used as the canonical
  /// "Start" anchor — if the user logs their first weight months after
  /// onboarding, that log is *not* the start; the onboarding entry is.
  final double fallbackWeightKg;

  /// Weight to render under the `Start` tab. Defaults to the onboarding
  /// fallback when present; falls back to the first log's weight if the
  /// onboarding row never recorded a weight.
  final double startWeightKg;

  /// Time-sorted points fed to the trend chart. Includes a synthetic
  /// `(onboardedAt, fallbackWeightKg)` head when an onboarding weight
  /// exists and predates the first log — that way a single log still
  /// renders a real trend line instead of a "Log a weight to start
  /// tracking" empty state.
  final List<_ChartPoint> chartPoints;
}

class _WeightTrackerScreenState extends State<WeightTrackerScreen> {
  _Range _range = _Range.d30;
  late Future<_WeightTrackerBundle> _future;

  @override
  void initState() {
    super.initState();
    // Capture the player's current weight + onboarding timestamp before
    // any awaits — using `context` after an async gap inside a State
    // method trips the analyzer.
    final p = context.read<PlayerState>().player;
    final fallback = p?.weightKg ?? 0;
    final startEpoch = p?.onboardedAt ?? p?.createdAt ?? 0;
    _future = _load(fallback, startEpoch);
  }

  Future<_WeightTrackerBundle> _load(double fallback, int startEpoch) async {
    final results = await Future.wait([
      WeightLogService.all(),
      GoalsService.get(),
    ]);
    final logs = (results[0] as List<WeightLog>).toList()
      ..sort((a, b) => a.loggedOn.compareTo(b.loggedOn));
    final goal = results[1] as Goal?;

    // Start = onboarding weight if recorded; else the earliest log.
    final startWeight = fallback > 0
        ? fallback
        : (logs.isNotEmpty ? logs.first.weightKg : 0.0);

    // Synthesize the chart series. Prepend `(startEpoch, fallback)` when
    // the onboarding weight predates the first log, so even a single
    // post-onboarding log produces a 2-point trend line.
    final points = <_ChartPoint>[];
    final hasFallback = fallback > 0 && startEpoch > 0;
    final beforeFirstLog =
        logs.isEmpty || startEpoch < logs.first.loggedOn;
    if (hasFallback && beforeFirstLog) {
      points.add(_ChartPoint(epoch: startEpoch, kg: fallback));
    }
    for (final l in logs) {
      points.add(_ChartPoint(epoch: l.loggedOn, kg: l.weightKg));
    }

    return _WeightTrackerBundle(
      logs: logs,
      goal: goal,
      fallbackWeightKg: fallback,
      startWeightKg: startWeight,
      chartPoints: points,
    );
  }

  Duration _windowFor(_Range r) {
    switch (r) {
      case _Range.d30:
        return const Duration(days: 30);
      case _Range.d90:
        return const Duration(days: 90);
      case _Range.y1:
        return const Duration(days: 365);
    }
  }

  String _rangeLabel(_Range r) => switch (r) {
        _Range.d30 => '30D',
        _Range.d90 => '90D',
        _Range.y1 => '1Y',
      };

  Future<void> _openLogSheet(double currentWeightKg) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _LogWeightSheet(initialWeightKg: currentWeightKg),
    );
    if (saved != true || !mounted) return;
    final p = context.read<PlayerState>().player;
    final fallback = p?.weightKg ?? 0;
    final startEpoch = p?.onboardedAt ?? p?.createdAt ?? 0;
    setState(() {
      _future = _load(fallback, startEpoch);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScreenBase(
      background: AppPalette.voidBg,
      child: SafeArea(
        bottom: false,
        child: FutureBuilder<_WeightTrackerBundle>(
          future: _future,
          builder: (ctx, snap) {
            final bundle = snap.data;
            final current = bundle == null
                ? 0.0
                : (bundle.logs.isNotEmpty
                    ? bundle.logs.last.weightKg
                    : bundle.fallbackWeightKg);
            return Column(
              children: [
                _Header(
                  onBack: () => context.go('/profile'),
                  onLog: () => _openLogSheet(current),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    children: [
                      _CurrentWeightCard(bundle: bundle),
                      const SizedBox(height: 14),
                      _StartCurrentTargetTabs(bundle: bundle),
                      const SizedBox(height: 14),
                      _WeightTrendCard(
                        bundle: bundle,
                        range: _range,
                        rangeLabel: _rangeLabel(_range),
                        onRangeChanged: (r) => setState(() => _range = r),
                        windowFor: _windowFor,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─── Header ────────────────────────────────────────────────
class _Header extends StatelessWidget {
  const _Header({required this.onBack, required this.onLog});
  final VoidCallback onBack;
  final VoidCallback onLog;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          _RoundButton(icon: Icons.chevron_left, onTap: onBack),
          const Spacer(),
          const Text(
            'Weight Tracker',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppPalette.textPrimary,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: onLog,
            style: TextButton.styleFrom(
              foregroundColor: AppPalette.teal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text(
              '+ Log',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppPalette.purple.withValues(alpha: 0.12),
            border: Border.all(
              color: AppPalette.purple.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Icon(icon, size: 20, color: AppPalette.textPrimary),
        ),
      ),
    );
  }
}

// ─── Current weight card ───────────────────────────────────
class _CurrentWeightCard extends StatelessWidget {
  const _CurrentWeightCard({required this.bundle});
  final _WeightTrackerBundle? bundle;

  @override
  Widget build(BuildContext context) {
    final logs = bundle?.logs ?? const <WeightLog>[];
    final fallback = bundle?.fallbackWeightKg ?? 0;
    final start = bundle?.startWeightKg ?? fallback;
    final current = logs.isNotEmpty ? logs.last.weightKg : fallback;
    // Prefer log-to-log delta; if there's only one log, fall back to
    // current-vs-start so the user always sees their cumulative
    // progress. Suppressed when the deltas would round to zero.
    final logToLogDelta =
        logs.length >= 2 ? current - logs[logs.length - 2].weightKg : null;
    final delta = logToLogDelta ?? (start > 0 ? current - start : 0.0);
    final target = bundle?.goal?.targetWeightKg;
    final toGo = target == null ? null : (current - target);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xE61A0F2B), Color(0xE6120A1F)],
        ),
        border: Border.all(
          color: AppPalette.purple.withValues(alpha: 0.45),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppPalette.purple.withValues(alpha: 0.30),
            blurRadius: 24,
            spreadRadius: -8,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CURRENT WEIGHT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: AppPalette.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: current == 0
                            ? '—'
                            : current.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 52,
                          fontFamily: 'BebasNeue',
                          height: 1,
                          color: AppPalette.textPrimary,
                        ),
                      ),
                      const TextSpan(
                        text: '  kg',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppPalette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (delta != 0)
                      _Pill(
                        text:
                            '${delta < 0 ? "↓" : "↑"} ${delta.abs().toStringAsFixed(1)} kg',
                        color: delta < 0
                            ? AppPalette.success
                            : AppPalette.amber,
                      ),
                    if (toGo != null && toGo > 0)
                      _Pill(
                        text: '${toGo.abs().toStringAsFixed(1)} KG TO GO',
                        color: AppPalette.amber,
                        emphasis: true,
                      ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppPalette.purple.withValues(alpha: 0.12),
            ),
            child: Icon(
              Icons.scale,
              size: 24,
              color: AppPalette.purpleSoft,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.text,
    required this.color,
    this.emphasis = false,
  });
  final String text;
  final Color color;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: emphasis ? 0.18 : 0.12),
        border: Border.all(
          color: color.withValues(alpha: emphasis ? 0.50 : 0.30),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: color,
        ),
      ),
    );
  }
}

// ─── Start / Current / Target tabs ─────────────────────────
class _StartCurrentTargetTabs extends StatelessWidget {
  const _StartCurrentTargetTabs({required this.bundle});
  final _WeightTrackerBundle? bundle;

  @override
  Widget build(BuildContext context) {
    final logs = bundle?.logs ?? const <WeightLog>[];
    final fallback = bundle?.fallbackWeightKg ?? 0;
    final start = bundle?.startWeightKg ?? fallback;
    final current = logs.isNotEmpty ? logs.last.weightKg : fallback;
    final target = bundle?.goal?.targetWeightKg;

    String fmt(double? v) {
      if (v == null || v == 0) return '—';
      return v.toStringAsFixed(1);
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppPalette.bgCard.withValues(alpha: 0.8),
        border: Border.all(
          color: AppPalette.purple.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabPill(label: 'Start', value: fmt(start), active: false),
          ),
          const SizedBox(width: 6),
          Expanded(
            child:
                _TabPill(label: 'Current', value: fmt(current), active: true),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _TabPill(label: 'Target', value: fmt(target), active: false),
          ),
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.value,
    required this.active,
  });
  final String label;
  final String value;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: active
            ? AppPalette.purple.withValues(alpha: 0.25)
            : Colors.transparent,
        border: Border.all(
          color: active
              ? AppPalette.purple.withValues(alpha: 0.40)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          '$label  $value',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: active ? AppPalette.purpleSoft : AppPalette.textMuted,
          ),
        ),
      ),
    );
  }
}

// ─── Weight trend card with chart ──────────────────────────
class _WeightTrendCard extends StatelessWidget {
  const _WeightTrendCard({
    required this.bundle,
    required this.range,
    required this.rangeLabel,
    required this.onRangeChanged,
    required this.windowFor,
  });
  final _WeightTrackerBundle? bundle;
  final _Range range;
  final String rangeLabel;
  final ValueChanged<_Range> onRangeChanged;
  final Duration Function(_Range) windowFor;

  @override
  Widget build(BuildContext context) {
    final all = bundle?.chartPoints ?? const <_ChartPoint>[];
    final cutoffEpoch =
        DateTime.now().subtract(windowFor(range)).millisecondsSinceEpoch ~/
            1000;
    var inRange = all.where((p) => p.epoch >= cutoffEpoch).toList();
    // If the range cuts everything off (typical with fresh onboarding +
    // a single log on day 0), still show every available point so the
    // user gets a chart on first launch.
    if (inRange.length < 2 && all.length >= 2) {
      inRange = all;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xE61A0F2B), Color(0xE6120A1F)],
        ),
        border: Border.all(
          color: AppPalette.borderViolet,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Weight Trend',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.textPrimary,
                ),
              ),
              Row(
                children: [
                  for (final r in _Range.values) ...[
                    _RangeButton(
                      label: r == _Range.d30
                          ? '30D'
                          : r == _Range.d90
                              ? '90D'
                              : '1Y',
                      active: range == r,
                      onTap: () => onRangeChanged(r),
                    ),
                    if (r != _Range.values.last) const SizedBox(width: 4),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          AspectRatio(
            aspectRatio: 320 / 160,
            child: inRange.length < 2
                ? Center(
                    child: Text(
                      'Log a weight to start tracking trend.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppPalette.textMuted,
                      ),
                    ),
                  )
                : CustomPaint(painter: _ChartPainter(points: inRange)),
          ),
          const SizedBox(height: 6),
          if (inRange.length >= 2)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _shortDate(DateTime.fromMillisecondsSinceEpoch(
                    inRange.first.epoch * 1000,
                  )),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppPalette.textDim,
                  ),
                ),
                Text(
                  _shortDate(DateTime.fromMillisecondsSinceEpoch(
                    inRange[inRange.length ~/ 2].epoch * 1000,
                  )),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppPalette.textDim,
                  ),
                ),
                Text(
                  _shortDate(DateTime.fromMillisecondsSinceEpoch(
                    inRange.last.epoch * 1000,
                  )),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppPalette.textDim,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  static String _shortDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[(d.month - 1).clamp(0, 11)]} ${d.day}';
  }
}

class _RangeButton extends StatelessWidget {
  const _RangeButton({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: active
                ? AppPalette.purple.withValues(alpha: 0.20)
                : Colors.transparent,
            border: Border.all(
              color: active
                  ? AppPalette.purple.withValues(alpha: 0.40)
                  : AppPalette.purple.withValues(alpha: 0.10),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: active ? AppPalette.purpleSoft : AppPalette.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({required this.points});
  final List<_ChartPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final values = points.map((p) => p.kg).toList();
    var minY = values.reduce((a, b) => a < b ? a : b);
    var maxY = values.reduce((a, b) => a > b ? a : b);
    // Pad the range so a flat line doesn't sit on the bottom edge and
    // so a tiny range still shows clear motion on the chart.
    final span = (maxY - minY).abs();
    final pad = span < 1 ? 1.0 : span * 0.2;
    minY -= pad;
    maxY += pad;
    final w = size.width;
    final h = size.height;
    final stepX = w / (values.length - 1);

    Offset toPoint(int i) {
      final v = values[i];
      final y = h - ((v - minY) / (maxY - minY)) * h;
      return Offset(i * stepX, y);
    }

    // Area underlay (purple → transparent).
    final areaPath = Path()..moveTo(0, h);
    for (var i = 0; i < values.length; i++) {
      final p = toPoint(i);
      if (i == 0) {
        areaPath.lineTo(p.dx, p.dy);
      } else {
        areaPath.lineTo(p.dx, p.dy);
      }
    }
    areaPath.lineTo(w, h);
    areaPath.close();
    final areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppPalette.purple.withValues(alpha: 0.30),
          AppPalette.purple.withValues(alpha: 0.00),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(areaPath, areaPaint);

    // Line stroke (teal → violet gradient).
    final linePath = Path();
    for (var i = 0; i < values.length; i++) {
      final p = toPoint(i);
      if (i == 0) {
        linePath.moveTo(p.dx, p.dy);
      } else {
        linePath.lineTo(p.dx, p.dy);
      }
    }
    final linePaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppPalette.teal, AppPalette.purple],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    // Data points.
    final dotFill = Paint()..color = AppPalette.purpleSoft;
    final dotRing = Paint()
      ..color = AppPalette.voidBg
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (var i = 0; i < values.length; i++) {
      final p = toPoint(i);
      // Soft glow.
      canvas.drawCircle(
        p,
        5,
        Paint()
          ..color = AppPalette.purpleSoft.withValues(alpha: 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(p, 3, dotFill);
      canvas.drawCircle(p, 3, dotRing);
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) =>
      old.points.length != points.length ||
      old.points.any(
        (p) => !points.any(
          (q) => q.epoch == p.epoch && q.kg == p.kg,
        ),
      );
}

// ─── Log-weight bottom sheet ───────────────────────────────
//
// Numeric stepper + KG/LBS toggle + optional note. On save, calls
// `WeightLogService.upsertForDay` so the UNIQUE(user_id, logged_on)
// constraint folds same-day re-logs into a single row. Pops with
// `true` so the parent can refresh its data future.
class _LogWeightSheet extends StatefulWidget {
  const _LogWeightSheet({required this.initialWeightKg});
  final double initialWeightKg;

  @override
  State<_LogWeightSheet> createState() => _LogWeightSheetState();
}

class _LogWeightSheetState extends State<_LogWeightSheet> {
  bool _kg = true;
  late double _kgValue;
  final _noteController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _kgValue = widget.initialWeightKg > 0 ? widget.initialWeightKg : 70.0;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  double get _displayValue => _kg ? _kgValue : _kgValue * 2.20462;
  void _adjust(double deltaKg) {
    setState(() => _kgValue = (_kgValue + deltaKg).clamp(20.0, 300.0));
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final today = DateTime.now();
    final dayEpoch =
        DateTime(today.year, today.month, today.day).millisecondsSinceEpoch ~/
            1000;
    final note = _noteController.text.trim();
    await WeightLogService.upsertForDay(
      dayEpoch: dayEpoch,
      weightKg: double.parse(_kgValue.toStringAsFixed(1)),
      note: note.isEmpty ? null : note,
    );
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A0F2B), Color(0xFF0A0612)],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
            ),
            const Text(
              'LOG WEIGHT',
              style: TextStyle(
                fontSize: 22,
                fontFamily: 'BebasNeue',
                letterSpacing: 1,
                color: AppPalette.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'One log per day. Re-saving overwrites today.',
              style: TextStyle(fontSize: 12, color: AppPalette.textMuted),
            ),
            const SizedBox(height: 22),
            _UnitToggle(
              kg: _kg,
              onChange: (v) => setState(() => _kg = v),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                _StepBtn(
                  icon: Icons.remove,
                  onTap: () => _adjust(-0.5),
                ),
                Expanded(
                  child: Center(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: _displayValue.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 56,
                              fontFamily: 'BebasNeue',
                              height: 1,
                              color: AppPalette.textPrimary,
                            ),
                          ),
                          TextSpan(
                            text: _kg ? '  kg' : '  lbs',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppPalette.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                _StepBtn(
                  icon: Icons.add,
                  onTap: () => _adjust(0.5),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _noteController,
              style: const TextStyle(
                fontSize: 13,
                color: AppPalette.textPrimary,
              ),
              maxLength: 80,
              decoration: InputDecoration(
                hintText: 'Optional note (e.g. post-workout)',
                hintStyle: const TextStyle(
                  fontSize: 12,
                  color: AppPalette.textMuted,
                ),
                counterText: '',
                filled: true,
                fillColor: AppPalette.purple.withValues(alpha: 0.10),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: AppPalette.purple.withValues(alpha: 0.30),
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: AppPalette.purple.withValues(alpha: 0.30),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: AppPalette.purple.withValues(alpha: 0.55),
                    width: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _saving ? null : _save,
                borderRadius: BorderRadius.circular(14),
                child: Ink(
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppPalette.teal, AppPalette.purple],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppPalette.teal.withValues(alpha: 0.45),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                  child: Center(
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'SAVE LOG',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnitToggle extends StatelessWidget {
  const _UnitToggle({required this.kg, required this.onChange});
  final bool kg;
  final ValueChanged<bool> onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: AppPalette.purple.withValues(alpha: 0.10),
        border: Border.all(
          color: AppPalette.purple.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          for (final v in const [true, false])
            Expanded(
              child: GestureDetector(
                onTap: () => onChange(v),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: kg == v
                        ? const LinearGradient(
                            colors: [AppPalette.teal, AppPalette.purple],
                          )
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    v ? 'KG' : 'LBS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      color: kg == v
                          ? Colors.white
                          : AppPalette.textMuted,
                    ),
                  ),
                ),
              ),
            ),
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
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 52,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: AppPalette.purple.withValues(alpha: 0.15),
            border: Border.all(
              color: AppPalette.purple.withValues(alpha: 0.30),
              width: 1,
            ),
          ),
          child: Icon(icon, size: 22, color: AppPalette.purpleSoft),
        ),
      ),
    );
  }
}
