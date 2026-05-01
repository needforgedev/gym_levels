import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/tokens.dart';
import 'screen_base.dart';
import 'tab_bar.dart';

/// Shared in-app shell — top header + body + **floating** tab bar.
///
/// The tab bar is layered absolutely over the body via Stack so it floats
/// (per design v2 — `design/v2/shared.jsx` `TabBar`). Body widgets that
/// scroll should reserve `tabBarSafeBottom` worth of bottom padding so
/// content doesn't sit under the bar.
class InAppShell extends StatelessWidget {
  const InAppShell({
    super.key,
    required this.active,
    required this.title,
    required this.child,
    this.showHeader = true,
  });

  final AppTab active;
  final String title;
  final Widget child;

  /// When `false`, the `LEVEL UP IRL · <TITLE>` header strip is omitted —
  /// content starts directly under the iOS status bar. Used by Home, which
  /// has its own greeting block at the top per design v2.
  final bool showHeader;

  /// Vertical clearance the floating tab bar needs at the bottom of any
  /// scrollable content. = bar surface height (66) + bottom inset (24) +
  /// floating gold leaderboard button rise (~28) + breathing (~20).
  /// Bumped from 110 → 138 for the v1-improvements design.
  static const double tabBarSafeBottom = 138;

  void _onTab(BuildContext context, AppTab tab) {
    switch (tab) {
      case AppTab.home:
        context.go('/home');
      case AppTab.quests:
        context.go('/quests');
      case AppTab.leaderboard:
        context.go('/leaderboard');
      case AppTab.streak:
        context.go('/streak');
      case AppTab.profile:
        context.go('/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenBase(
      child: Stack(
        children: [
          // Ambient radial-gradient wash — design v2 `body::before`. Sits
          // under everything so each screen picks up the same backdrop.
          const Positioned.fill(child: _AmbientBackground()),
          Column(
            children: [
              if (showHeader) _Header(title: title),
              Expanded(child: child),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24 + MediaQuery.of(context).padding.bottom,
            child: AppTabBar(
              active: active,
              onChange: (t) => _onTab(context, t),
            ),
          ),
        ],
      ),
    );
  }
}

/// Subtle violet (top) + amber (bottom-right) radial washes layered over
/// the page bg. Mirrors the `body::before` rule in design v2's index.html.
class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-0.6, -0.95),
            radius: 1.1,
            colors: [
              AppPalette.purple.withValues(alpha: 0.18),
              Colors.transparent,
            ],
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.95, 0.95),
              radius: 0.9,
              colors: [
                AppPalette.amber.withValues(alpha: 0.06),
                Colors.transparent,
              ],
            ),
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title});
  final String title;

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
        border: Border(
          bottom: BorderSide(color: AppPalette.strokeHairline),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'LEVEL UP IRL',
            style: AppType.displaySM(color: AppPalette.textMuted)
                .copyWith(letterSpacing: 2),
          ),
          Text(
            title.toUpperCase(),
            style: AppType.label(color: AppPalette.textMuted)
                .copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}
