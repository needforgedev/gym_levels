import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/quest.dart' as model;
import '../data/models/workout.dart';
import '../data/services/analytics_service.dart';
import '../data/services/player_service.dart';
import '../data/services/quest_service.dart';
import '../data/services/workout_service.dart';
import '../game/plan_generator.dart';
import '../game/quest_engine.dart';
import '../state/onboarding_flag.dart';
import '../state/player_state.dart';
import '../theme/tokens.dart';
import '../widgets/in_app_shell.dart';
import '../widgets/neon_card.dart';
import '../widgets/pills.dart';
import '../widgets/progress_bar.dart';
import '../widgets/tab_bar.dart';

/// Home screen — matches design v2 (`design/v2/screens-home.jsx`).
///
/// Layout (top → bottom):
///   1. Top bar — greeting + name + class line + avatar slot
///   2. Level + Total XP strip — two side-by-side mini cards
///   3. XP progress bar with shimmer
///   4. Total Workouts + Streak row
///   5. Next Workout card (clickable, opens Today's Workout)
///   6. Today's Quest card
///   7. START WORKOUT teal CTA
///
/// Floating glass tab bar lives at the bottom, layered by [InAppShell].
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<model.Quest>> _dailyQuests;
  late Future<int> _totalWorkouts;
  late Future<_HomeSession> _session;

  @override
  void initState() {
    super.initState();
    _dailyQuests = _loadDailyQuests();
    _totalWorkouts = WorkoutService.totalFinished();
    _session = _loadSession();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeCompleteOnboarding());
  }

  Future<List<model.Quest>> _loadDailyQuests() async {
    // Daily rotation runs every Home mount; weekly + boss are also
    // refreshed here so a user landing on Home Monday morning gets a
    // fresh weekly batch and any never-seeded boss rows show up.
    await QuestEngine.rotateDailyIfNeeded();
    await QuestEngine.rotateWeeklyIfNeeded();
    await QuestEngine.seedBossesIfNeeded();
    return QuestService.issuedSince('daily', QuestEngine.todayEpoch());
  }

  Future<_HomeSession> _loadSession() async {
    final results = await Future.wait([
      PlanGenerator.todaysSession(),
      WorkoutService.finishedToday(),
    ]);
    return _HomeSession(
      plan: results[0] as SessionPlan?,
      doneToday: results[1] as Workout?,
    );
  }

  Future<void> _maybeCompleteOnboarding() async {
    if (!mounted) return;
    final state = context.read<PlayerState>();
    if (state.player == null) {
      await state.refresh();
    }
    if (!mounted) return;
    final already = state.player?.isOnboarded ?? false;
    if (already) return;

    await PlayerService.completeOnboarding();
    await AnalyticsService.log('onboarding_completed', {
      'source': 'home_first_render',
    });
    isOnboardedNotifier.value = true;
    if (!mounted) return;
    await state.refresh();
  }

  void _startWorkout() {
    context.go('/exercise-picker');
  }

  void _openTodaysWorkout() {
    context.go('/home/todays-workout');
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<PlayerState>();
    final safeBottom = MediaQuery.of(context).padding.bottom;
    return InAppShell(
      active: AppTab.home,
      title: 'HOME',
      showHeader: false,
      child: Stack(
        children: [
          // Atmospheric hero-character bg silhouette anchored top-right.
          // Faded with a vertical mask so the bottom half of the screen
          // stays clean for the START WORKOUT CTA.
          const Positioned(
            right: -30,
            top: 40,
            width: 260,
            height: 380,
            child: IgnorePointer(child: _HeroSilhouetteBg()),
          ),
          // Faint violet grid texture (very subtle) — mirrors the design.
          const Positioned.fill(
            child: IgnorePointer(child: _GridTextureBg()),
          ),
          ListView(
            padding: EdgeInsets.fromLTRB(
              0,
              0,
              0,
              InAppShell.tabBarSafeBottom + safeBottom,
            ),
            children: [
              _TopBar(
                name: s.playerName,
                className: s.playerClass.displayName,
                level: s.level,
                onAvatar: () => context.go('/profile'),
                onOpenFriends: () => context.go('/friends'),
              ),
              _LevelXpStrip(level: s.level, totalXp: s.totalXp),
              _XpProgressBlock(
                level: s.level,
                xpInto: s.xpCurrent,
                xpMax: s.xpMax,
              ),
              _StatRow(
                totalWorkoutsFuture: _totalWorkouts,
                streak: s.streak,
                onStreakTap: () => context.go('/streak'),
                onTotalWorkoutsTap: () => context.go('/workouts'),
              ),
              _NextWorkoutBlock(
                future: _session,
                onTap: _openTodaysWorkout,
              ),
              _TodaysQuestBlock(future: _dailyQuests),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _StartWorkoutButton(onTap: _startWorkout),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Background atmospherics (hero silhouette + grid) ─────────────

class _HeroSilhouetteBg extends StatelessWidget {
  const _HeroSilhouetteBg();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (rect) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.black, Colors.black, Colors.transparent],
        stops: [0, 0.6, 1.0],
      ).createShader(rect),
      child: Opacity(
        opacity: 0.30,
        child: Image.asset(
          'assets/hero-character.png',
          fit: BoxFit.cover,
          alignment: Alignment.topRight,
        ),
      ),
    );
  }
}

class _GridTextureBg extends StatelessWidget {
  const _GridTextureBg();
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: const _GridPainter());
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppPalette.purpleSoft.withValues(alpha: 0.04)
      ..strokeWidth = 1;
    const step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) => false;
}

