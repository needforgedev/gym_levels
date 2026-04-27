import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/services/muscle_rank_service.dart';
import '../game/rank_engine.dart';
import '../theme/tokens.dart';
import '../widgets/screen_base.dart';

/// Muscle Rankings drill-down — matches design v2 (`screens-progress.jsx`
/// `RanksScreen`). Shows a violet-haloed body silhouette + an "OVERALL
/// RANK" amber pill + per-muscle rows with letter badge, name, progress
/// bar, tier + XP.
class RanksScreen extends StatefulWidget {
  const RanksScreen({super.key});

  @override
  State<RanksScreen> createState() => _RanksScreenState();
}

class _MuscleRow {
  const _MuscleRow({
    required this.key,
    required this.name,
    required this.tier,
    required this.subRank,
    required this.color,
    required this.xp,
    required this.pct,
  });
  final String key;
  final String name;
  final String tier; // 'bronze' / 'silver' / ...
  final String subRank;
  final Color color;
  final int xp;
  final double pct;
}

class _Bundle {
  const _Bundle({required this.rows, required this.overallTier, required this.overallSub});
  final List<_MuscleRow> rows;
  final String overallTier;
  final String? overallSub;
}

class _RanksScreenState extends State<RanksScreen> {
  late Future<_Bundle> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_Bundle> _load() async {
    final ranks = await MuscleRankService.getAll();
    final byMuscle = {for (final r in ranks) r.muscle: r};
    final rows = <_MuscleRow>[];
    var totalXp = 0;
    for (final m in RankEngine.trackedMuscles) {
      final mr = byMuscle[m];
      final xp = mr?.rankXp ?? 0;
      final assignment = RankEngine.assign(xp);
      totalXp += xp;
      rows.add(_MuscleRow(
        key: m,
        name: _titleCase(m),
        tier: assignment.rank,
        subRank: assignment.subRank ?? '',
        color: _colorFor(assignment.rank),
        xp: xp,
        pct: RankEngine.progressInTier(xp),
      ));
    }
    final avg = (totalXp / RankEngine.trackedMuscles.length).round();
    final overall = RankEngine.assign(avg);
    return _Bundle(
      rows: rows,
      overallTier: overall.rank,
      overallSub: overall.subRank,
    );
  }

  static String _titleCase(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  static Color _colorFor(String tier) {
    switch (tier) {
      case 'bronze':
        return const Color(0xFFCD7F32);
      case 'silver':
        return const Color(0xFFC9D3E0);
      case 'gold':
        return AppPalette.amber;
      case 'platinum':
        return const Color(0xFF6FC9FF);
      case 'diamond':
        return AppPalette.teal;
      case 'master':
        return AppPalette.purpleSoft;
      case 'grandmaster':
        return AppPalette.flame;
      default:
        return AppPalette.purpleSoft;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenBase(
      background: AppPalette.voidBg,
      child: SafeArea(
        bottom: false,
        child: FutureBuilder<_Bundle>(
          future: _future,
          builder: (ctx, snap) {
            final bundle = snap.data;
            return Column(
              children: [
                _Header(onBack: () => context.go('/profile')),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    children: [
                      // Hero body silhouette with violet halo.
                      Center(child: _HeroBody()),
                      const SizedBox(height: 8),
                      Center(child: _OverallBadge(bundle: bundle)),
                      const SizedBox(height: 18),
                      if (bundle != null)
                        for (final row in bundle.rows) ...[
                          _MuscleRowCard(row: row),
                          const SizedBox(height: 8),
                        ]
                      else
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppPalette.purpleSoft,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppPalette.purple.withValues(alpha: 0.12),
                  border: Border.all(
                    color: AppPalette.purple.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.chevron_left,
                  size: 20,
                  color: AppPalette.textPrimary,
                ),
              ),
            ),
          ),
          const Spacer(),
          const Text(
            'Muscle Rankings',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppPalette.textPrimary,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 38),
        ],
      ),
    );
  }
}

// ─── Hero body silhouette with halo ────────────────────────
class _HeroBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Violet halo behind.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppPalette.purple.withValues(alpha: 0.40),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.7],
                ),
              ),
            ),
          ),
          // Body silhouette painted.
          CustomPaint(
            size: const Size(160, 190),
            painter: _BodyPainter(),
          ),
        ],
      ),
    );
  }
}

