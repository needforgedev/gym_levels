import 'dart:ui';

import 'package:flutter/material.dart';
import '../theme/tokens.dart';

enum AppTab { home, quests, leaderboard, streak, profile }

/// Floating glass pill tab bar — translucent backdrop-blurred surface with
/// a violet border, layered shadows (outer drop, violet ambient, inset
/// highlights), and an amber-glowing active pill. Matches the design v2
/// `TabBar` (`design/v2/shared.jsx`).
///
/// Size: 66px tall, fully rounded (radius 33). Sits 24px from the bottom
/// safe area with 16px horizontal margin. Callers should layer this over
/// the screen body using a Stack and reserve ~110px of bottom padding on
/// scrollable content so it doesn't end up flush behind the bar.
class AppTabBar extends StatelessWidget {
  const AppTabBar({
    super.key,
    required this.active,
    required this.onChange,
  });

  final AppTab active;
  final ValueChanged<AppTab> onChange;

  static const _items = [
    (AppTab.home, Icons.home_outlined, 'Home'),
    (AppTab.quests, Icons.menu_book_outlined, 'Quests'),
    (AppTab.leaderboard, Icons.leaderboard_outlined, 'Ranks'),
    (AppTab.streak, Icons.local_fire_department_outlined, 'Streak'),
    (AppTab.profile, Icons.emoji_events_outlined, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(33),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: 66,
          decoration: BoxDecoration(
            // Two-stop gradient on translucent dark — the design's
            // `linear-gradient(180deg, rgba(26,15,43,0.72) 0%, rgba(10,6,18,0.78) 100%)`.
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xB81A0F2B),
                Color(0xC70A0612),
              ],
            ),
            borderRadius: BorderRadius.circular(33),
            border: Border.all(
              color: AppPalette.purple.withValues(alpha: 0.30),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 40,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: AppPalette.purple.withValues(alpha: 0.4),
                blurRadius: 30,
                spreadRadius: -8,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Inner violet ambient gradient — radial wash from below.
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(33),
                      gradient: RadialGradient(
                        center: const Alignment(0, 1.5),
                        radius: 1.0,
                        colors: [
                          AppPalette.purple.withValues(alpha: 0.20),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Top shine highlight.
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    height: 1,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.transparent,
                          Color(0x40FFFFFF),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: _items.map((i) {
                    final tab = i.$1;
                    final icon = i.$2;
                    final label = i.$3;
                    final isActive = tab == active;
                    return _TabPill(
                      icon: icon,
                      label: label,
                      active: isActive,
                      onTap: () => onChange(tab),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppPalette.amber : AppPalette.textMuted;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(27),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          // Trimmed from 66 → 58 so 5 pills fit on a 375pt-wide screen
          // (iPhone SE 3rd gen) without overflow. 5 × 58 + 20 inner +
          // 32 outer margin = 342 ≤ 375.
          width: 58,
          height: 54,
          decoration: BoxDecoration(
            gradient: active
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppPalette.amber.withValues(alpha: 0.22),
                      AppPalette.amber.withValues(alpha: 0.08),
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(27),
            border: Border.all(
              color: active
                  ? AppPalette.amber.withValues(alpha: 0.45)
                  : Colors.transparent,
              width: 1,
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppPalette.amber.withValues(alpha: 0.55),
                      blurRadius: 18,
                      spreadRadius: -2,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                transform: Matrix4.translationValues(0, active ? -1 : 0, 0),
                child: Icon(
                  icon,
                  size: 21,
                  color: color,
                  shadows: active
                      ? [
                          Shadow(
                            color: AppPalette.amber.withValues(alpha: 0.8),
                            blurRadius: 6,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.9,
                  color: color,
                  shadows: active
                      ? [
                          Shadow(
                            color: AppPalette.amber.withValues(alpha: 0.4),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
