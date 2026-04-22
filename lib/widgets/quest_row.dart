import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import 'neon_card.dart';
import 'progress_bar.dart';

enum QuestType { daily, weekly, boss }

Color _questColor(QuestType t) {
  switch (t) {
    case QuestType.daily:
      return AppPalette.green;
    case QuestType.weekly:
      return AppPalette.purple;
    case QuestType.boss:
      return AppPalette.flame;
  }
}

GlowColor _questGlow(QuestType t) {
  switch (t) {
    case QuestType.daily:
      return GlowColor.green;
    case QuestType.weekly:
      return GlowColor.purple;
    case QuestType.boss:
      return GlowColor.flame;
  }
}

class QuestRow extends StatelessWidget {
  const QuestRow({
    super.key,
    required this.title,
    required this.type,
    required this.progress,
    required this.xp,
    this.locked = false,
    this.onTap,
  });

  final String title;
  final QuestType type;
  final double progress; // 0..1
  final int xp;
  final bool locked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = _questColor(type);
    return NeonCard(
      glow: _questGlow(type),
      padding: const EdgeInsets.all(14),
      pulse: false,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.name.toUpperCase(),
                      style: AppType.label(color: color).copyWith(fontSize: 10),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: AppType.bodyLG(color: AppPalette.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppPalette.xpGold.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppPalette.xpGold),
                ),
                child: Text(
                  '+$xp',
                  style: AppType.monoMD(color: AppPalette.xpGold).copyWith(
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Bar(percent: progress * 100, color: color, glowOn: progress > 0),
        ],
      ),
    );
  }
}