// ─── Hex frame helper ─────────────────────────────────────────────

class _HexFrame extends StatelessWidget {
  const _HexFrame({
    required this.size,
    required this.child,
    this.fillColor,
    this.strokeColor,
    this.glow = false,
    this.strokeWidth = 2,
  });

  final double size;
  final Widget child;
  final Color? fillColor;
  final Color? strokeColor;
  final bool glow;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final fill = fillColor ?? AppPalette.purple.withValues(alpha: 0.15);
    final stroke = strokeColor ?? AppPalette.purple.withValues(alpha: 0.6);
    return SizedBox(
      width: size,
      height: size * 1.155,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _HexPainter(
                fill: fill,
                stroke: stroke,
                strokeWidth: strokeWidth,
                glow: glow,
              ),
            ),
          ),
          Positioned.fill(child: Center(child: child)),
        ],
      ),
    );
  }
}

class _HexPainter extends CustomPainter {
  const _HexPainter({
    required this.fill,
    required this.stroke,
    required this.strokeWidth,
    required this.glow,
  });
  final Color fill;
  final Color stroke;
  final double strokeWidth;
  final bool glow;

  Path _hexPath(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.5, h * 0.0175)
      ..lineTo(w * 0.96, h * 0.25)
      ..lineTo(w * 0.96, h * 0.75)
      ..lineTo(w * 0.5, h * 0.9825)
      ..lineTo(w * 0.04, h * 0.75)
      ..lineTo(w * 0.04, h * 0.25)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _hexPath(size);
    if (glow) {
      canvas.drawPath(
        path,
        Paint()
          ..color = stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _HexPainter old) =>
      old.fill != fill ||
      old.stroke != stroke ||
      old.strokeWidth != strokeWidth ||
      old.glow != glow;
}

class _HomeSession {
  const _HomeSession({required this.plan, required this.doneToday});
  final SessionPlan? plan;
  final Workout? doneToday;
}

// ─── Top bar (hex avatar + friends hex + welcome + class) ────
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.name,
    required this.className,
    required this.level,
    required this.onAvatar,
    required this.onOpenFriends,
  });
  final String name;
  final String className;
  final int level;
  final VoidCallback onAvatar;
  final VoidCallback onOpenFriends;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hex row — avatar (with LV badge) on the left, Friends hex
          // (with cyan notification dot) on the right.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _PlayerHexAvatar(level: level, onTap: onAvatar),
              _FriendsHex(onTap: onOpenFriends),
            ],
          ),
          const SizedBox(height: 22),
          // Eyebrow — mono-styled like the design.
          Text(
            'WELCOME BACK,',
            style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.5,
              color: AppPalette.purpleSoft,
            ),
          ),
          const SizedBox(height: 4),
          // Hero name — display-font, 56pt to match the design.
          Text(
            _displayName(name),
            style: AppType.displayLG(color: AppPalette.textPrimary)
                .copyWith(
              fontSize: 56,
              height: 0.95,
              letterSpacing: 1.5,
              shadows: [
                Shadow(
                  color: AppPalette.purpleSoft.withValues(alpha: 0.25),
                  blurRadius: 24,
                ),
              ],
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          // Class badge: hex (X-pattern logo) + two-line stack on the right.
          _ClassBadge(name: _displayName(name), className: className),
        ],
      ),
    );
  }

  String _displayName(String raw) {
    if (raw.isEmpty) return 'Player';
    return raw[0].toUpperCase() + raw.substring(1);
  }
}

