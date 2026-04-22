import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/tokens.dart';
import 'screen_base.dart';
import 'tab_bar.dart';

/// Shared in-app shell: top header + body + bottom tab bar.
class InAppShell extends StatelessWidget {
  const InAppShell({
    super.key,
    required this.active,
    required this.title,
    required this.child,
  });

  final AppTab active;
  final String title;
  final Widget child;

  void _onTab(BuildContext context, AppTab tab) {
    switch (tab) {
      case AppTab.home:
        context.go('/home');
      case AppTab.quests:
        context.go('/quests');
      case AppTab.streak:
        context.go('/streak');
      case AppTab.profile:
        context.go('/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenBase(
      child: Column(
        children: [
          Container(
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
          ),
          Expanded(child: child),
          AppTabBar(active: active, onChange: (t) => _onTab(context, t)),
        ],
      ),
    );
  }
}
