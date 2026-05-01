import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/leaderboard_entry.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/leaderboard_service.dart';
import '../../theme/tokens.dart';
import '../../widgets/in_app_shell.dart';
import '../../widgets/tab_bar.dart';

/// **Hall of Glory** — friend-only leaderboard.
///
/// Layout (top → bottom, per `screens-leaderboard.jsx`):
///   1. **XP-to-rank banner** — bolt-circle + "X XP to rank #N" copy
///      + Train Now CTA. Pinned to the top to catch the eye.
///   2. **Header block** — "◆ HALL OF GLORY ◆" mono kicker + amber
///      gradient "LEADERBOARD" display title.
///   3. **Scope toggle** — `FRIENDS` / `CLASS` / `GLOBAL`. Only
///      `FRIENDS` is wired in v1.x.0; the other two surface a "coming
///      soon" snackbar (per locked decision: only contact + username
///      search are real, rest cosmetic).
///   4. **Period tabs** — `This Week` / `Streak` / `All Time`. Maps
///      directly onto our existing `LeaderboardMetric` enum — same
///      `LeaderboardService.fetch()` call per tab.
///   5. **Top-3 podium** — gold #1 (with bobbing crown), violet #2,
///      bronze #3. Pillars beneath each with rank number + XP.
///   6. **Rank 4 — N list** — standard rows. The current user's row
///      is highlighted with an amber border + "YOU" pill.
///
/// Data plumbing preserved unchanged from the previous version:
/// `LeaderboardService.fetch(metric)` reads `public_profiles` rows
/// for `me + accepted friends`, ordered server-side. Lazy-loaded per
/// metric, pull-to-refresh per tab.
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

