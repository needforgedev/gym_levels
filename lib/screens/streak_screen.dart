import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/schedule_row.dart';
import '../data/models/streak.dart';
import '../data/models/workout.dart';
import '../data/services/schedule_service.dart';
import '../data/services/streak_service.dart';
import '../data/services/workout_service.dart';
import '../state/player_state.dart';
import '../theme/tokens.dart';
import '../widgets/in_app_shell.dart';
import '../widgets/tab_bar.dart';

/// Streak screen — matches design v2 (`design/v2/screens-progress.jsx`
/// `StreakScreen`).
///
/// Layout (top → bottom):
///   • Centered "Streak" small title.
///   • Hero row: pulsing flame icon + huge streak number with glow,
///     followed by "day streak · On fire!" caption.
///   • "N THIS MONTH" amber pill.
///   • Streak Freezes card (snowflake icon block + count + 2 small
///     snowflake chips on the right).
///   • Month calendar card: arrows + month name, S/M/T/W/T/F/S header,
///     7-column grid where each cell is amber (completed), teal (frozen),
///     red (missed), or violet (rest/idle), with today highlighted.
///   • Legend strip with 3 swatches.
class StreakScreen extends StatefulWidget {
  const StreakScreen({super.key});

  @override
  State<StreakScreen> createState() => _StreakScreenState();
}

enum _DayKind { future, rest, completed, frozen, missed, today }

class _CellSpec {
  const _CellSpec({required this.day, required this.kind});
  final int day;
  final _DayKind kind;
}

class _StreakBundle {
  const _StreakBundle({
    required this.streak,
    required this.cells,
    required this.workoutsThisMonth,
    required this.monthName,
    required this.year,
    required this.firstWeekday,
    required this.daysInMonth,
  });
  final Streak? streak;
  final List<_CellSpec> cells;
  final int workoutsThisMonth;
  final String monthName;
  final int year;

