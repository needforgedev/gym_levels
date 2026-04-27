import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/models/quest.dart';
import '../data/services/quest_service.dart';
import '../game/quest_engine.dart';
import '../theme/tokens.dart';
import '../widgets/screen_base.dart';

/// Boss-quest drill-down. Reads a real `quests` row (passed via go_router
/// `extra` from the Quests screen, or pulled lazily as the first active
/// boss row when deep-linked). The progress bar + week phase + objective
/// breakdown all derive from the row's `progress` / `target` /
/// `issuedAt` fields — no static placeholders.
class BossDetailScreen extends StatefulWidget {
  const BossDetailScreen({super.key, this.quest});

  final Quest? quest;

  @override
  State<BossDetailScreen> createState() => _BossDetailScreenState();
}

class _BossDetailScreenState extends State<BossDetailScreen> {
  late Future<Quest?> _future;

  @override
  void initState() {
    super.initState();
    _future = _resolve();
  }

  Future<Quest?> _resolve() async {
    if (widget.quest != null) return widget.quest;
    await QuestEngine.seedBossesIfNeeded();
    final all = await QuestService.all();
    final bosses = all.where((q) => q.type == 'boss').toList();
    if (bosses.isEmpty) return null;
    final active = bosses.where((q) => !q.isCompleted).toList();
    return active.isNotEmpty ? active.first : bosses.first;
  }

  @override
  Widget build(BuildContext context) {
    return ScreenBase(
      background: AppPalette.voidBg,
      child: SafeArea(
        bottom: false,
        child: FutureBuilder<Quest?>(
          future: _future,
          builder: (ctx, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(color: AppPalette.flame),
              );
            }
            final q = snap.data;
            if (q == null) return const _EmptyState();
            return _BossDetailBody(quest: q);
          },
        ),
      ),
    );
  }
}

class _BossDetailBody extends StatelessWidget {
  const _BossDetailBody({required this.quest});
  final Quest quest;

  String _formatNum(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final fromEnd = s.length - i;
      buf.write(s[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final meta = QuestEngine.metaFor(quest.description);
    final phase = QuestEngine.bossPhase(quest);
    final pct = quest.progressRatio;
    final pctRounded = (pct * 100).round();
    final unit = meta.unit;
    final unitSuffix = unit == null ? '' : ' $unit';
    final daysLeft = quest.expiresAt == null
        ? null
        : ((quest.expiresAt! -
                    DateTime.now().millisecondsSinceEpoch ~/ 1000) /
                86400)
            .ceil()
            .clamp(0, 999);

    return Column(
      children: [
        _Header(
          phase: phase,
          daysLeft: daysLeft,
          onBack: () => context.go('/quests'),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              const SizedBox(height: 4),
              Text(
                quest.title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 36,
                  fontFamily: 'BebasNeue',
                  letterSpacing: 1,
                  height: 1.05,
                  color: AppPalette.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              if ((quest.description ?? '').isNotEmpty)
                Text(
                  _descCopy(quest),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppPalette.textMuted,
                    height: 1.5,
                  ),
                ),
              const SizedBox(height: 18),
              _ProgressBlock(
                pct: pct,
                pctLabel: '$pctRounded% COMPLETE',
                xpReward: quest.xpReward,
                done: quest.isCompleted,
              ),
              const SizedBox(height: 18),
              const _SectionLabel(text: 'OBJECTIVE'),
              const SizedBox(height: 8),
              _ObjectiveRow(
                label: quest.title,
                progressText:
                    '${_formatNum(quest.progress)}$unitSuffix / ${_formatNum(quest.target)}$unitSuffix',
                done: quest.isCompleted,
              ),
              const SizedBox(height: 22),
              const _SectionLabel(text: 'REWARD ON COMPLETION'),
              const SizedBox(height: 8),
              _RewardCard(xp: quest.xpReward),
              const SizedBox(height: 24),
              _StartCta(
                onTap: () => context.go('/exercise-picker'),
                done: quest.isCompleted,
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _descCopy(Quest q) {
    final tpl = QuestEngine.bossPool.firstWhere(
      (t) => t.kindKey == q.description,
      orElse: () => const BossQuestTemplate(
        kindKey: '',
        title: '',
        desc: '',
        target: 0,
        xp: 0,
        totalWeeks: 6,
      ),
    );
    return tpl.desc.isEmpty
        ? 'Multi-week objective. Complete the prescribed work to break the gauntlet and earn a permanent buff.'
        : tpl.desc;
  }
}

// ─── Header ────────────────────────────────────────────────
class _Header extends StatelessWidget {
  const _Header({
    required this.onBack,
    this.phase,
    this.daysLeft,
  });

  final VoidCallback onBack;
  final String? phase;
  final int? daysLeft;

  @override
  Widget build(BuildContext context) {
    final kicker = StringBuffer('BOSS ENGAGEMENT');
    if (phase != null) kicker.write(' · $phase');
    if (daysLeft != null) kicker.write(' · ${daysLeft}D LEFT');
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 16, 16),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 18,
              color: AppPalette.textPrimary,
            ),
          ),
          Expanded(
            child: Text(
              kicker.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                color: AppPalette.flame,
              ),
            ),
          ),
          const SizedBox(width: 40), // balances the back-button width
        ],
      ),
    );
  }
}

