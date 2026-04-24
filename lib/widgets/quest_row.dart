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
    this.completed = false,
    this.onTap,
  });

  final String title;
  final QuestType type;
  final double progress; // 0..1
  final int xp;
  final bool locked;

  /// True once the quest's `completed_at` is stamped. The row stays in the
  /// list for the remainder of the local day but renders with a DONE chip
  /// (replacing the XP chip) and a full bar so users see the payout they
  /// already banked.
  final bool completed;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = _questColor(type);
    final titleColor = completed
        ? AppPalette.textSecondary
        : AppPalette.textPrimary;
    return NeonCard(
      glow: completed ? GlowColor.none : _questGlow(type),
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
                      style: AppType.bodyLG(color: titleColor).copyWith(
                        decoration: completed ? TextDecoration.lineThrough : null,
                        decorationColor: AppPalette.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (completed)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppPalette.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppPalette.green),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check,
                          color: AppPalette.green, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'DONE +$xp',
                        style: AppType.label(color: AppPalette.green)
                            .copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppPalette.xpGold.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppPalette.xpGold),
                  ),
                  child: Text(
                    '+$xp',
                    style: AppType.monoMD(color: AppPalette.xpGold)
                        .copyWith(fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Bar(
            percent: progress * 100,
            color: completed ? AppPalette.green : color,
            glowOn: progress > 0 && !completed,
          ),
        ],
      ),
    );
  }
}