class _BodyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;
    final body = Paint()
      ..color = AppPalette.purple.withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;

    // Head.
    canvas.drawCircle(Offset(cx, h * 0.13), w * 0.085, body);

    // Torso.
    final torso = Path()
      ..moveTo(cx - w * 0.18, h * 0.24)
      ..quadraticBezierTo(cx - w * 0.22, h * 0.30, cx - w * 0.21, h * 0.42)
      ..quadraticBezierTo(cx - w * 0.23, h * 0.50, cx - w * 0.16, h * 0.58)
      ..lineTo(cx - w * 0.10, h * 0.65)
      ..lineTo(cx + w * 0.10, h * 0.65)
      ..lineTo(cx + w * 0.16, h * 0.58)
      ..quadraticBezierTo(cx + w * 0.23, h * 0.50, cx + w * 0.21, h * 0.42)
      ..quadraticBezierTo(cx + w * 0.22, h * 0.30, cx + w * 0.18, h * 0.24)
      ..close();
    canvas.drawPath(torso, body);

    // Pec accent (lighter violet).
    final pec = Paint()
      ..color = AppPalette.purpleSoft.withValues(alpha: 0.55);
    final pecPath = Path()
      ..moveTo(cx - w * 0.16, h * 0.27)
      ..quadraticBezierTo(cx, h * 0.31, cx + w * 0.16, h * 0.27)
      ..quadraticBezierTo(cx + w * 0.10, h * 0.38, cx, h * 0.40)
      ..quadraticBezierTo(cx - w * 0.10, h * 0.38, cx - w * 0.16, h * 0.27)
      ..close();
    canvas.drawPath(pecPath, pec);

    // Arms.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - w * 0.32, h * 0.27, w * 0.10, h * 0.32),
        const Radius.circular(8),
      ),
      body,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + w * 0.22, h * 0.27, w * 0.10, h * 0.32),
        const Radius.circular(8),
      ),
      body,
    );

    // Legs.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - w * 0.13, h * 0.65, w * 0.11, h * 0.32),
        const Radius.circular(6),
      ),
      body,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + w * 0.02, h * 0.65, w * 0.11, h * 0.32),
        const Radius.circular(6),
      ),
      body,
    );

    // Eye glow.
    final eye = Paint()..color = AppPalette.purple;
    canvas.drawCircle(Offset(cx - w * 0.025, h * 0.13), 2, eye);
    canvas.drawCircle(Offset(cx + w * 0.025, h * 0.13), 2, eye);
  }

  @override
  bool shouldRepaint(covariant _BodyPainter old) => false;
}

// ─── Overall rank pill ─────────────────────────────────────
class _OverallBadge extends StatelessWidget {
  const _OverallBadge({required this.bundle});
  final _Bundle? bundle;

  @override
  Widget build(BuildContext context) {
    final tier = bundle?.overallTier ?? 'bronze';
    final sub = bundle?.overallSub ?? '';
    final label = sub.isEmpty
        ? tier.toUpperCase()
        : '${tier.toUpperCase()} $sub';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppPalette.amber.withValues(alpha: 0.20),
            AppPalette.amber.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(
          color: AppPalette.amber.withValues(alpha: 0.50),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppPalette.amber.withValues(alpha: 0.45),
            blurRadius: 24,
            spreadRadius: -6,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'OVERALL RANK',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: AppPalette.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 28,
              fontFamily: 'BebasNeue',
              height: 1,
              color: AppPalette.amber,
              shadows: [
                Shadow(
                  color: AppPalette.amber.withValues(alpha: 0.5),
                  blurRadius: 12,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Per-muscle row ────────────────────────────────────────
class _MuscleRowCard extends StatelessWidget {
  const _MuscleRowCard({required this.row});
  final _MuscleRow row;

  @override
  Widget build(BuildContext context) {
    final tierLabel =
        row.subRank.isEmpty ? row.tier.toUpperCase() : '${row.tier.toUpperCase()} ${row.subRank}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppPalette.bgCard.withValues(alpha: 0.6),
        border: Border.all(
          color: AppPalette.purple.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Letter badge.
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  row.color.withValues(alpha: 0.20),
                  row.color.withValues(alpha: 0.08),
                ],
              ),
              border: Border.all(
                color: row.color.withValues(alpha: 0.50),
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              row.name[0].toUpperCase(),
              style: TextStyle(
                fontFamily: 'BebasNeue',
                fontSize: 16,
                color: row.color,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: SizedBox(
                    height: 3,
                    child: Stack(
                      children: [
                        Container(
                          color: AppPalette.purple.withValues(alpha: 0.10),
                        ),
                        FractionallySizedBox(
                          widthFactor: row.pct.clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: row.color,
                              boxShadow: [
                                BoxShadow(
                                  color: row.color.withValues(alpha: 0.7),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                tierLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'BebasNeue',
                  letterSpacing: 1,
                  color: row.color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${row.xp} XP',
                style: const TextStyle(
                  fontSize: 10,
                  fontFamily: 'JetBrainsMono',
                  color: AppPalette.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right,
            size: 14,
            color: AppPalette.textDim,
          ),
        ],
      ),
    );
  }
}