class _PlayerHexAvatar extends StatelessWidget {
  const _PlayerHexAvatar({required this.level, required this.onTap});
  final int level;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 70,
            height: 76,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                _HexFrame(
                  size: 62,
                  fillColor: AppPalette.purple.withValues(alpha: 0.18),
                  strokeColor: AppPalette.purpleSoft.withValues(alpha: 0.7),
                  glow: true,
                  child: ClipPath(
                    clipper: const _HexClipper(),
                    child: Image.asset(
                      'assets/hero-bust.png',
                      width: 54,
                      height: 54,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Circular LV pill at bottom-right of the hex.
                Positioned(
                  right: 0,
                  bottom: 6,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 22),
                    height: 22,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(11),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF2A1845), Color(0xFF1A0F2B)],
                      ),
                      border: Border.all(
                        color: AppPalette.purpleSoft,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                        BoxShadow(
                          color: AppPalette.purpleSoft.withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Text(
                      '$level',
                      style: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        height: 1,
                        color: AppPalette.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'PROFILE',
            style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 9,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
              color: AppPalette.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendsHex extends StatelessWidget {
  const _FriendsHex({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                _HexFrame(
                  size: 48,
                  fillColor: AppPalette.purple.withValues(alpha: 0.18),
                  strokeColor: AppPalette.purpleSoft.withValues(alpha: 0.7),
                  glow: true,
                  child: Icon(
                    Icons.people_alt_outlined,
                    size: 22,
                    color: AppPalette.textPrimary,
                  ),
                ),
                // Teal notification dot.
                Positioned(
                  right: 6,
                  top: 0,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppPalette.teal,
                      border:
                          Border.all(color: AppPalette.voidBg, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppPalette.teal.withValues(alpha: 0.8),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'FRIENDS',
            style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 9,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
              color: AppPalette.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _HexClipper extends CustomClipper<Path> {
  const _HexClipper();
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.5, h * 0.04)
      ..lineTo(w * 0.96, h * 0.28)
      ..lineTo(w * 0.96, h * 0.78)
      ..lineTo(w * 0.5, h)
      ..lineTo(w * 0.08, h * 0.78)
      ..lineTo(w * 0.08, h * 0.28)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Class badge — hex icon (X-pattern logo) on the left, stacked
/// `name` (display font) + `MASS BUILDER CLASS` mono caption on the
/// right. Mirrors `screens-home.jsx` lines 156-170.
class _ClassBadge extends StatelessWidget {
  const _ClassBadge({required this.name, required this.className});
  final String name;
  final String className;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _HexFrame(
          size: 48,
          fillColor: AppPalette.purple.withValues(alpha: 0.18),
          strokeColor: AppPalette.purpleSoft.withValues(alpha: 0.55),
          strokeWidth: 1.5,
          child: SizedBox(
            width: 22,
            height: 22,
            child: CustomPaint(painter: const _XPatternPainter()),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              name,
              style: AppType.displaySM(color: AppPalette.textPrimary)
                  .copyWith(
                fontSize: 18,
                letterSpacing: 1.5,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${className.toUpperCase()} CLASS',
              style: TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 10,
                letterSpacing: 2,
                fontWeight: FontWeight.w700,
                color: AppPalette.purpleSoft,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// X-pattern logo: two diagonal lines + a circle at each corner.
/// Matches the design's class-hex content.
class _XPatternPainter extends CustomPainter {
  const _XPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..color = AppPalette.purpleSoft
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.21, size.height * 0.21),
      Offset(size.width * 0.79, size.height * 0.79),
      stroke,
    );
    canvas.drawLine(
      Offset(size.width * 0.79, size.height * 0.21),
      Offset(size.width * 0.21, size.height * 0.79),
      stroke,
    );
    final dot = Paint()..color = AppPalette.purpleSoft;
    final r = size.width * 0.083;
    canvas.drawCircle(
      Offset(size.width * 0.21, size.height * 0.21),
      r,
      dot,
    );
    canvas.drawCircle(
      Offset(size.width * 0.79, size.height * 0.21),
      r,
      dot,
    );
    canvas.drawCircle(
      Offset(size.width * 0.21, size.height * 0.79),
      r,
      dot,
    );
    canvas.drawCircle(
      Offset(size.width * 0.79, size.height * 0.79),
      r,
      dot,
    );
  }

  @override
  bool shouldRepaint(covariant _XPatternPainter old) => false;
}

// (Old `_HeroAvatar` widget removed — replaced by `_PlayerHexAvatar`
// at the top of this file as part of the v1-improvements design.)

// ─── Level + Total XP strip ────────────────────────────────
class _LevelXpStrip extends StatelessWidget {
  const _LevelXpStrip({required this.level, required this.totalXp});
  final int level;
  final int totalXp;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      // Design v2 widths: Level flex 1, Total XP flex 1.3. Flutter's flex is
      // int-only, so use 10:13 to preserve the same proportions.
      child: Row(
        children: [
          Expanded(
            flex: 10,
            child: _StripCard(
              icon: Icons.star,
              iconColor: AppPalette.amber,
              kicker: 'LEVEL',
              value: 'LV $level',
              valueColor: AppPalette.amber,
              tint: AppPalette.amber,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 13,
            child: _StripCard(
              icon: Icons.bolt,
              iconColor: AppPalette.purpleSoft,
              kicker: 'TOTAL XP',
              value: _format(totalXp),
              valueColor: AppPalette.purpleSoft,
              tint: AppPalette.purple,
            ),
          ),
        ],
      ),
    );
  }

  static String _format(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final fromEnd = s.length - i;
      buf.write(s[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }
}

class _StripCard extends StatelessWidget {
  const _StripCard({
    required this.icon,
    required this.iconColor,
    required this.kicker,
    required this.value,
    required this.valueColor,
    required this.tint,
  });

  final IconData icon;
  final Color iconColor;
  final String kicker;
  final String value;
  final Color valueColor;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tint.withValues(alpha: 0.20),
            tint.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tint.withValues(alpha: 0.40),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  kicker,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: AppPalette.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: AppType.displayMD(color: valueColor)
                        .copyWith(fontSize: 22, height: 1),
                    maxLines: 1,
                    softWrap: false,
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

// ─── XP progress block ─────────────────────────────────────
class _XpProgressBlock extends StatelessWidget {
  const _XpProgressBlock({
    required this.level,
    required this.xpInto,
    required this.xpMax,
  });

  final int level;
  final int xpInto;
  final int xpMax;

  @override
  Widget build(BuildContext context) {
    final pct = xpMax == 0 ? 0.0 : (xpInto / xpMax * 100).clamp(0, 100);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress to Level ${level + 1}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppPalette.textMuted,
                ),
              ),
              Text(
                '${pct.round()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.amber,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          XpBar(percent: pct.toDouble(), height: 10),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$xpInto XP',
                style: TextStyle(
                  fontSize: 10,
                  color: AppPalette.textDim,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                '$xpMax XP',
                style: TextStyle(
                  fontSize: 10,
                  color: AppPalette.textDim,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Total + Streak row ────────────────────────────────────
class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.totalWorkoutsFuture,
    required this.streak,
    required this.onStreakTap,
    required this.onTotalWorkoutsTap,
  });

  final Future<int> totalWorkoutsFuture;
  final int streak;
  final VoidCallback onStreakTap;
  final VoidCallback onTotalWorkoutsTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      // IntrinsicHeight + stretch makes both cards take the height of
      // the taller one, so the violet TOTAL WORKOUTS card and the
      // amber STREAK card always render at identical sizes (regardless
      // of caption length / wrap).
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: FutureBuilder<int>(
                future: totalWorkoutsFuture,
                builder: (ctx, snap) => _StatTile(
                  kicker: 'TOTAL WORKOUTS',
                  value: '${snap.data ?? 0}',
                  caption: 'Workouts Completed',
                  icon: Icons.fitness_center,
                  accent: AppPalette.purpleSoft,
                  valueColor: AppPalette.textPrimary,
                  onTap: onTotalWorkoutsTap,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                kicker: 'STREAK',
                value: '$streak',
                caption: streak > 0 ? 'Days in a row' : 'Start today',
                captionColor: AppPalette.amber,
                icon: Icons.local_fire_department,
                accent: AppPalette.amber,
                valueColor: AppPalette.amber,
                valueGlow: true,
                animateIcon: streak > 0,
                onTap: onStreakTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatefulWidget {
  const _StatTile({
    required this.kicker,
    required this.value,
    required this.caption,
    required this.icon,
    required this.accent,
    required this.valueColor,
    this.captionColor,
    this.valueGlow = false,
    this.animateIcon = false,
    this.onTap,
  });

  final String kicker;
  final String value;
  final String caption;
  final IconData icon;
  final Color accent;
  final Color valueColor;
  final Color? captionColor;
  final bool valueGlow;
  final bool animateIcon;
  final VoidCallback? onTap;

  @override
  State<_StatTile> createState() => _StatTileState();
}

class _StatTileState extends State<_StatTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    if (widget.animateIcon) _ctl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      padding: const EdgeInsets.all(14),
      glow: GlowColor.purple,
      pulse: false,
      onTap: widget.onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.kicker,
                  // Mono 9pt to match the design (`screens-home.jsx`
                  // line 223). Single-line so "TOTAL WORKOUTS" doesn't
                  // wrap and force the card taller than its sibling.
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: AppPalette.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.value,
                  style: AppType.displayLG(color: widget.valueColor).copyWith(
                    fontSize: 34,
                    height: 1,
                    shadows: widget.valueGlow
                        ? [
                            Shadow(
                              color: widget.accent.withValues(alpha: 0.6),
                              blurRadius: 12,
                            ),
                          ]
                        : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.caption,
                  style: TextStyle(
                    fontSize: 10,
                    color: widget.captionColor ?? AppPalette.textMuted,
                    fontWeight: widget.captionColor == null
                        ? FontWeight.w400
                        : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Hex icon — matches the design's hexagonal accent shape on
          // each stat card. Animates a pulsing glow on streak when
          // `animateIcon` is true.
          AnimatedBuilder(
            animation: _ctl,
            builder: (context, _) {
              return _HexFrame(
                size: 36,
                fillColor: widget.accent.withValues(alpha: 0.18),
                strokeColor: widget.accent.withValues(
                  alpha: widget.animateIcon
                      ? 0.55 + _ctl.value * 0.35
                      : 0.55,
                ),
                strokeWidth: 1.5,
                glow: widget.animateIcon,
                child: Icon(
                  widget.icon,
                  size: 18,
                  color: widget.accent,
                  shadows: widget.animateIcon
                      ? [
                          Shadow(
                            color: widget.accent.withValues(
                              alpha: 0.5 + _ctl.value * 0.4,
                            ),
                            blurRadius: 6 + _ctl.value * 8,
                          ),
                        ]
                      : null,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Next Workout block (real plan + done-today + no-schedule states) ─
class _NextWorkoutBlock extends StatelessWidget {
  const _NextWorkoutBlock({required this.future, required this.onTap});
  final Future<_HomeSession> future;
  final VoidCallback onTap;

  /// Maps the focus label back to a muscle-grouping category for the
  /// subtitle line on the Next Workout card. Matches the design's
  /// `USER.nextWorkout.category` field.
  static String _categoryFor(String focus) {
    final f = focus.toLowerCase();
    if (f.contains('push') || f.contains('pull') || f.contains('upper')) {
      return 'Upper Body';
    }
    if (f.contains('leg') || f.contains('lower')) return 'Lower Body';
    if (f.contains('full')) return 'Full Body';
    return 'Mixed';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'NEXT WORKOUT',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: AppPalette.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          FutureBuilder<_HomeSession>(
            future: future,
            builder: (ctx, snap) {
              final data = snap.data;
              final plan = data?.plan;
              final done = data?.doneToday;
              final settled = snap.connectionState == ConnectionState.done;

              if (!settled) {
                return _NextWorkoutCard(
                  title: 'LOADING…',
                  subtitle: '…calibrating your session',
                  pills: const [],
                  iconAccent: AppPalette.purpleSoft,
                  onTap: null,
                );
              }
              if (done != null) {
                return _NextWorkoutCard(
                  title: (plan?.focus ?? 'COMPLETED'),
                  subtitle:
                      'Done today · +${done.xpEarned} XP · ${done.volumeKg.round()}kg',
                  pills: const [],
                  iconAccent: AppPalette.success,
                  iconData: Icons.check_circle,
                  onTap: () => GoRouter.of(context).go('/workouts/${done.id}'),
                  glow: GlowColor.green,
                );
              }
              if (plan == null) {
                return _NextWorkoutCard(
                  title: 'PICK TRAINING DAYS',
                  subtitle: 'Tap to set your weekly schedule.',
                  pills: const [],
                  iconAccent: AppPalette.teal,
                  iconData: Icons.event_outlined,
                  onTap: () => GoRouter.of(context).go('/training-days'),
                  glow: GlowColor.teal,
                );
              }
              if (plan.exercises.isEmpty) {
                return _NextWorkoutCard(
                  title: plan.focus,
                  subtitle: 'No matching exercises — tap to add equipment.',
                  pills: const [],
                  iconAccent: AppPalette.teal,
                  iconData: Icons.tune,
                  onTap: () => GoRouter.of(context).go('/equipment'),
                  glow: GlowColor.teal,
                );
              }
              final muscleSet = <String>{};
              for (final e in plan.exercises) {
                final lower = e.name.toLowerCase();
                if (lower.contains('press') || lower.contains('bench') || lower.contains('push')) {
                  muscleSet.add('Chest');
                }
                if (lower.contains('shoulder') || lower.contains('lateral') || lower.contains('overhead')) {
                  muscleSet.add('Shoulders');
                }
                if (lower.contains('tricep') || lower.contains('dip')) {
                  muscleSet.add('Triceps');
                }
                if (lower.contains('row') || lower.contains('pull')) {
                  muscleSet.add('Back');
                }
                if (lower.contains('curl') && !lower.contains('nordic')) {
                  muscleSet.add('Biceps');
                }
                if (lower.contains('squat') || lower.contains('lunge')) {
                  muscleSet.add('Legs');
                }
                if (lower.contains('glute') || lower.contains('bridge')) {
                  muscleSet.add('Glutes');
                }
              }
              final pills = muscleSet.take(3).toList();

              return _NextWorkoutCard(
                title: plan.focus,
                subtitle:
                    '${_categoryFor(plan.focus)} · ~${plan.estimatedMinutes} min · ${plan.exercises.length} exercises',
                pills: pills,
                iconAccent: AppPalette.purpleSoft,
                onTap: onTap,
                glow: plan.isScheduled ? GlowColor.purple : GlowColor.teal,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NextWorkoutCard extends StatelessWidget {
  const _NextWorkoutCard({
    required this.title,
    required this.subtitle,
    required this.pills,
    required this.iconAccent,
    this.iconData = Icons.fitness_center,
    this.onTap,
    this.glow = GlowColor.purple,
  });

  final String title;
  final String subtitle;
  final List<String> pills;
  final Color iconAccent;
  final IconData iconData;
  final VoidCallback? onTap;
  final GlowColor glow;

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      glow: glow,
      pulse: false,
      padding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      onTap: onTap,
      // IntrinsicHeight makes the Row size to the tallest child's natural
      // height so the violet icon column on the left can stretch alongside
      // the text column on the right (the CSS prototype gets this for free
      // via flex's `align-items: stretch`).
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 80,
              decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  iconAccent.withValues(alpha: 0.30),
                  iconAccent.withValues(alpha: 0.10),
                ],
              ),
              border: Border(
                right: BorderSide(
                  color: iconAccent.withValues(alpha: 0.20),
                  width: 1,
                ),
              ),
            ),
            child: Center(
              child: Icon(iconData, size: 36, color: iconAccent),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppType.displayMD(color: AppPalette.textPrimary)
                        .copyWith(fontSize: 22, height: 1),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppPalette.textMuted,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (pills.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final p in pills)
                          AppPill(label: p, dense: true),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Icon(
              Icons.chevron_right,
              color: AppPalette.textMuted,
              size: 20,
            ),
          ),
        ],
      ),
      ),
    );
  }
}

// ─── Today's Quest block ───────────────────────────────────
class _TodaysQuestBlock extends StatelessWidget {
  const _TodaysQuestBlock({required this.future});
  final Future<List<model.Quest>> future;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "TODAY'S QUEST",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: AppPalette.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<model.Quest>>(
            future: future,
            builder: (ctx, snap) {
              final quests = snap.data ?? const <model.Quest>[];
              if (quests.isEmpty) {
                return _QuestCard(
                  title: 'Rotating today\'s quests…',
                  progress: 0,
                  subtitle: '',
                  reward: 0,
                  done: false,
                );
              }
              // Show the first not-yet-completed quest; if all done, show
              // the first completed one stamped DONE.
              final pending = quests.firstWhere(
                (q) => !q.isCompleted,
                orElse: () => quests.first,
              );
              final p = pending.target == 0
                  ? 0.0
                  : pending.progress / pending.target;
              return _QuestCard(
                title: pending.title,
                progress: pending.isCompleted ? 1.0 : p.clamp(0.0, 1.0),
                subtitle:
                    'Progress: ${pending.progress} / ${pending.target}',
                reward: pending.xpReward,
                done: pending.isCompleted,
                onTap: () => GoRouter.of(context).go('/quests'),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _QuestCard extends StatelessWidget {
  const _QuestCard({
    required this.title,
    required this.progress,
    required this.subtitle,
    required this.reward,
    required this.done,
    this.onTap,
  });

  final String title;
  final double progress;
  final String subtitle;
  final int reward;
  final bool done;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = done ? AppPalette.success : AppPalette.amber;
    return NeonCard(
      padding: const EdgeInsets.all(14),
      glow: GlowColor.purple,
      pulse: false,
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: accent.withValues(alpha: 0.15),
              border: Border.all(
                color: accent.withValues(alpha: 0.30),
                width: 1,
              ),
            ),
            child: Icon(
              done ? Icons.check : Icons.gps_fixed,
              size: 20,
              color: accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppPalette.textPrimary,
                    decoration:
                        done ? TextDecoration.lineThrough : TextDecoration.none,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppPalette.textMuted,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: SizedBox(
                    height: 4,
                    child: Stack(
                      children: [
                        Container(
                          color: accent.withValues(alpha: 0.15),
                        ),
                        FractionallySizedBox(
                          widthFactor: progress.clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: accent,
                              boxShadow: [
                                BoxShadow(color: accent, blurRadius: 6),
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
          const SizedBox(width: 8),
          Text(
            '+$reward XP',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: accent,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Start Workout teal CTA ────────────────────────────────
/// START WORKOUT CTA — outlined teal pill with bolt-circle on the left,
/// big display-font label centered, and a chevron-right on the right.
/// Matches `screens-home.jsx` lines 327-352:
///   • 60px tall, 30 radius (full pill)
///   • Translucent teal gradient bg (`rgba(25,227,227,0.18)` →
///     `rgba(25,227,227,0.08)`), 2px solid teal border
///   • Outer teal glow (24px blur, 50% alpha) + inset inner glow
///   • Bolt-circle (36×36) on left, label in 22pt teal display font
///     with text-shadow glow, chevron-right on the right
class _StartWorkoutButton extends StatelessWidget {
  const _StartWorkoutButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppPalette.teal.withValues(alpha: 0.18),
                AppPalette.teal.withValues(alpha: 0.08),
              ],
            ),
            border: Border.all(color: AppPalette.teal, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppPalette.teal.withValues(alpha: 0.5),
                blurRadius: 24,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Inset inner glow — stays beneath the content.
              Positioned.fill(
                child: IgnorePointer(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 1.0,
                          colors: [
                            AppPalette.teal.withValues(alpha: 0.15),
                            Colors.transparent,
                          ],
                          stops: const [0, 0.7],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Bolt-circle on the left.
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppPalette.teal.withValues(alpha: 0.18),
                      border: Border.all(
                        color: AppPalette.teal.withValues(alpha: 0.55),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.bolt,
                      size: 18,
                      color: AppPalette.teal,
                    ),
                  ),
                  // Centered label — display font, glowing teal.
                  Text(
                    'START WORKOUT',
                    style: AppType.displayLG(color: AppPalette.teal)
                        .copyWith(
                      fontSize: 22,
                      letterSpacing: 3,
                      height: 1,
                      shadows: [
                        Shadow(
                          color: AppPalette.teal.withValues(alpha: 0.6),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: AppPalette.teal,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
