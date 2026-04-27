import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../game/quest_engine.dart';
import '../theme/tokens.dart';
import '../widgets/screen_base.dart';

/// PRD §3.2 — celebration shown after a workout that closes a boss
/// quest. Carries the boss [title], the +XP reward, and the awarded
/// [BossBuff]. Persistence already wrote `'buff:<key>@<epoch>'` to
/// `player_class.evolution_history` via [GameHandlers.onWorkoutFinished];
/// this screen is the reward-feedback layer.
class BossCompletionScreen extends StatelessWidget {
  const BossCompletionScreen({
    super.key,
    required this.title,
    required this.xpReward,
    required this.buff,
  });

  final String title;
  final int xpReward;
  final BossBuff buff;

  @override
  Widget build(BuildContext context) {
    return ScreenBase(
      background: AppPalette.voidBg,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            children: [
              const Spacer(),
              const _BossSeal(),
              const SizedBox(height: 28),
              const Text(
                'BOSS DEFEATED',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  color: AppPalette.flame,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 38,
                  fontFamily: 'BebasNeue',
                  height: 1.05,
                  letterSpacing: 1,
                  color: AppPalette.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              _XpReward(xp: xpReward),
              const SizedBox(height: 16),
              _BuffCard(buff: buff),
              const Spacer(),
              _BackHomeButton(onTap: () => context.go('/home')),
            ],
          ),
        ),
      ),
    );
  }
}

class _BossSeal extends StatelessWidget {
  const _BossSeal();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppPalette.flame.withValues(alpha: 0.35),
            AppPalette.flame.withValues(alpha: 0.0),
          ],
        ),
      ),
      child: Center(
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppPalette.flame, AppPalette.amberSoft],
            ),
            boxShadow: [
              BoxShadow(
                color: AppPalette.flame.withValues(alpha: 0.55),
                blurRadius: 36,
              ),
            ],
          ),
          child: const Icon(
            Icons.shield,
            size: 52,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _XpReward extends StatelessWidget {
  const _XpReward({required this.xp});
  final int xp;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppPalette.amber.withValues(alpha: 0.14),
        border: Border.all(
          color: AppPalette.amber.withValues(alpha: 0.50),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt, size: 22, color: AppPalette.amber),
          const SizedBox(width: 10),
          Text(
            '+$xp XP',
            style: const TextStyle(
              fontSize: 26,
              fontFamily: 'BebasNeue',
              height: 1,
              letterSpacing: 1,
              color: AppPalette.amber,
            ),
          ),
        ],
      ),
    );
  }
}

class _BuffCard extends StatelessWidget {
  const _BuffCard({required this.buff});
  final BossBuff buff;

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
            AppPalette.purple.withValues(alpha: 0.18),
            AppPalette.flame.withValues(alpha: 0.10),
          ],
        ),
        border: Border.all(
          color: AppPalette.purple.withValues(alpha: 0.40),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppPalette.purple.withValues(alpha: 0.20),
              border: Border.all(
                color: AppPalette.purple.withValues(alpha: 0.50),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.shield_moon_outlined,
              size: 26,
              color: AppPalette.purpleSoft,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BUFF AWARDED',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: AppPalette.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  buff.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontFamily: 'BebasNeue',
                    letterSpacing: 1,
                    color: AppPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  buff.desc,
                  style: const TextStyle(
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

class _BackHomeButton extends StatelessWidget {
  const _BackHomeButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: double.infinity,
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
              'BACK TO HOME',
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
