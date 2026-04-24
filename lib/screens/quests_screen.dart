import 'package:flutter/material.dart';

import '../data/models/quest.dart' as model;
import '../data/services/quest_service.dart';
import '../game/quest_engine.dart';
import '../theme/tokens.dart';
import '../widgets/in_app_shell.dart';
import '../widgets/neon_card.dart';
import '../widgets/quest_row.dart';
import '../widgets/segmented_toggle.dart';
import '../widgets/tab_bar.dart';

/// Quests hub — PRD §9.4. Daily tab is wired to the real engine. Weekly
/// and Boss tabs are locked placeholders pending §3.1 / §3.2.
class QuestsScreen extends StatefulWidget {
  const QuestsScreen({super.key});

  @override
  State<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends State<QuestsScreen> {
  String _tab = 'daily';
  late Future<List<model.Quest>> _dailyFuture;

  @override
  void initState() {
    super.initState();
    _dailyFuture = _loadDaily();
  }

  Future<List<model.Quest>> _loadDaily() async {
    // Fire-and-forget rotation on mount — same pattern Home uses. If the
    // user navigates to Quests before Home today (rare), the batch is
    // still ready.
    await QuestEngine.rotateDailyIfNeeded();
    // Read today's FULL batch including completed quests so the DONE
    // state sticks until tomorrow's rotation. `active()` alone would hide
    // completions, which felt like a reset to users.
    return QuestService.issuedSince('daily', QuestEngine.todayEpoch());
  }

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
        return [_DailyTab(future: _dailyFuture)];
      case 'weekly':
        return const [
          _ComingSoonCard(
            glow: GlowColor.purple,
            kicker: 'WEEKLY QUESTS',
            title: 'BUILDING THE WEEK BOARD',
            body:
                'Weekly challenges ship with v1.0 — 4-day training streaks, volume milestones, PR chases. Pro-gated per PRD §13.',
          ),
        ];
      case 'boss':
      default:
        return const [
          _ComingSoonCard(
            glow: GlowColor.flame,
            kicker: 'BOSS QUESTS',
            title: 'BOSSES ARRIVE AT v1.0',
            body:
                'Multi-week boss objectives with legendary buffs (e.g. "Deadlift 2×BW", "+10% e1RM in 6 weeks"). Tap at launch.',
          ),
        ];
    }
  }
}

class _DailyTab extends StatelessWidget {
  const _DailyTab({required this.future});
  final Future<List<model.Quest>> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<model.Quest>>(
      future: future,
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpace.s6),
            child: Center(
              child: CircularProgressIndicator(color: AppPalette.purple),
            ),
          );
        }
        final quests = snap.data ?? const <model.Quest>[];
        if (quests.isEmpty) {
          return NeonCard(
            glow: GlowColor.none,
            padding: const EdgeInsets.all(AppSpace.s5),
            pulse: false,
            child: Text(
              'No daily quests yet — pull to refresh, or start a workout to trigger the first batch.',
              style: AppType.bodySM(color: AppPalette.textMuted),
            ),
          );
        }
        final completed = quests.where((q) => q.isCompleted).length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DailyHeader(completed: completed, total: quests.length),
            const SizedBox(height: AppSpace.s3),
            for (final q in quests) ...[
              QuestRow(
                title: q.title,
                type: QuestType.daily,
                progress:
                    q.isCompleted ? 1.0 : q.progressRatio,
                xp: q.xpReward,
                completed: q.isCompleted,
              ),
              const SizedBox(height: AppSpace.s3),
            ],
          ],
        );
      },
    );
  }
}

class _DailyHeader extends StatelessWidget {
  const _DailyHeader({required this.completed, required this.total});
  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final allDone = completed == total && total > 0;
    final color = allDone ? AppPalette.green : AppPalette.purple;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.s4,
        vertical: AppSpace.s3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(
            allDone ? Icons.check_circle : Icons.local_fire_department,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              allDone
                  ? 'ALL $total DAILIES COMPLETE — BANK THE XP'
                  : 'DAILY PROGRESS · $completed / $total',
              style: AppType.label(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComingSoonCard extends StatelessWidget {
  const _ComingSoonCard({
    required this.glow,
    required this.kicker,
    required this.title,
    required this.body,
  });

  final GlowColor glow;
  final String kicker;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final accent = glow == GlowColor.flame
        ? AppPalette.flame
        : AppPalette.purple;
    return NeonCard(
      glow: glow,
      padding: const EdgeInsets.all(AppSpace.s5),
      pulse: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline, color: accent, size: 16),
              const SizedBox(width: 8),
              Text(kicker, style: AppType.label(color: accent)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: AppType.displayMD(color: AppPalette.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: AppType.bodySM(color: AppPalette.textSecondary),
          ),
        ],
      ),
    );
  }
}
