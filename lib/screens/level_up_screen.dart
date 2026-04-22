import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../state/player_state.dart';
import '../theme/tokens.dart';
import '../widgets/buttons.dart';
import '../widgets/neon_card.dart';
import '../widgets/screen_base.dart';
import '../widgets/system_header.dart';

class LevelUpScreen extends StatefulWidget {
  const LevelUpScreen({super.key});

  @override
  State<LevelUpScreen> createState() => _LevelUpScreenState();
}

class _LevelUpScreenState extends State<LevelUpScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<PlayerState>();
    return ScreenBase(
      child: Stack(
        children: [
          // Radial glow backdrop
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppPalette.xpGold.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                  radius: 0.5,
                ),
              ),
            ),
          ),
          // Rays
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _ctl,
              builder: (context, _) {
                return Transform.rotate(
                  angle: _ctl.value * 6.28319,
                  child: CustomPaint(painter: _RaysPainter()),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpace.s8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SystemHeader(
                  kicker: 'SYSTEM BROADCAST',
                  color: AppPalette.xpGold,
                ),
                const SizedBox(height: AppSpace.s6),
                Text(
                  'LEVEL',
                  style: AppType.displayXL(color: AppPalette.textPrimary)
                      .copyWith(letterSpacing: -1),
                ),
                Text(
                  '${s.level + 1}',
                  style: AppType.monoXL(color: AppPalette.xpGold).copyWith(
                    fontSize: 96,
                    height: 1,
                    shadows: [
                      Shadow(color: AppPalette.xpGold, blurRadius: 24),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.s3),
                Text(
                  'UNLOCKED',
                  style: AppType.displayMD(color: AppPalette.xpGold),
                ),
                const SizedBox(height: AppSpace.s4),
                Text(
                  '…new quests available. +3 attribute points granted.',
                  textAlign: TextAlign.center,
                  style: AppType.system(color: AppPalette.textSecondary),
                ),
                const SizedBox(height: AppSpace.s8),
                NeonCard(
                  glow: GlowColor.xp,
                  padding: const EdgeInsets.all(AppSpace.s5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'REWARDS',
                        style: AppType.label(color: AppPalette.textMuted),
                      ),
                      const SizedBox(height: 10),
                      const _RewardRow(symbol: '+', label: '500 XP BONUS'),
                      const SizedBox(height: AppSpace.s3),
                      const _RewardRow(
                        symbol: '◆',
                        label: 'NEW QUEST: IRON GAUNTLET',
                      ),
                      const SizedBox(height: AppSpace.s3),
                      const _RewardRow(
                        symbol: '✦',
                        label: '+3 ATTRIBUTE POINTS',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.s6),
                PrimaryButton(
                  label: 'CONTINUE',
                  onTap: () => context.go('/home'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RaysPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final paint = Paint()
      ..color = AppPalette.xpGold.withValues(alpha: 0.3);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    for (var i = 0; i < 12; i++) {
      canvas.rotate(6.28319 / 12);
      final path = Path()
        ..moveTo(0, 0)
        ..lineTo(-2, -size.height)
        ..lineTo(2, -size.height)
        ..close();
      canvas.drawPath(path, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RaysPainter oldDelegate) => false;
}

class _RewardRow extends StatelessWidget {
  const _RewardRow({required this.symbol, required this.label});
  final String symbol;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppPalette.xpGold.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: AppPalette.xpGold),
          ),
          child: Text(
            symbol,
            style: AppType.monoMD(color: AppPalette.xpGold).copyWith(
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: AppSpace.s3),
        Expanded(
          child: Text(
            label,
            style: AppType.bodyMD(color: AppPalette.textPrimary),
          ),
        ),
      ],
    );
  }
}
