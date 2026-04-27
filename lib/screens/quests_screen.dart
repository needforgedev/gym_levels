import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/models/quest.dart' as model;
import '../data/services/quest_service.dart';
import '../game/quest_engine.dart';
import '../theme/tokens.dart';
import '../widgets/in_app_shell.dart';
import '../widgets/tab_bar.dart';

/// Quests hub — matches design v2 (`design/v2/screens-quests.jsx`).
///
/// Layout:
///   • Centered "QUESTS" big title + "LEVEL UP THROUGH CHALLENGES" mono
///     kicker.
///   • 3-segment tab pill: Daily (amber) / Weekly (violet) / Boss (flame).
///   • Reset cadence row + N ACTIVE counter.
///   • Quest cards: 42px icon block, title + +XP top-right, description,
///     "Progress" label + count, gradient progress bar.
///
/// Daily quests are wired to the real engine. Weekly + Boss tabs are
/// locked placeholders until §3.1 / §3.2.
class QuestsScreen extends StatefulWidget {
  const QuestsScreen({super.key});

  @override
  State<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends State<QuestsScreen> {
  String _tab = 'daily';
  late Future<List<model.Quest>> _dailyFuture;
  late Future<List<model.Quest>> _weeklyFuture;
  late Future<List<model.Quest>> _bossFuture;

  @override
  void initState() {
    super.initState();
    _dailyFuture = _loadDaily();
    _weeklyFuture = _loadWeekly();
    _bossFuture = _loadBoss();
  }

  Future<List<model.Quest>> _loadDaily() async {
    await QuestEngine.rotateDailyIfNeeded();
    return QuestService.issuedSince('daily', QuestEngine.todayEpoch());
  }

  Future<List<model.Quest>> _loadWeekly() async {
    await QuestEngine.rotateWeeklyIfNeeded();
    return QuestService.issuedSince('weekly', QuestEngine.weekStartEpoch());
  }

  Future<List<model.Quest>> _loadBoss() async {
    await QuestEngine.seedBossesIfNeeded();
    // Boss quests are long-running; show every non-expired one (active +
    // completed) so the user sees their full lineup.
    final all = await QuestService.all();
    return all.where((q) => q.type == 'boss').toList();
  }

  Color _tabColor(String tab) {
    switch (tab) {
      case 'daily':
        return AppPalette.amber;
      case 'weekly':
        return AppPalette.purpleSoft;
      case 'boss':
      default:
        return AppPalette.flame;
    }
  }

  String _resetText(String tab) {
    switch (tab) {
      case 'daily':
        return 'RESETS AT 04:00 LOCAL';
      case 'weekly':
        return 'RESETS MONDAY 00:00';
      case 'boss':
      default:
        return 'MULTI-WEEK OBJECTIVE';
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _tabColor(_tab);
    return InAppShell(
      active: AppTab.quests,
      title: 'QUESTS',
      showHeader: false,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          0,
          0,
          0,
          InAppShell.tabBarSafeBottom +
              MediaQuery.of(context).padding.bottom,
        ),
        children: [
          // Title block.
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Column(
              children: [
                Text(
                  'QUESTS',
                  style: TextStyle(
                    fontSize: 28,
                    fontFamily: 'BebasNeue',
                    letterSpacing: 2,
                    color: AppPalette.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'LEVEL UP THROUGH CHALLENGES',
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'JetBrainsMono',
                    letterSpacing: 2,
                    color: AppPalette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          // Tab pills.
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: _TabPills(active: _tab, onChange: (t) => setState(() => _tab = t)),
          ),
          // Reset / Active row.
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: _ResetRow(
              text: _resetText(_tab),
              accent: accent,
              future: switch (_tab) {
                'daily' => _dailyFuture,
                'weekly' => _weeklyFuture,
                'boss' => _bossFuture,
                _ => _dailyFuture,
              },
            ),
          ),
          // Body.
          if (_tab == 'daily')
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: _DailyTab(future: _dailyFuture),
            )
          else if (_tab == 'weekly')
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: _DbQuestList(
                future: _weeklyFuture,
                accent: AppPalette.purpleSoft,
                emptyText:
                    "This week's lineup is rotating in — pull to refresh in a sec.",
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                children: [
                  const _BossBanner(),
                  const SizedBox(height: 14),
                  _DbQuestList(
                    future: _bossFuture,
                    accent: AppPalette.flame,
                    emptyText: 'Bosses are spawning…',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── DB-backed quest list (Weekly + Boss) ─────────────────
//
// Reads real `Quest` rows from the engine. Each row's `description`
// holds the kindKey, which the QuestEngine.metaFor map turns into the
// icon + unit suffix. Boss rows additionally pull a phase label from
// `QuestEngine.bossPhase` (computed from `issuedAt` + template's
// `totalWeeks`).

class _DbQuestList extends StatelessWidget {
  const _DbQuestList({
    required this.future,
    required this.accent,
    required this.emptyText,
  });

  final Future<List<model.Quest>> future;
  final Color accent;
  final String emptyText;

  String _descFor(String? kindKey) {
    final weekly = QuestEngine.weeklyPool.firstWhere(
      (t) => t.kindKey == kindKey,
      orElse: () => const WeeklyQuestTemplate(
        kindKey: '',
        title: '',
        desc: '',
        target: 0,
        xp: 0,
      ),
    );
    if (weekly.kindKey.isNotEmpty) return weekly.desc;
    final boss = QuestEngine.bossPool.firstWhere(
      (t) => t.kindKey == kindKey,
      orElse: () => const BossQuestTemplate(
        kindKey: '',
        title: '',
        desc: '',
        target: 0,
        xp: 0,
        totalWeeks: 0,
      ),
    );
    return boss.desc;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<model.Quest>>(
      future: future,
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(color: accent),
            ),
          );
        }
        final quests = snap.data ?? const <model.Quest>[];
        if (quests.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: AppPalette.bgCard.withValues(alpha: 0.8),
              border: Border.all(
                color: accent.withValues(alpha: 0.20),
                width: 1,
              ),
            ),
            child: Text(
              emptyText,
              style: const TextStyle(
                fontSize: 12,
                color: AppPalette.textMuted,
              ),
            ),
          );
        }
        return Column(
          children: [
            for (final q in quests) ...[
              _QuestCard(
                quest: q,
                meta: QuestEngine.metaFor(q.description),
                desc: _descFor(q.description),
                phase: q.type == 'boss' ? QuestEngine.bossPhase(q) : null,
                accent: accent,
                onTap: q.type == 'boss'
                    ? () => GoRouter.of(context).go(
                          '/boss-detail',
                          extra: q,
                        )
                    : null,
              ),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }
}

// ─── Boss banner ───────────────────────────────────────────
class _BossBanner extends StatelessWidget {
  const _BossBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppPalette.flame.withValues(alpha: 0.18),
            AppPalette.purple.withValues(alpha: 0.15),
          ],
        ),
        border: Border.all(
          color: AppPalette.flame.withValues(alpha: 0.40),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppPalette.flame.withValues(alpha: 0.40),
            blurRadius: 24,
            spreadRadius: -6,
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Boss silhouette decoration on the right.
          Positioned(
            top: -10,
            right: -10,
            bottom: -10,
            width: 120,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.4,
                child: CustomPaint(painter: _BossSilhouettePainter()),
              ),
            ),
          ),
          // Foreground content.
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '[BOSS TIER ACTIVE]',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  fontFamily: 'JetBrainsMono',
                  color: AppPalette.flame,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'IRON COLOSSUS',
                style: TextStyle(
                  fontSize: 22,
                  fontFamily: 'BebasNeue',
                  letterSpacing: 1,
                  height: 1,
                  color: AppPalette.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const SizedBox(
                width: 220,
                child: Text(
                  'Defeat the Colossus to earn the Iron Ascendant title and 5000 bonus XP.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppPalette.textMuted,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Painter for the silhouette behind the boss banner — flame→violet
/// gradient figure with two small glowing eyes. Decorative only.
class _BossSilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [AppPalette.flame, AppPalette.purple],
    ).createShader(Rect.fromLTWH(0, 0, w, h));
    final body = Paint()..shader = shader;

    // Body silhouette (head + shoulders + waist tapering down).
    final path = Path()
      ..moveTo(w * 0.5, h * 0.10)
      ..lineTo(w * 0.62, h * 0.18)
      ..lineTo(w * 0.66, h * 0.30)
      ..lineTo(w * 0.62, h * 0.36)
      ..lineTo(w * 0.66, h * 0.44)
      ..lineTo(w * 0.78, h * 0.48)
      ..lineTo(w * 0.82, h * 0.62)
      ..lineTo(w * 0.76, h * 0.70)
      ..lineTo(w * 0.78, h * 0.86)
      ..lineTo(w * 0.70, h * 0.96)
      ..lineTo(w * 0.62, h * 0.99)
      ..lineTo(w * 0.54, h * 0.92)
      ..lineTo(w * 0.54, h * 0.78)
      ..lineTo(w * 0.46, h * 0.78)
      ..lineTo(w * 0.46, h * 0.92)
      ..lineTo(w * 0.38, h * 0.99)
      ..lineTo(w * 0.30, h * 0.96)
      ..lineTo(w * 0.22, h * 0.86)
      ..lineTo(w * 0.24, h * 0.70)
      ..lineTo(w * 0.18, h * 0.62)
      ..lineTo(w * 0.22, h * 0.48)
      ..lineTo(w * 0.34, h * 0.44)
      ..lineTo(w * 0.38, h * 0.36)
      ..lineTo(w * 0.34, h * 0.30)
      ..lineTo(w * 0.38, h * 0.18)
      ..close();
    canvas.drawPath(path, body);

    // Eyes — small flame-tinted dots.
    final eye = Paint()..color = AppPalette.flame;
    canvas.drawCircle(Offset(w * 0.43, h * 0.22), 2, eye);
    canvas.drawCircle(Offset(w * 0.57, h * 0.22), 2, eye);
  }

  @override
  bool shouldRepaint(covariant _BossSilhouettePainter old) => false;
}

// ─── Tab pill ──────────────────────────────────────────────
class _TabPills extends StatelessWidget {
  const _TabPills({required this.active, required this.onChange});
  final String active;
  final ValueChanged<String> onChange;

  static const _tabs = [
    ('daily', 'DAILY', AppPalette.amber),
    ('weekly', 'WEEKLY', AppPalette.purpleSoft),
    ('boss', 'BOSS', AppPalette.flame),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppPalette.bgCard.withValues(alpha: 0.8),
        border: Border.all(
          color: AppPalette.purple.withValues(alpha: 0.20),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          for (final (key, label, color) in _tabs)
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onChange(key),
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: active == key
                          ? LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                color.withValues(alpha: 0.20),
                                color.withValues(alpha: 0.06),
                              ],
                            )
                          : null,
                      border: Border.all(
                        color: active == key
                            ? color.withValues(alpha: 0.40)
                            : Colors.transparent,
                        width: 1,
                      ),
                      boxShadow: active == key
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.55),
                                blurRadius: 14,
                                spreadRadius: -4,
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: active == key ? color : AppPalette.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Reset / Active row ────────────────────────────────────
class _ResetRow extends StatelessWidget {
  const _ResetRow({
    required this.text,
    required this.accent,
    required this.future,
  });

  final String text;
  final Color accent;
  final Future<List<model.Quest>> future;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 10,
            fontFamily: 'JetBrainsMono',
            letterSpacing: 1.5,
            color: AppPalette.textDim,
          ),
        ),
        FutureBuilder<List<model.Quest>>(
          future: future,
          builder: (ctx, snap) {
            final n = snap.data?.length ?? 0;
            return Text(
              '$n ACTIVE',
              style: TextStyle(
                fontSize: 10,
                fontFamily: 'JetBrainsMono',
                letterSpacing: 1,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            );
          },
        ),
      ],
    );
  }
}

// ─── Daily tab body ────────────────────────────────────────
class _DailyTab extends StatelessWidget {
  const _DailyTab({required this.future});
  final Future<List<model.Quest>> future;

  String _descFor(String? kindKey) {
    switch (kindKey) {
      case 'complete_workout':
        return 'Finish your generated session';
      case 'sets_logged':
        return 'Log every set you finish';
      case 'volume_goal':
        return 'Sum weight × reps across the day';
      case 'compound_lift':
        return 'Hit at least one compound lift';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<model.Quest>>(
      future: future,
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(color: AppPalette.amber),
            ),
          );
        }
        final quests = snap.data ?? const <model.Quest>[];
        if (quests.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: AppPalette.bgCard.withValues(alpha: 0.8),
              border: Border.all(
                color: AppPalette.amber.withValues(alpha: 0.20),
                width: 1,
              ),
            ),
            child: const Text(
              "No daily quests yet — start a workout to trigger today's batch.",
              style: TextStyle(
                fontSize: 12,
                color: AppPalette.textMuted,
              ),
            ),
          );
        }
        return Column(
          children: [
            for (final q in quests) ...[
              _QuestCard(
                quest: q,
                meta: QuestEngine.metaFor(q.description),
                desc: _descFor(q.description),
                accent: AppPalette.amber,
              ),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }
}

class _QuestCard extends StatelessWidget {
  const _QuestCard({
    required this.quest,
    required this.meta,
    required this.desc,
    required this.accent,
    this.phase,
    this.onTap,
  });

  final model.Quest quest;
  final QuestMeta meta;
  final String desc;
  final Color accent;

  /// Optional cadence label (e.g. `WEEK 4 / 6`) shown under the description.
  /// Boss-only — the engine derives this from the issued-at timestamp via
  /// [QuestEngine.bossPhase].
  final String? phase;

  /// Tap-to-drill-down. Boss tiles wire this to push `/boss-detail`.
  final VoidCallback? onTap;

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
    final title = quest.title;
    final xp = quest.xpReward;
    final progress = quest.progress;
    final target = quest.target;
    final done = quest.isCompleted;
    final pct = target == 0 ? 0.0 : (progress / target).clamp(0.0, 1.0);
    final progressColor = done ? AppPalette.success : accent;
    final unit = meta.unit;
    final unitSuffix = unit == null ? '' : ' $unit';
    final progressText =
        '${_formatNum(progress)}$unitSuffix / ${_formatNum(target)}$unitSuffix';
    final icon = meta.icon;
    final card = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: done
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppPalette.success.withValues(alpha: 0.12),
                  AppPalette.bgCard.withValues(alpha: 0.8),
                ],
              )
            : null,
        color: done ? null : AppPalette.bgCard.withValues(alpha: 0.85),
        border: Border.all(
          color: done
              ? AppPalette.success.withValues(alpha: 0.40)
              : accent.withValues(alpha: 0.20),
          width: 1,
        ),
        boxShadow: done
            ? [
                BoxShadow(
                  color: AppPalette.success.withValues(alpha: 0.40),
                  blurRadius: 16,
                  spreadRadius: -6,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon block.
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  color: accent.withValues(alpha: 0.13),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.40),
                    width: 1,
                  ),
                ),
                child: Icon(icon, size: 20, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppPalette.textPrimary,
                              height: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '+${_formatNum(xp)} XP',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'JetBrainsMono',
                            color: accent,
                          ),
                        ),
                      ],
                    ),
                    if (desc.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        desc,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppPalette.textMuted,
                          height: 1.4,
                        ),
                      ),
                    ],
                    if (phase case final p?) ...[
                      const SizedBox(height: 6),
                      Text(
                        p,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          fontFamily: 'JetBrainsMono',
                          color: accent,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress label + count.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progress',
                style: TextStyle(
                  fontSize: 10,
                  color: AppPalette.textMuted,
                ),
              ),
              Text(
                progressText,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'JetBrainsMono',
                  color: progressColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Progress bar.
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Container(
              height: 6,
              color: AppPalette.purple.withValues(alpha: 0.12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: pct,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: done
                          ? const LinearGradient(
                              colors: [
                                AppPalette.success,
                                Color(0xFF4ADE80),
                              ],
                            )
                          : LinearGradient(
                              colors: [
                                accent,
                                AppPalette.amberSoft,
                              ],
                            ),
                      boxShadow: [
                        BoxShadow(
                          color: progressColor.withValues(alpha: 0.55),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (done) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.check, size: 14, color: AppPalette.success),
                const SizedBox(width: 6),
                Text(
                  'CLAIMED',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppPalette.success,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: card,
      ),
    );
  }
}