  /// Sunday=0..Saturday=6 — what column day 1 starts in.
  final int firstWeekday;
  final int daysInMonth;
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
      WorkoutService.recent(limit: 200),
      ScheduleService.get(),
    ]);
    final streak = results[0] as Streak?;
    final recent = results[1] as List<Workout>;
    final schedule = results[2] as ScheduleRow?;

    // Workout-day set for the month being shown (current month).
    final workoutDays = <String>{};
    for (final w in recent) {
      final end = w.endedAt;
      if (end == null) continue;
      final d = DateTime.fromMillisecondsSinceEpoch(end * 1000).toLocal();
      workoutDays.add(_ymd(DateTime(d.year, d.month, d.day)));
    }

    final scheduleDays = schedule?.days.toSet() ?? <int>{};
    final now = DateTime.now();
    final firstOfMonth = DateTime(now.year, now.month, 1);
    final daysInMonth =
        DateTime(now.year, now.month + 1, 0).day; // last day of month
    // Sunday=0..Saturday=6 (DateTime.weekday: Mon=1..Sun=7)
    final firstCol = firstOfMonth.weekday % 7;

    final cells = <_CellSpec>[];
    var workoutsThisMonth = 0;
    for (var d = 1; d <= daysInMonth; d++) {
      final date = DateTime(now.year, now.month, d);
      final key = _ymd(date);
      final isToday = d == now.day;
      final didWorkout = workoutDays.contains(key);
      final weekdayIdx = (date.weekday - 1) % 7; // 0=Mon..6=Sun
      final isScheduled = scheduleDays.contains(weekdayIdx);
      final isFuture = date.isAfter(DateTime(now.year, now.month, now.day));

      _DayKind kind;
      if (didWorkout) {
        workoutsThisMonth += 1;
        kind = _DayKind.completed;
      } else if (isToday) {
        kind = _DayKind.today;
      } else if (isFuture) {
        kind = _DayKind.future;
      } else if (isScheduled) {
        kind = _DayKind.missed;
      } else {
        kind = _DayKind.rest;
      }
      cells.add(_CellSpec(day: d, kind: kind));
    }

    return _StreakBundle(
      streak: streak,
      cells: cells,
      workoutsThisMonth: workoutsThisMonth,
      monthName: _monthName(now.month),
      year: now.year,
      firstWeekday: firstCol,
      daysInMonth: daysInMonth,
    );
  }

  static String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, "0")}-${d.day.toString().padLeft(2, "0")}';

  static String _monthName(int m) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return names[(m - 1).clamp(0, 11)];
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<PlayerState>();
    return InAppShell(
      active: AppTab.streak,
      title: 'STREAK',
      showHeader: false,
      child: FutureBuilder<_StreakBundle>(
        future: _future,
        builder: (ctx, snap) {
          final bundle = snap.data;
          return ListView(
            padding: EdgeInsets.fromLTRB(
              0,
              0,
              0,
              InAppShell.tabBarSafeBottom +
                  MediaQuery.of(context).padding.bottom,
            ),
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Center(
                  child: Text(
                    'Streak',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppPalette.textPrimary,
                    ),
                  ),
                ),
              ),
              // Hero number.
              _HeroNumber(streak: s.streak),
              const SizedBox(height: 16),
              // 'N THIS MONTH' pill.
              Center(
                child: _ThisMonthPill(count: bundle?.workoutsThisMonth ?? 0),
              ),
              const SizedBox(height: 16),
              // Freezes card.
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: _FreezesCard(available: 2, total: 2),
              ),
              const SizedBox(height: 16),
              // Calendar.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _CalendarCard(bundle: bundle),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Hero flame + number ───────────────────────────────────
class _HeroNumber extends StatefulWidget {
  const _HeroNumber({required this.streak});
  final int streak;

  @override
  State<_HeroNumber> createState() => _HeroNumberState();
}

class _HeroNumberState extends State<_HeroNumber>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _ctl,
            builder: (context, _) {
              final t = _ctl.value;
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_fire_department,
                    size: 52,
                    color: AppPalette.streak,
                    shadows: [
                      Shadow(
                        color: AppPalette.streak.withValues(
                          alpha: 0.5 + 0.4 * t,
                        ),
                        blurRadius: 6 + t * 8,
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${widget.streak}',
                    style: TextStyle(
                      fontSize: 96,
                      fontFamily: 'BebasNeue',
                      height: 0.9,
                      color: AppPalette.streak,
                      shadows: [
                        Shadow(
                          color: AppPalette.streak.withValues(alpha: 0.6),
                          blurRadius: 24,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text: 'day streak · ',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppPalette.textMuted,
                  ),
                ),
                TextSpan(
                  text: widget.streak == 0 ? 'Light it up' : 'On fire!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                    color: AppPalette.streak,
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

// ─── This-month pill ──────────────────────────────────────
class _ThisMonthPill extends StatelessWidget {
  const _ThisMonthPill({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: AppPalette.streak.withValues(alpha: 0.15),
        border: Border.all(
          color: AppPalette.streak.withValues(alpha: 0.40),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_month, size: 12, color: AppPalette.streak),
          const SizedBox(width: 6),
          Text(
            '$count THIS MONTH',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppPalette.streak,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Freezes card ──────────────────────────────────────────
class _FreezesCard extends StatelessWidget {
  const _FreezesCard({required this.available, required this.total});
  final int available;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppPalette.teal.withValues(alpha: 0.12),
              border: Border.all(
                color: AppPalette.teal.withValues(alpha: 0.30),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.ac_unit,
              size: 20,
              color: AppPalette.teal,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Streak Freezes — $available/$total available',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  available == total
                      ? 'All freezes available'
                      : '$available available · ${total - available} used',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppPalette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              for (var i = 0; i < total; i++) ...[
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: i < available
                        ? AppPalette.teal.withValues(alpha: 0.15)
                        : AppPalette.purple.withValues(alpha: 0.06),
                    border: Border.all(
                      color: i < available
                          ? AppPalette.teal.withValues(alpha: 0.40)
                          : AppPalette.purple.withValues(alpha: 0.20),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.ac_unit,
                    size: 14,
                    color: i < available
                        ? AppPalette.teal
                        : AppPalette.textDim,
                  ),
                ),
                if (i < total - 1) const SizedBox(width: 4),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Calendar card ─────────────────────────────────────────
class _CalendarCard extends StatelessWidget {
  const _CalendarCard({required this.bundle});
  final _StreakBundle? bundle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
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
          // Month nav row.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _NavArrow(
                icon: Icons.chevron_left,
                onTap: () {},
              ),
              Text(
                bundle == null
                    ? '—'
                    : '${bundle!.monthName} ${bundle!.year}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.textPrimary,
                ),
              ),
              _NavArrow(
                icon: Icons.chevron_right,
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Day-of-week header.
          Row(
            children: [
              for (final l in const ['S', 'M', 'T', 'W', 'T', 'F', 'S'])
                Expanded(
                  child: Center(
                    child: Text(
                      l,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppPalette.textMuted,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          // Calendar grid.
          if (bundle != null) _Grid(bundle: bundle!),
          const SizedBox(height: 14),
          // Legend.
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _LegendItem(color: AppPalette.amber, label: 'Completed'),
              _LegendItem(color: AppPalette.teal, label: 'Freeze'),
              _LegendItem(color: AppPalette.streak, label: 'Missed'),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavArrow extends StatelessWidget {
  const _NavArrow({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 16, color: AppPalette.textMuted),
        ),
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.bundle});
  final _StreakBundle bundle;

  @override
  Widget build(BuildContext context) {
    // Pad the front so day 1 lands in its real weekday column.
    final blanks = bundle.firstWeekday;
    final cells = <Widget>[
      for (var i = 0; i < blanks; i++) const SizedBox.shrink(),
      for (final spec in bundle.cells) _DayCell(spec: spec),
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 7,
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      children: cells,
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.spec});
  final _CellSpec spec;

  @override
  Widget build(BuildContext context) {
    Color bg = AppPalette.purple.withValues(alpha: 0.05);
    Color borderColor = AppPalette.purple.withValues(alpha: 0.10);
    Color text = AppPalette.textDim;
    BoxBorder? border = Border.all(color: borderColor, width: 1);
    BoxShadow? glow;

    switch (spec.kind) {
      case _DayKind.completed:
        bg = AppPalette.amber.withValues(alpha: 0.55);
        borderColor = AppPalette.amber.withValues(alpha: 0.60);
        border = Border.all(color: borderColor, width: 1);
        text = AppPalette.voidBg;
        break;
      case _DayKind.frozen:
        bg = AppPalette.teal.withValues(alpha: 0.20);
        borderColor = AppPalette.teal.withValues(alpha: 0.55);
        border = Border.all(color: borderColor, width: 1);
        text = AppPalette.teal;
        break;
      case _DayKind.missed:
        bg = AppPalette.streak.withValues(alpha: 0.12);
        borderColor = AppPalette.streak.withValues(alpha: 0.40);
        border = Border.all(
          color: borderColor,
          width: 1,
          style: BorderStyle.solid,
        );
        text = AppPalette.streak;
        break;
      case _DayKind.today:
        bg = AppPalette.purple.withValues(alpha: 0.15);
        borderColor = AppPalette.purple.withValues(alpha: 0.60);
        border = Border.all(color: borderColor, width: 2);
        text = AppPalette.purpleSoft;
        glow = BoxShadow(
          color: AppPalette.purple.withValues(alpha: 0.55),
          blurRadius: 12,
        );
        break;
      case _DayKind.future:
        text = AppPalette.textDim;
        break;
      case _DayKind.rest:
        text = AppPalette.textMuted;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: bg,
        border: border,
        boxShadow: glow != null ? [glow] : null,
      ),
      alignment: Alignment.center,
      child: Text(
        '${spec.day}',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: text,
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppPalette.textMuted,
          ),
        ),
      ],
    );
  }
}
