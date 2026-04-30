import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/leaderboard_entry.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/leaderboard_service.dart';
import '../../theme/tokens.dart';
import '../../widgets/in_app_shell.dart';
import '../../widgets/tab_bar.dart';

/// Friend-only leaderboard. Three tabs (Weekly XP / Streak / All-time
/// XP) on the same source — `public_profiles` rows for the user +
/// their accepted friends, ordered server-side by the active metric.
///
/// User's own row is highlighted regardless of position; an empty
/// state nudges them to add friends if they haven't yet.
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  // One future per metric; lazy-loaded on first paint of that tab.
  final Map<LeaderboardMetric, Future<List<LeaderboardEntry>>> _futures = {};

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: LeaderboardMetric.values.length, vsync: this);
    // Pre-fetch the default tab so the first paint isn't a spinner.
    _futures[LeaderboardMetric.weeklyXp] =
        LeaderboardService.fetch(LeaderboardMetric.weeklyXp);
    _tabs.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabs.removeListener(_onTabChanged);
    _tabs.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabs.indexIsChanging) return;
    final metric = LeaderboardMetric.values[_tabs.index];
    _futures.putIfAbsent(metric, () => LeaderboardService.fetch(metric));
    setState(() {});
  }

  Future<void> _refresh() async {
    final metric = LeaderboardMetric.values[_tabs.index];
    final f = LeaderboardService.fetch(metric);
    setState(() => _futures[metric] = f);
    await f;
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthService.isAuthenticated) {
      return const InAppShell(
        active: AppTab.leaderboard,
        title: 'LEADERBOARD',
        showHeader: true,
        child: _SignInPrompt(),
      );
    }
    return InAppShell(
      active: AppTab.leaderboard,
      title: 'LEADERBOARD',
      showHeader: true,
      child: Column(
        children: [
          _MetricTabs(controller: _tabs),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: LeaderboardMetric.values
                  .map((m) => _Body(
                        metric: m,
                        future: _futures[m],
                        onRefresh: _refresh,
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tabs ────────────────────────────────────────────────────────

class _MetricTabs extends StatelessWidget {
  const _MetricTabs({required this.controller});
  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpace.s5,
        AppSpace.s4,
        AppSpace.s5,
        AppSpace.s2,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppPalette.purple.withValues(alpha: 0.06),
        border: Border.all(
          color: AppPalette.purple.withValues(alpha: 0.20),
          width: 1,
        ),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppPalette.amber, AppPalette.amberSoft],
          ),
          boxShadow: [
            BoxShadow(
              color: AppPalette.amber.withValues(alpha: 0.45),
              blurRadius: 14,
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        labelColor: AppPalette.voidBg,
        unselectedLabelColor: AppPalette.textMuted,
        labelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
        dividerColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        tabs: LeaderboardMetric.values
            .map((m) => Tab(text: m.label.toUpperCase()))
            .toList(),
      ),
    );
  }
}

// ─── Per-tab body ────────────────────────────────────────────────

class _Body extends StatelessWidget {
  const _Body({
    required this.metric,
    required this.future,
    required this.onRefresh,
  });
  final LeaderboardMetric metric;
  final Future<List<LeaderboardEntry>>? future;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (future == null) {
      return const SizedBox.shrink();
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppPalette.amber,
      backgroundColor: AppPalette.obsidian,
      child: FutureBuilder<List<LeaderboardEntry>>(
        future: future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppPalette.amber),
            );
          }
          final entries = snap.data ?? const <LeaderboardEntry>[];
          if (entries.isEmpty) {
            return const _EmptyLeaderboard();
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.s5,
              AppSpace.s2,
              AppSpace.s5,
              InAppShell.tabBarSafeBottom,
            ),
            itemCount: entries.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _RankRow(
              entry: entries[i],
              metric: metric,
            ),
          );
        },
      ),
    );
  }
}

// ─── Row ─────────────────────────────────────────────────────────

class _RankRow extends StatelessWidget {
  const _RankRow({required this.entry, required this.metric});
  final LeaderboardEntry entry;
  final LeaderboardMetric metric;

  @override
  Widget build(BuildContext context) {
    final highlight = entry.isMe;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: highlight
            ? AppPalette.amber.withValues(alpha: 0.10)
            : AppPalette.purple.withValues(alpha: 0.06),
        border: Border.all(
          color: highlight
              ? AppPalette.amber.withValues(alpha: 0.55)
              : AppPalette.purple.withValues(alpha: 0.20),
          width: 1,
        ),
        boxShadow: highlight
            ? [
                BoxShadow(
                  color: AppPalette.amber.withValues(alpha: 0.30),
                  blurRadius: 14,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          _RankBadge(rank: entry.rank),
          const SizedBox(width: 12),
          _Avatar(displayName: entry.displayName),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.displayName.isEmpty
                      ? '@${entry.username}'
                      : entry.displayName + (highlight ? ' (you)' : ''),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '@${entry.username} · LV ${entry.level}',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppPalette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _MetricChip(value: entry.valueFor(metric), metric: metric),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});
  final int rank;

  Color get _accentColor {
    if (rank == 1) return AppPalette.amber;
    if (rank == 2) return AppPalette.purpleSoft;
    if (rank == 3) return AppPalette.tealDim;
    return AppPalette.textDisabled;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      alignment: Alignment.center,
      child: Text(
        '#$rank',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: _accentColor,
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.displayName});
  final String displayName;

  String get _initial {
    final t = displayName.trim();
    return t.isEmpty ? '?' : t.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppPalette.purpleDeep, AppPalette.purple],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        _initial,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: AppPalette.textPrimary,
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.value, required this.metric});
  final int value;
  final LeaderboardMetric metric;

  String get _suffix => switch (metric) {
        LeaderboardMetric.weeklyXp => 'XP',
        LeaderboardMetric.totalXp => 'XP',
        LeaderboardMetric.currentStreak => '🔥',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: AppPalette.amber.withValues(alpha: 0.14),
        border: Border.all(
          color: AppPalette.amber.withValues(alpha: 0.40),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppPalette.amber,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            _suffix,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppPalette.amber,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty + sign-in states ──────────────────────────────────────

class _EmptyLeaderboard extends StatelessWidget {
  const _EmptyLeaderboard();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpace.s8),
      children: [
        const SizedBox(height: 60),
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppPalette.purple.withValues(alpha: 0.08),
              border: Border.all(
                color: AppPalette.purple.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.leaderboard_outlined,
              size: 44,
              color: AppPalette.purpleSoft,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'No friends to rank against yet.',
          textAlign: TextAlign.center,
          style: AppType.label(color: AppPalette.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          'Add a few friends — your row appears here as soon as someone\'s in the list.',
          textAlign: TextAlign.center,
          style: AppType.bodyMD(color: AppPalette.textMuted),
        ),
        const SizedBox(height: 24),
        Center(
          child: TextButton(
            onPressed: () =>
                GoRouter.of(context).go('/friends/search'),
            child: Text(
              'Find friends',
              style: AppType.label(color: AppPalette.amber),
            ),
          ),
        ),
      ],
    );
  }
}

class _SignInPrompt extends StatelessWidget {
  const _SignInPrompt();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.s8),
        child: Text(
          'Sign in to compete with friends.',
          textAlign: TextAlign.center,
          style: AppType.bodyMD(color: AppPalette.textMuted),
        ),
      ),
    );
  }
}
