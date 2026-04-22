import 'package:flutter/material.dart';
import '../theme/tokens.dart';

enum AppTab { home, quests, streak, profile }

class AppTabBar extends StatelessWidget {
  const AppTabBar({super.key, required this.active, required this.onChange});

  final AppTab active;
  final ValueChanged<AppTab> onChange;

  static const _items = [
    (AppTab.home, Icons.home_outlined, 'HOME'),
    (AppTab.quests, Icons.menu_book_outlined, 'QUESTS'),
    (AppTab.streak, Icons.local_fire_department_outlined, 'STREAK'),
    (AppTab.profile, Icons.emoji_events_outlined, 'PROFILE'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72 + MediaQuery.of(context).padding.bottom,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: AppPalette.carbon,
        border: Border(
          top: BorderSide(color: AppPalette.strokeHairline),
        ),
      ),
      child: Row(
        children: _items.map((i) {
          final tab = i.$1;
          final icon = i.$2;
          final label = i.$3;
          final on = tab == active;
          return Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onChange(tab),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: on
                            ? AppPalette.xpGold.withValues(alpha: 0.20)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: on
                            ? [
                                BoxShadow(
                                  color: AppPalette.xpGold.withValues(
                                    alpha: 0.66,
                                  ),
                                  blurRadius: 12,
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        icon,
                        size: 20,
                        color:
                            on ? AppPalette.xpGold : AppPalette.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: AppType.label(
                        color: on ? AppPalette.xpGold : AppPalette.textMuted,
                      ).copyWith(fontSize: 10, letterSpacing: 0.6),
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
