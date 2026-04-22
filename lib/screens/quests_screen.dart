import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/tokens.dart';
import '../widgets/in_app_shell.dart';
import '../widgets/neon_card.dart';
import '../widgets/placeholder_block.dart';
import '../widgets/progress_bar.dart';
import '../widgets/quest_row.dart';
import '../widgets/segmented_toggle.dart';
import '../widgets/tab_bar.dart';

class QuestsScreen extends StatefulWidget {
  const QuestsScreen({super.key});

  @override
  State<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends State<QuestsScreen> {
  String _tab = 'daily';

  @override
  Widget build(BuildContext context) {
    return InAppShell(
      active: AppTab.quests,
      title: 'QUESTS',
      child: ListView(
        padding: const EdgeInsets.all(AppSpace.s5),
        children: [
          SegmentedToggle<String>(
            options: const [
              SegmentOption(value: 'daily', label: 'DAILY'),
              SegmentOption(value: 'weekly', label: 'WEEKLY'),
              SegmentOption(value: 'boss', label: 'BOSS'),
            ],
            value: _tab,
            onChanged: (v) => setState(() => _tab = v),
            color: AppPalette.purple,
          ),
          const SizedBox(height: AppSpace.s4),
          ..._tabContent(context),
        ],
      ),
    );
  }

  List<Widget> _tabContent(BuildContext context) {
    switch (_tab) {
      case 'daily':
        return const [
          QuestRow(title: 'HIT 10,000 STEPS', type: QuestType.daily, progress: 0.72, xp: 25),
          SizedBox(height: AppSpace.s3),
          QuestRow(title: 'COMPLETE PUSH DAY', type: QuestType.daily, progress: 0, xp: 40),
          SizedBox(height: AppSpace.s3),
          QuestRow(title: 'LOG PROTEIN INTAKE', type: QuestType.daily, progress: 0.4, xp: 15),
          SizedBox(height: AppSpace.s3),
          QuestRow(title: 'SLEEP BEFORE 23:00', type: QuestType.daily, progress: 1, xp: 20),
        ];
      case 'weekly':
        return const [
          QuestRow(title: 'TRAIN 4 DAYS', type: QuestType.weekly, progress: 0.5, xp: 150),
          SizedBox(height: AppSpace.s3),
          QuestRow(title: 'ADD 5KG ON ANY LIFT', type: QuestType.weekly, progress: 0.6, xp: 200),
          SizedBox(height: AppSpace.s3),
          QuestRow(title: '30MIN CARDIO × 3', type: QuestType.weekly, progress: 0.33, xp: 120),
        ];
      case 'boss':
      default:
        return [
          _BossQuestCard(onTap: () => context.go('/boss-detail')),
          const SizedBox(height: AppSpace.s4),
          const QuestRow(
            title: 'SPRING CHALLENGE',
            type: QuestType.boss,
            progress: 0.25,
            xp: 500,
            locked: true,
          ),
        ];
    }
  }
}

class _BossQuestCard extends StatelessWidget {
  const _BossQuestCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      glow: GlowColor.flame,
      padding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              const PlaceholderBlock(
                label: 'BOSS KEY ART',
                height: 150,
                color: AppPalette.flame,
                border: false,
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppPalette.flame.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppPalette.flame),
                  ),
                  child: Text(
                    'BOSS · 3 DAYS LEFT',
                    style: AppType.label(color: AppPalette.flame).copyWith(
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpace.s5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'THE IRON GAUNTLET',
                  style: AppType.displayMD(color: AppPalette.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Complete 5 push workouts and a 10km run this week. Break the system — earn legendary buffs.',
                  style: AppType.bodySM(color: AppPalette.textSecondary),
                ),
                const SizedBox(height: AppSpace.s4),
                const Bar(percent: 60, color: AppPalette.flame),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '3 / 5 WORKOUTS',
                      style: AppType.monoMD(color: AppPalette.textSecondary)
                          .copyWith(fontSize: 12),
                    ),
                    Text(
                      '+500 XP',
                      style: AppType.monoMD(color: AppPalette.xpGold).copyWith(
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