enum _Scope { friends, classGroup, global }

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  LeaderboardMetric _metric = LeaderboardMetric.weeklyXp;
  _Scope _scope = _Scope.friends;
  // One future per metric; lazy-loaded on first paint.
  final Map<LeaderboardMetric, Future<List<LeaderboardEntry>>> _futures = {};

  @override
  void initState() {
    super.initState();
    _futures[_metric] = LeaderboardService.fetch(_metric);
  }

  void _setMetric(LeaderboardMetric m) {
    if (_metric == m) return;
    setState(() {
      _metric = m;
      _futures.putIfAbsent(m, () => LeaderboardService.fetch(m));
    });
  }

  void _setScope(_Scope s) {
    if (s == _Scope.friends) {
      setState(() => _scope = s);
      return;
    }
    // Class + Global are cosmetic in v1.x.0 — surface a "coming soon"
    // toast and leave the toggle on Friends.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          s == _Scope.classGroup
              ? 'Class leaderboards drop in v1.x.1.'
              : 'Global leaderboards drop in v1.x.1.',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _refresh() async {
    final f = LeaderboardService.fetch(_metric);
    setState(() => _futures[_metric] = f);
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
      showHeader: false,
      child: Stack(
        children: [
          // Ambient gold radial wash at the top — sets the tone.
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 360,
            child: IgnorePointer(child: _AmbientGoldGlow()),
          ),
          RefreshIndicator(
            onRefresh: _refresh,
            color: AppPalette.amber,
            backgroundColor: AppPalette.obsidian,
            child: FutureBuilder<List<LeaderboardEntry>>(
              future: _futures[_metric],
              builder: (context, snap) {
                final entries = snap.data ?? const <LeaderboardEntry>[];
                final loading = snap.connectionState == ConnectionState.waiting;
                final me = entries.firstWhere(
                  (e) => e.isMe,
                  orElse: () => const LeaderboardEntry(
                    userId: '',
                    username: '',
                    displayName: '',
                    level: 1,
                    totalXp: 0,
                    weeklyXp: 0,
                    monthlyXp: 0,
                    currentStreak: 0,
                    longestStreak: 0,
                    rank: 0,
                    isMe: true,
                  ),
                );
                return ListView(
                  padding: EdgeInsets.fromLTRB(
                    0,
                    MediaQuery.of(context).padding.top + 14,
                    0,
                    InAppShell.tabBarSafeBottom +
                        MediaQuery.of(context).padding.bottom,
                  ),
                  children: [
                    _XpToRankBanner(
                      me: me.userId.isEmpty ? null : me,
                      entries: entries,
                      metric: _metric,
                      onTrainNow: () => GoRouter.of(context).go('/home'),
                    ),
                    const SizedBox(height: 16),
                    const _HallOfGloryHeader(),
                    const SizedBox(height: 14),
                    _ScopeToggle(scope: _scope, onChange: _setScope),
                    const SizedBox(height: 8),
                    _PeriodTabs(metric: _metric, onChange: _setMetric),
                    const SizedBox(height: 16),
                    if (loading && entries.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 60),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppPalette.amber,
                          ),
                        ),
                      )
                    else if (entries.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 24),
                        child: _EmptyLeaderboard(),
                      )
                    else ...[
                      if (entries.length >= 3) ...[
                        _PodiumRow(top3: entries.take(3).toList(), metric: _metric),
                        const SizedBox(height: 24),
                      ],
                      _RankSection(
                        entries: entries.length >= 3
                            ? entries.skip(3).toList()
                            : entries,
                        metric: _metric,
                        startsFromRank: entries.length >= 3 ? 4 : 1,
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Ambient gold glow ───────────────────────────────────────────

class _AmbientGoldGlow extends StatelessWidget {
  const _AmbientGoldGlow();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -1.0),
          radius: 1.0,
          colors: [
            AppPalette.amber.withValues(alpha: 0.28),
            Colors.transparent,
          ],
          stops: const [0, 0.65],
        ),
      ),
    );
  }
}

// ─── XP-to-rank banner ───────────────────────────────────────────

class _XpToRankBanner extends StatelessWidget {
  const _XpToRankBanner({
    required this.me,
    required this.entries,
    required this.metric,
    required this.onTrainNow,
  });
  final LeaderboardEntry? me;
  final List<LeaderboardEntry> entries;
  final LeaderboardMetric metric;
  final VoidCallback onTrainNow;

  ({int xpDiff, int targetRank})? _computeGap() {
    if (me == null || me!.rank <= 1) return null;
    final myRank = me!.rank;
    final ahead = entries.firstWhere(
      (e) => e.rank == myRank - 1,
      orElse: () => me!,
    );
    if (ahead.userId == me!.userId) return null;
    final aheadValue = ahead.valueFor(metric);
    final myValue = me!.valueFor(metric);
    final diff = (aheadValue - myValue).clamp(0, 1 << 31);
    if (diff == 0) return null;
    return (xpDiff: diff, targetRank: myRank - 1);
  }

  @override
  Widget build(BuildContext context) {
    final gap = _computeGap();
    final headline = gap == null
        ? 'You hold the throne'
        : '${_format(gap.xpDiff)} ${metric == LeaderboardMetric.currentStreak ? 'days' : 'XP'} to rank #${gap.targetRank}';
    final sub = gap == null
        ? 'No one above. Hold it.'
        : 'Train this week to climb the ranks';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppPalette.amber.withValues(alpha: 0.18),
              AppPalette.purple.withValues(alpha: 0.12),
            ],
          ),
          border: Border.all(
            color: AppPalette.amber.withValues(alpha: 0.6),
          ),
          boxShadow: [
            BoxShadow(
              color: AppPalette.amber.withValues(alpha: 0.45),
              blurRadius: 24,
              spreadRadius: -6,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // Bolt circle.
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppPalette.amber.withValues(alpha: 0.22),
                border: Border.all(
                  color: AppPalette.amber.withValues(alpha: 0.65),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppPalette.amber.withValues(alpha: 0.6),
                    blurRadius: 14,
                    spreadRadius: -2,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.bolt,
                size: 18,
                color: AppPalette.amber,
              ),
            ),
            const SizedBox(width: 12),
            // Headline + sub.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    headline,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppPalette.textPrimary,
                      height: 1.2,
                      shadows: gap == null
                          ? null
                          : [
                              Shadow(
                                color:
                                    AppPalette.amber.withValues(alpha: 0.4),
                                blurRadius: 8,
                              ),
                            ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: AppPalette.purpleSoft.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Train Now CTA.
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTrainNow,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFBBF24), AppPalette.amber],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppPalette.amber.withValues(alpha: 0.55),
                        blurRadius: 12,
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: Text(
                    'TRAIN NOW',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      color: AppPalette.voidBg,
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

  static String _format(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final fromEnd = s.length - i;
      buf.write(s[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }
}

// ─── Header (HALL OF GLORY / LEADERBOARD) ────────────────────────

class _HallOfGloryHeader extends StatelessWidget {
  const _HallOfGloryHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Text(
            '◆ HALL OF GLORY ◆',
            style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 10,
              letterSpacing: 3,
              fontWeight: FontWeight.w700,
              color: AppPalette.amber,
            ),
          ),
          const SizedBox(height: 6),
          ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFBBF24),
                AppPalette.amber,
                Color(0xFFFCD34D),
              ],
              stops: [0, 0.5, 1.0],
            ).createShader(rect),
            child: Text(
              'LEADERBOARD',
              style: AppType.displayLG(color: Colors.white).copyWith(
                fontSize: 38,
                height: 1,
                letterSpacing: 2,
                shadows: [
                  Shadow(
                    color: AppPalette.amber.withValues(alpha: 0.4),
                    blurRadius: 24,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Scope toggle ────────────────────────────────────────────────

class _ScopeToggle extends StatelessWidget {
  const _ScopeToggle({required this.scope, required this.onChange});
  final _Scope scope;
  final ValueChanged<_Scope> onChange;

  @override
  Widget build(BuildContext context) {
    const items = [
      (_Scope.friends, 'Friends'),
      (_Scope.classGroup, 'Class'),
      (_Scope.global, 'Global'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Expanded(
              child: _ScopeButton(
                label: items[i].$2,
                active: scope == items[i].$1,
                onTap: () => onChange(items[i].$1),
              ),
            ),
            if (i < items.length - 1) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class _ScopeButton extends StatelessWidget {
  const _ScopeButton({
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
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: active
                ? AppPalette.amber.withValues(alpha: 0.15)
                : AppPalette.bgCard.withValues(alpha: 0.7),
            border: Border.all(
              color: active
                  ? AppPalette.amber.withValues(alpha: 0.55)
                  : AppPalette.purpleSoft.withValues(alpha: 0.2),
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppPalette.amber.withValues(alpha: 0.25),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: active ? AppPalette.amber : AppPalette.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Period tabs (under-score-style, maps to LeaderboardMetric) ──

class _PeriodTabs extends StatelessWidget {
  const _PeriodTabs({required this.metric, required this.onChange});
  final LeaderboardMetric metric;
  final ValueChanged<LeaderboardMetric> onChange;

  @override
  Widget build(BuildContext context) {
    const items = [
      (LeaderboardMetric.weeklyXp, 'This Week'),
      (LeaderboardMetric.monthlyXp, 'Month'),
      (LeaderboardMetric.totalXp, 'All Time'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final item in items) ...[
            _PeriodButton(
              label: item.$2,
              active: metric == item.$1,
              onTap: () => onChange(item.$1),
            ),
            const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }
}

class _PeriodButton extends StatelessWidget {
  const _PeriodButton({
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
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 4, 10, 6),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? const Color(0xFFFBBF24) : Colors.transparent,
                width: 1.2,
              ),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: active
                  ? const Color(0xFFFBBF24)
                  : AppPalette.textDisabled,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Top-3 podium ────────────────────────────────────────────────

class _PodiumRow extends StatelessWidget {
  const _PodiumRow({required this.top3, required this.metric});
  final List<LeaderboardEntry> top3;
  final LeaderboardMetric metric;

  @override
  Widget build(BuildContext context) {
    final first = top3[0];
    final second = top3[1];
    final third = top3[2];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            flex: 10,
            child: _PodiumCard(
              entry: second,
              place: 2,
              height: 120,
              accent: AppPalette.purpleSoft,
              metric: metric,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 11,
            child: _PodiumCard(
              entry: first,
              place: 1,
              height: 150,
              accent: AppPalette.amber,
              showCrown: true,
              metric: metric,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 10,
            child: _PodiumCard(
              entry: third,
              place: 3,
              height: 100,
              accent: const Color(0xFFCD7F32),
              metric: metric,
            ),
          ),
        ],
      ),
    );
  }
}

class _PodiumCard extends StatefulWidget {
  const _PodiumCard({
    required this.entry,
    required this.place,
    required this.height,
    required this.accent,
    required this.metric,
    this.showCrown = false,
  });

  final LeaderboardEntry entry;
  final int place;
  final double height;
  final Color accent;
  final LeaderboardMetric metric;
  final bool showCrown;

  @override
  State<_PodiumCard> createState() => _PodiumCardState();
}

class _PodiumCardState extends State<_PodiumCard>
    with SingleTickerProviderStateMixin {
  AnimationController? _crownBob;

  @override
  void initState() {
    super.initState();
    if (widget.showCrown) {
      _crownBob = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2400),
      )..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _crownBob?.dispose();
    super.dispose();
  }

  String _initial() {
    final n = widget.entry.displayName.isEmpty
        ? widget.entry.username
        : widget.entry.displayName;
    return n.isEmpty ? '?' : n.substring(0, 1).toUpperCase();
  }

  String _xpLabel() {
    final value = widget.entry.valueFor(widget.metric);
    if (widget.metric == LeaderboardMetric.currentStreak) {
      return '$value';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return '$value';
  }

  String _xpSuffix() => widget.metric == LeaderboardMetric.currentStreak
      ? 'DAYS'
      : 'XP';

  @override
  Widget build(BuildContext context) {
    final isFirst = widget.place == 1;
    final avatarSize = isFirst ? 64.0 : 52.0;
    final accent = widget.accent;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Bobbing crown for #1.
        if (widget.showCrown && _crownBob != null)
          AnimatedBuilder(
            animation: _crownBob!,
            builder: (_, _) {
              final bob = -2 * _crownBob!.value;
              return Transform.translate(
                offset: Offset(0, bob),
                child: const _Crown(),
              );
            },
          )
        else
          const SizedBox(height: 24),
        const SizedBox(height: 4),
        // Avatar circle with halo.
        SizedBox(
          width: avatarSize + 16,
          height: avatarSize + 16,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Halo blur.
              Container(
                width: avatarSize + 16,
                height: avatarSize + 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      accent.withValues(alpha: 0.4),
                      Colors.transparent,
                    ],
                    stops: const [0, 0.7],
                  ),
                ),
              ),
              Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent.withValues(alpha: 0.25),
                      accent.withValues(alpha: 0.06),
                    ],
                  ),
                  border: Border.all(color: accent, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.55),
                      blurRadius: 16,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  _initial(),
                  style: AppType.displayMD(color: AppPalette.textPrimary)
                      .copyWith(
                    fontSize: isFirst ? 26 : 22,
                    letterSpacing: 1,
                    height: 1,
                    shadows: [
                      Shadow(
                        color: accent.withValues(alpha: 0.6),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.entry.displayName.isEmpty
              ? '@${widget.entry.username}'
              : widget.entry.displayName.toUpperCase(),
          style: AppType.displaySM(color: AppPalette.textPrimary).copyWith(
            fontSize: isFirst ? 14 : 12,
            letterSpacing: 1,
            height: 1.1,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          'LV ${widget.entry.level}',
          style: TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 8,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w700,
            color: accent,
          ),
        ),
        const SizedBox(height: 6),
        // Pedestal.
        SizedBox(
          height: widget.height,
          width: double.infinity,
          child: ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(8)),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    accent.withValues(alpha: 0.20),
                    accent.withValues(alpha: 0.07),
                  ],
                ),
                border: Border(
                  top: BorderSide(color: accent.withValues(alpha: 0.4)),
                  left: BorderSide(color: accent.withValues(alpha: 0.4)),
                  right: BorderSide(color: accent.withValues(alpha: 0.4)),
                ),
              ),
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  // Big watermark place number behind.
                  Positioned(
                    bottom: -16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        '${widget.place}',
                        style: AppType.displayLG(color: accent).copyWith(
                          fontSize: 100,
                          height: 1,
                          shadows: [
                            Shadow(
                              color: accent.withValues(alpha: 0.08),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                    child: Column(
                      children: [
                        // Place number pill.
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accent.withValues(alpha: 0.15),
                            border: Border.all(
                              color: accent.withValues(alpha: 0.6),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${widget.place}',
                            style:
                                AppType.displayMD(color: accent).copyWith(
                              fontSize: 14,
                              height: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _xpLabel(),
                          style: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          _xpSuffix(),
                          style: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 7,
                            letterSpacing: 1,
                            color: AppPalette.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Crown extends StatelessWidget {
  const _Crown();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 20,
      child: CustomPaint(painter: const _CrownPainter()),
    );
  }
}

class _CrownPainter extends CustomPainter {
  const _CrownPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final body = Path()
      ..moveTo(2, 16)
      ..lineTo(4, 4)
      ..lineTo(11, 12)
      ..lineTo(17, 2)
      ..lineTo(23, 12)
      ..lineTo(30, 4)
      ..lineTo(32, 16)
      ..close();
    final fill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFCD34D), AppPalette.amber],
      ).createShader(Rect.fromLTWH(0, 0, 34, 20));
    canvas.drawPath(body, fill);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFFFCD34D)
      ..strokeWidth = 0.5;
    canvas.drawPath(body, stroke);
    final dot = Paint()..color = const Color(0xFFFCD34D);
    canvas.drawCircle(const Offset(4, 4), 1.6, dot);
    canvas.drawCircle(const Offset(17, 2), 1.8, dot);
    canvas.drawCircle(const Offset(30, 4), 1.6, dot);
    canvas.drawRect(
      const Rect.fromLTWH(2, 15, 30, 2),
      Paint()..color = const Color(0xFFB8741A),
    );
  }

  @override
  bool shouldRepaint(covariant _CrownPainter old) => false;
}

// ─── Rank list (rank 4+) ─────────────────────────────────────────

class _RankSection extends StatelessWidget {
  const _RankSection({
    required this.entries,
    required this.metric,
    required this.startsFromRank,
  });
  final List<LeaderboardEntry> entries;
  final LeaderboardMetric metric;
  final int startsFromRank;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    final lastRank = entries.last.rank;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (startsFromRank > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
              child: Text(
                'RANK $startsFromRank — $lastRank',
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 9,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.textMuted,
                ),
              ),
            ),
          for (final e in entries) ...[
            _RankRow(entry: e, metric: metric),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.entry, required this.metric});
  final LeaderboardEntry entry;
  final LeaderboardMetric metric;

  String _initial() {
    final n =
        entry.displayName.isEmpty ? entry.username : entry.displayName;
    return n.isEmpty ? '?' : n.substring(0, 1).toUpperCase();
  }

  String _value() {
    final v = entry.valueFor(metric);
    if (metric == LeaderboardMetric.currentStreak) return '$v';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return '$v';
  }

  @override
  Widget build(BuildContext context) {
    final isYou = entry.isMe;
    final accent = isYou ? AppPalette.amber : AppPalette.purpleSoft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: isYou
            ? LinearGradient(
                colors: [
                  AppPalette.amber.withValues(alpha: 0.18),
                  AppPalette.amber.withValues(alpha: 0.06),
                ],
              )
            : null,
        color: isYou ? null : AppPalette.bgCard.withValues(alpha: 0.7),
        border: Border.all(
          color: isYou
              ? AppPalette.amber.withValues(alpha: 0.6)
              : AppPalette.purpleSoft.withValues(alpha: 0.2),
        ),
        boxShadow: isYou
            ? [
                BoxShadow(
                  color: AppPalette.amber.withValues(alpha: 0.22),
                  blurRadius: 14,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Rank badge.
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: isYou
                  ? AppPalette.amber.withValues(alpha: 0.20)
                  : AppPalette.purple.withValues(alpha: 0.12),
              border: Border.all(
                color: isYou
                    ? AppPalette.amber.withValues(alpha: 0.5)
                    : AppPalette.purpleSoft.withValues(alpha: 0.3),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '${entry.rank}',
              style: AppType.displayMD(color: accent).copyWith(
                fontSize: 14,
                height: 1,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Avatar circle.
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: 0.20),
                  accent.withValues(alpha: 0.06),
                ],
              ),
              border: Border.all(
                color: accent.withValues(alpha: 0.55),
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              _initial(),
              style: AppType.displayMD(color: AppPalette.textPrimary)
                  .copyWith(
                fontSize: 14,
                height: 1,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name + class.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.displayName.isEmpty
                            ? '@${entry.username}'
                            : entry.displayName.toUpperCase(),
                        style: AppType.displaySM(
                          color: AppPalette.textPrimary,
                        ).copyWith(
                          fontSize: 14,
                          letterSpacing: 0.5,
                          height: 1.1,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isYou) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: AppPalette.amber,
                        ),
                        child: Text(
                          'YOU',
                          style: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 7,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w800,
                            color: AppPalette.voidBg,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'LV ${entry.level} · @${entry.username}',
                  style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 9,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700,
                    color: AppPalette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          // Streak chip.
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.local_fire_department,
                size: 12,
                color: Color(0xFFFF6B35),
              ),
              const SizedBox(width: 3),
              Text(
                '${entry.currentStreak}',
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFFF6B35),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          // Active-metric value.
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _value(),
                style: AppType.displayMD(color: AppPalette.textPrimary)
                    .copyWith(fontSize: 15, height: 1),
              ),
              const SizedBox(height: 1),
              Text(
                metric == LeaderboardMetric.currentStreak ? 'DAYS' : 'XP',
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 8,
                  letterSpacing: 1,
                  color: AppPalette.textMuted,
                ),
              ),
            ],
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
    return Padding(
      padding: const EdgeInsets.all(AppSpace.s8),
      child: Column(
        children: [
          const SizedBox(height: 40),
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
            "Add a few friends — your row appears here as soon as someone's in the list.",
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
      ),
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