class _ProgressBlock extends StatelessWidget {
  const _ProgressBlock({
    required this.pct,
    required this.pctLabel,
    required this.xpReward,
    required this.done,
  });

  final double pct;
  final String pctLabel;
  final int xpReward;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final accent = done ? AppPalette.success : AppPalette.flame;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Container(
            height: 8,
            color: AppPalette.purple.withValues(alpha: 0.12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: pct,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accent, AppPalette.amberSoft],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.55),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              pctLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                fontFamily: 'JetBrainsMono',
                color: AppPalette.textMuted,
              ),
            ),
            Text(
              '+$xpReward XP',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                fontFamily: 'JetBrainsMono',
                color: AppPalette.amber,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
        color: AppPalette.textMuted,
      ),
    );
  }
}

class _ObjectiveRow extends StatelessWidget {
  const _ObjectiveRow({
    required this.label,
    required this.progressText,
    required this.done,
  });
  final String label;
  final String progressText;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: done
            ? AppPalette.success.withValues(alpha: 0.10)
            : AppPalette.bgCard.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: done
              ? AppPalette.success.withValues(alpha: 0.45)
              : AppPalette.flame.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: done ? AppPalette.success : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color:
                    done ? AppPalette.success : AppPalette.flame,
                width: 1.5,
              ),
            ),
            child: done
                ? const Icon(Icons.check, color: AppPalette.voidBg, size: 12)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: done
                    ? AppPalette.textPrimary.withValues(alpha: 0.65)
                    : AppPalette.textPrimary,
                decoration: done ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          Text(
            progressText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              fontFamily: 'JetBrainsMono',
              color: done ? AppPalette.success : AppPalette.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({required this.xp});
  final int xp;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPalette.amber.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppPalette.amber.withValues(alpha: 0.45),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppPalette.amber.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppPalette.amber.withValues(alpha: 0.50),
                width: 1,
              ),
            ),
            child: const Icon(Icons.star, color: AppPalette.amber, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '+$xp XP',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'BebasNeue',
                    color: AppPalette.amber,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Plus a permanent class buff on completion.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppPalette.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StartCta extends StatelessWidget {
  const _StartCta({required this.onTap, required this.done});
  final VoidCallback onTap;
  final bool done;
  @override
  Widget build(BuildContext context) {
    if (done) {
      return Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppPalette.success.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppPalette.success.withValues(alpha: 0.45),
            width: 1,
          ),
        ),
        child: const Text(
          'BOSS DEFEATED',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: AppPalette.success,
          ),
        ),
      );
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppPalette.flame, AppPalette.amberSoft],
            ),
            boxShadow: [
              BoxShadow(
                color: AppPalette.flame.withValues(alpha: 0.50),
                blurRadius: 16,
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'START WORKOUT',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                color: AppPalette.voidBg,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'No active boss quests.',
            style: TextStyle(color: AppPalette.textMuted),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.go('/quests'),
            child: const Text('BACK TO QUESTS'),
          ),
        ],
      ),
    );
  }
}
