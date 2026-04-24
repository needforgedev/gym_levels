import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/schedule_row.dart';
import '../data/models/streak.dart';
import '../data/models/workout.dart';
import '../data/services/schedule_service.dart';
import '../data/services/streak_service.dart';
import '../data/services/workout_service.dart';
import '../game/streak_engine.dart';
import '../state/player_state.dart';
import '../theme/tokens.dart';
import '../widgets/big_flame.dart';
import '../widgets/in_app_shell.dart';
import '../widgets/neon_card.dart';
import '../widgets/tab_bar.dart';

/// Which glyph a given calendar cell renders. `today` wins over everything;
/// `workout` beats `rest` when the user trained off-schedule on a rest day.
enum _DayType { workout, rest, miss, today, future }

class _CellSpec {
  const _CellSpec({required this.type, required this.date});
  final _DayType type;
  final DateTime date;
}

class _StreakBundle {
  const _StreakBundle({
    required this.streak,
    required this.cells,
    required this.workoutsThisMonth,
    required this.monthLabel,
  });
  final Streak? streak;
  final List<_CellSpec> cells;
  final int workoutsThisMonth;
  final String monthLabel;
}

class StreakScreen extends StatefulWidget {
  const StreakScreen({super.key});

  @override
  State<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends State<StreakScreen> {
  late Future<_StreakBundle> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_StreakBundle> _load() async {
    final results = await Future.wait([
      StreakService.get(),
      WorkoutService.recent(limit: 60),
      ScheduleService.get(),
    ]);
    final streak = results[0] as Streak?;
    final recent = results[1] as List<Workout>;
    final schedule = results[2] as ScheduleRow?;

    // Build a set of local dates on which the user logged a finished
    // workout. Key is `yyyy-mm-dd` in the device's local zone so it lines
    // up with the calendar cells.
    final workoutDays = <String>{};
    for (final w in recent) {
      final end = w.endedAt;
      if (end == null) continue;
      final d = DateTime.fromMillisecondsSinceEpoch(end * 1000).toLocal();
      workoutDays.add(_ymd(DateTime(d.year, d.month, d.day)));
    }

    final scheduleDays = schedule?.days.toSet() ?? <int>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 30-day rolling window ending today — day 0 is 29 days ago, day 29 is
    // today. Matches the hero copy "last 30 days".
    final cells = <_CellSpec>[];
    var workoutsCount = 0;
    for (var i = 29; i >= 0; i--) {
      final d = today.subtract(Duration(days: i));
      final key = _ymd(d);
      final isToday = i == 0;
      final didWorkout = workoutDays.contains(key);
      // weekday: Mon=1..Sun=7 in Dart, our schedule uses Mon=0..Sun=6.
      final weekdayIdx = (d.weekday - 1) % 7;
      final isScheduled = scheduleDays.contains(weekdayIdx);

      final _DayType type;
      if (didWorkout) {
        workoutsCount += 1;
        type = _DayType.workout;
      } else if (isToday) {
        type = _DayType.today;
      } else if (isScheduled) {
        type = _DayType.miss;
      } else {
        type = _DayType.rest;
      }
      cells.add(_CellSpec(type: type, date: d));
    }

    final monthLabel =
        '${_monthShort(today.month)} ${today.year}'.toUpperCase();

    return _StreakBundle(
      streak: streak,
      cells: cells,
      workoutsThisMonth: workoutsCount,
      monthLabel: monthLabel,
    );
  }

  static String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, "0")}-${d.day.toString().padLeft(2, "0")}';

  static String _monthShort(int m) {
    const names = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];
    return names[(m - 1).clamp(0, 11)];
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<PlayerState>();
    return InAppShell(
      active: AppTab.streak,
      title: 'STREAK',
      child: FutureBuilder<_StreakBundle>(
        future: _future,
        builder: (ctx, snap) {
          final bundle = snap.data;
          final current = s.streak;
          final longest = bundle?.streak?.longest ?? current;
          final nextMilestone = _nextMilestone(current);
          final heroTitle = _heroTitle(current);

          return ListView(
            padding: const EdgeInsets.all(AppSpace.s5),
            children: [
              _HeroCard(
                current: current,
                longest: longest,
                heroTitle: heroTitle,
                nextMilestone: nextMilestone,
              ),
              const SizedBox(height: AppSpace.s4),
              if (bundle != null)
                _CalendarCard(
                  cells: bundle.cells,
                  monthLabel: bundle.monthLabel,
                  workoutsCount: bundle.workoutsThisMonth,
                )
              else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpace.s6),
                  child: Center(
                    child: CircularProgressIndicator(color: AppPalette.flame),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Returns (target, daysToGo) for the next milestone up from `current`,
  /// or null once the user has passed every milestone.
  static ({int target, int daysToGo})? _nextMilestone(int current) {
    for (final m in StreakEngine.milestones) {
      if (current < m) return (target: m, daysToGo: m - current);
    }
    return null;
  }

  static String _heroTitle(int current) {
    if (current == 0) return 'START THE FIRE';
    if (current < 3) return 'WARMING UP';
    if (current < 7) return 'PICKING UP';
    if (current < 14) return 'ON FIRE';
    if (current < 30) return 'BLAZING';
    if (current < 60) return 'INFERNO';
    if (current < 180) return 'UNSTOPPABLE';
    return 'LEGENDARY';
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.current,
    required this.longest,
    required this.heroTitle,
    required this.nextMilestone,
  });

  final int current;
  final int longest;
  final String heroTitle;
  final ({int target, int daysToGo})? nextMilestone;

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      glow: GlowColor.flame,
      padding: const EdgeInsets.all(AppSpace.s7),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const BigFlame(),
                Text(
                  '$current',
                  style: AppType.monoXL(color: AppPalette.obsidian).copyWith(
                    fontSize: 36,
                    height: 1,
                    shadows: [
                      Shadow(
                        color: AppPalette.flame,
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.s6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DAY STREAK · BEST $longest',
                  style: AppType.label(color: AppPalette.flame),
                ),
                const SizedBox(height: 2),
                Text(
                  heroTitle,
                  style: AppType.displayLG(color: AppPalette.textPrimary),
                ),
                const SizedBox(height: 6),
                _MilestoneLine(current: current, next: nextMilestone),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MilestoneLine extends StatelessWidget {
  const _MilestoneLine({required this.current, required this.next});
  final int current;
  final ({int target, int daysToGo})? next;

  @override
  Widget build(BuildContext context) {
    if (next == null) {
      return Text(
        'Every milestone cleared. You are the fire.',
        style: AppType.bodySM(color: AppPalette.textSecondary),
      );
    }
    final m = next!;
    return Text.rich(
      TextSpan(
        style: AppType.bodySM(color: AppPalette.textSecondary),
        children: [
          const TextSpan(text: 'Next milestone: '),
          TextSpan(
            text: '${m.target} days',
            style: AppType.bodySM(color: AppPalette.xpGold),
          ),
          TextSpan(
            text: current == 0
                ? ' — log a workout to begin.'
                : ' — ${m.daysToGo} to go.',
          ),
        ],
      ),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({
    required this.cells,
    required this.monthLabel,
    required this.workoutsCount,
  });

  final List<_CellSpec> cells;
  final String monthLabel;
  final int workoutsCount;

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      glow: GlowColor.none,
      padding: const EdgeInsets.all(AppSpace.s4),
      pulse: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LAST 30 · $monthLabel',
                style: AppType.label(color: AppPalette.textMuted),
              ),
              Text(
                '$workoutsCount / 30 DAYS',
                style: AppType.label(color: AppPalette.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: const ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((d) {
              return Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: AppType.label(color: AppPalette.textMuted)
                        .copyWith(fontSize: 10),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 4),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            // Pad the front so the first cell aligns to its real weekday
            // column. Dart weekday Mon=1..Sun=7; grid is Mon..Sun.
            children: [
              for (var i = 0; i < _leadingBlanks(cells); i++)
                const SizedBox.shrink(),
              for (final c in cells) _DayCell(spec: c),
            ],
          ),
          const SizedBox(height: AppSpace.s4),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            children: const [
              _Legend(color: AppPalette.xpGold, label: 'WORKOUT'),
              _Legend(
                color: Colors.transparent,
                borderColor: AppPalette.purple,
                label: 'REST'),
              _Legend(color: AppPalette.carbon, label: 'MISSED'),
              _Legend(
                color: Colors.transparent,
                borderColor: AppPalette.teal,
                label: 'TODAY'),
            ],
          ),
        ],
      ),
    );
  }

  static int _leadingBlanks(List<_CellSpec> cells) {
    if (cells.isEmpty) return 0;
    // Grid column: Mon=0..Sun=6.
    final firstCol = (cells.first.date.weekday - 1) % 7;
    return firstCol;
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.spec});
  final _CellSpec spec;

  @override
  Widget build(BuildContext context) {
    final base = BoxDecoration(borderRadius: BorderRadius.circular(4));
    switch (spec.type) {
      case _DayType.workout:
        return Container(
          decoration: base.copyWith(
            color: AppPalette.xpGold,
            boxShadow: [
              BoxShadow(
                color: AppPalette.xpGold.withValues(alpha: 0.5),
                blurRadius: 4,
              ),
            ],
          ),
        );
      case _DayType.rest:
        return Container(
          decoration: base.copyWith(
            color: AppPalette.purple.withValues(alpha: 0.07),
            border: Border.all(color: AppPalette.purple),
          ),
        );
      case _DayType.miss:
        return Container(
          decoration: base.copyWith(
            color: AppPalette.carbon,
            border: Border.all(color: AppPalette.strokeHairline),
          ),
        );
      case _DayType.today:
        return Container(
          decoration: base.copyWith(
            border: Border.all(color: AppPalette.teal, width: 2),
            boxShadow: [
              BoxShadow(color: AppPalette.teal, blurRadius: 10),
            ],
          ),
        );
      case _DayType.future:
        return const SizedBox.shrink();
    }
  }
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.color,
    required this.label,
    this.borderColor,
  });

  final Color color;
  final Color? borderColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: borderColor != null ? Border.all(color: borderColor!) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style:
              AppType.label(color: AppPalette.textMuted).copyWith(fontSize: 9),
        ),
      ],
    );
  }
}
