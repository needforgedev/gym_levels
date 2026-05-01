import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/streak.dart';
import '../data/services/player_service.dart';
import '../data/services/streak_service.dart';
import '../data/services/workout_service.dart';
import '../state/onboarding_flag.dart';
import '../state/player_state.dart';
import '../theme/tokens.dart';
import '../widgets/class_sheet.dart';
import '../widgets/in_app_shell.dart';
import '../widgets/progress_bar.dart';
import '../widgets/tab_bar.dart';

/// Profile — matches design v2 (`design/v2/screens-progress.jsx`
/// `ProfileScreen`).
///
/// Layout (top → bottom):
///   • Centered "Profile" small title.
///   • Header card: hero avatar + name + email + edit icon, LV/XP pill row,
///     amber "Progress to Level N" bar with start/target XP labels, "PRO
///     MEMBER" amber pill (only when subscription says so).
///   • Player Class card — amber-bordered with dumbbell icon, MASS BUILDER
///     headline, descriptor.
///   • BODY STATS section: Age / Height / BMI / Weight rows in a card.
///   • Menu list: Muscle Rankings, Edit Onboarding, Notifications,
///     Subscription, Sign Out (red).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileBundle {
  const _ProfileBundle({
    required this.workoutCount,
    required this.streak,
  });
  final int workoutCount;
  final Streak? streak;
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<_ProfileBundle> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ProfileBundle> _load() async {
    final results = await Future.wait([
      WorkoutService.totalFinished(),
      StreakService.get(),
    ]);
    return _ProfileBundle(
      workoutCount: results[0] as int,
      streak: results[1] as Streak?,
    );
  }

  Future<void> _signOut() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppPalette.bgCard,
        title: const Text(
          'Sign out and wipe data?',
          style: TextStyle(color: AppPalette.textPrimary),
        ),
        content: const Text(
          'This deletes the player profile, every workout, every set, and resets onboarding. The exercise catalog stays.',
          style: TextStyle(color: AppPalette.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL',
                style: TextStyle(color: AppPalette.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('SIGN OUT',
                style: TextStyle(color: AppPalette.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await PlayerService.deleteAll();
    isOnboardedNotifier.value = false;
    if (!mounted) return;
    await context.read<PlayerState>().refresh();
    if (!mounted) return;
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<PlayerState>();
    return InAppShell(
      active: AppTab.profile,
      title: 'PROFILE',
      showHeader: false,
      child: FutureBuilder<_ProfileBundle>(
        future: _future,
        builder: (ctx, snap) {
          return ListView(
            padding: EdgeInsets.fromLTRB(
              0,
              0,
              0,
              InAppShell.tabBarSafeBottom +
                  MediaQuery.of(context).padding.bottom,
            ),
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Center(
                  child: Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppPalette.textPrimary,
                    ),
                  ),
                ),
              ),
              // Header card.
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: _HeaderCard(state: s),
              ),
              // Player Class card.
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: _PlayerClassCard(
                  className: s.playerClass.displayName,
                  descriptor: s.playerClass.descriptor,
                  onTap: () => showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (_) => PlayerClassSheet(
                      classDef: s.playerClass,
                    ),
                  ),
                ),
              ),
              // Body Stats.
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: _BodyStatsSection(state: s),
              ),
              // Menu list.
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: _MenuList(onSignOut: _signOut),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Header card ───────────────────────────────────────────
class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.state});
  final PlayerState state;

  @override
  Widget build(BuildContext context) {
    final levelPct = state.xpMax == 0
        ? 0.0
        : (state.xpCurrent / state.xpMax).clamp(0.0, 1.0) * 100;
    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const _ProfileAvatar(size: 64),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.playerName.isEmpty ? 'Player' : state.playerName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'local profile',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppPalette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              _SmallIconButton(
                icon: Icons.edit_outlined,
                // Profile-edit modal lands in Chunk C. Until then,
                // the pencil is a no-op (the single Hero Name was
                // claimed in Join Now and is rate-limited 30 days
                // server-side, so there's nothing to edit here yet).
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          // LV / XP pill row.
          Row(
            children: [
              _PillChip(
                tint: AppPalette.amber,
                child: Text(
                  'LV ${state.level}',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'BebasNeue',
                    letterSpacing: 1,
                    color: AppPalette.amber,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _PillChip(
                tint: AppPalette.purple,
                child: Text(
                  '${_format(state.totalXp)} XP',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'BebasNeue',
                    letterSpacing: 0.5,
                    color: AppPalette.purpleSoft,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Progress bar.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress to Level ${state.level + 1}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppPalette.textMuted,
                ),
              ),
              Text(
                '${levelPct.round()}%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'JetBrainsMono',
                  color: AppPalette.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          XpBar(percent: levelPct, height: 8),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${state.xpCurrent} XP',
                style: const TextStyle(
                  fontSize: 9,
                  fontFamily: 'JetBrainsMono',
                  color: AppPalette.textDim,
                ),
              ),
              Text(
                '${state.xpMax} XP',
                style: const TextStyle(
                  fontSize: 9,
                  fontFamily: 'JetBrainsMono',
                  color: AppPalette.textDim,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // PRO MEMBER pill (always visible until SubscriptionService is wired).
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: AppPalette.amber.withValues(alpha: 0.15),
                border: Border.all(
                  color: AppPalette.amber.withValues(alpha: 0.40),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shield_outlined,
                      size: 11, color: AppPalette.amber),
                  const SizedBox(width: 6),
                  Text(
                    'PRO MEMBER',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      color: AppPalette.amber,
                    ),
                  ),
                ],
              ),
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

// ─── Player Class card (amber-bordered) ────────────────────
class _PlayerClassCard extends StatelessWidget {
  const _PlayerClassCard({
    required this.className,
    required this.descriptor,
    this.onTap,
  });

  final String className;
  final String descriptor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppPalette.amber.withValues(alpha: 0.15),
                AppPalette.purple.withValues(alpha: 0.10),
              ],
            ),
            border: Border.all(
              color: AppPalette.amber.withValues(alpha: 0.45),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppPalette.amber.withValues(alpha: 0.25),
                blurRadius: 24,
                spreadRadius: -4,
              ),
            ],
          ),
          child: Row(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppPalette.amber.withValues(alpha: 0.30),
                  AppPalette.purple.withValues(alpha: 0.15),
                ],
              ),
              border: Border.all(
                color: AppPalette.amber.withValues(alpha: 0.50),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppPalette.amber.withValues(alpha: 0.30),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Icon(
              Icons.fitness_center,
              size: 38,
              color: AppPalette.amber,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PLAYER CLASS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: AppPalette.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  className,
                  style: TextStyle(
                    fontSize: 24,
                    fontFamily: 'BebasNeue',
                    height: 1,
                    letterSpacing: 1,
                    color: AppPalette.amber,
                    shadows: [
                      Shadow(
                        color: AppPalette.amber.withValues(alpha: 0.4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  descriptor,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppPalette.textMuted,
                  ),
                ),
              ],
            ),
          ),
              Icon(Icons.chevron_right, size: 18, color: AppPalette.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Body Stats section ────────────────────────────────────
class _BodyStatsSection extends StatelessWidget {
  const _BodyStatsSection({required this.state});
  final PlayerState state;

  @override
  Widget build(BuildContext context) {
    final p = state.player;
    final age = (p != null && p.age > 0) ? '${p.age} years' : '—';
    final height =
        (p != null && p.heightCm > 0) ? '${p.heightCm.round()} cm' : '—';
    final weight = (p != null && p.weightKg > 0)
        ? '${p.weightKg.toStringAsFixed(1)} kg'
        : '—';
    final bmi = (p != null && p.heightCm > 0 && p.weightKg > 0)
        ? _bmi(p.weightKg, p.heightCm)
        : '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'BODY STATS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: AppPalette.textMuted,
            ),
          ),
        ),
        _PanelCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _StatRow(
                label: 'Age',
                value: age,
                icon: Icons.person_outline,
              ),
              _StatRow(
                label: 'Height',
                value: height,
                icon: Icons.straighten,
              ),
              _StatRow(
                label: 'BMI',
                value: bmi,
                icon: Icons.gps_fixed,
              ),
              _StatRow(
                label: 'Weight',
                value: weight,
                icon: Icons.scale,
                onTap: () => GoRouter.of(context).go('/weight-tracker'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _bmi(double weightKg, double heightCm) {
    final hM = heightCm / 100;
    final v = weightKg / (hM * hM);
    final tier = v < 18.5
        ? 'Underweight'
        : v < 25
            ? 'Normal'
            : v < 30
                ? 'Overweight'
                : 'Obese';
    return '${v.toStringAsFixed(1)} ($tier)';
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    required this.icon,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasDivider = label != 'Age';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: hasDivider
                ? Border(
                    top: BorderSide(
                      color: AppPalette.purple.withValues(alpha: 0.08),
                      width: 1,
                    ),
                  )
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppPalette.purple.withValues(alpha: 0.12),
                ),
                child: Icon(
                  icon,
                  size: 14,
                  color: AppPalette.purpleSoft,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppPalette.textPrimary,
                  ),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppPalette.textMuted,
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 6),
                Icon(Icons.chevron_right,
                    size: 14, color: AppPalette.textDim),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Menu list ─────────────────────────────────────────────
class _MenuList extends StatelessWidget {
  const _MenuList({required this.onSignOut});
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _MenuRow(
            label: 'Muscle Rankings',
            icon: Icons.emoji_events_outlined,
            onTap: () => GoRouter.of(context).go('/ranks'),
          ),
          _MenuRow(
            label: 'Friends',
            icon: Icons.people_alt_outlined,
            onTap: () => GoRouter.of(context).go('/friends'),
          ),
          _MenuRow(
            label: 'Edit Onboarding',
            icon: Icons.edit_outlined,
            onTap: () => GoRouter.of(context).go('/training-days'),
          ),
          _MenuRow(
            label: 'Notifications',
            icon: Icons.notifications_outlined,
            onTap: () => GoRouter.of(context).go('/notification-prefs'),
          ),
          _MenuRow(
            label: 'Subscription',
            icon: Icons.shield_outlined,
            onTap: () => GoRouter.of(context).go('/paywall'),
          ),
          _MenuRow(
            label: 'Sign Out',
            icon: Icons.logout,
            danger: true,
            onTap: onSignOut,
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.label,
    required this.icon,
    required this.onTap,
    this.danger = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppPalette.streak : AppPalette.textPrimary;
    final iconColor = danger ? AppPalette.streak : AppPalette.purpleSoft;
    final iconBg = danger
        ? AppPalette.streak.withValues(alpha: 0.12)
        : AppPalette.purple.withValues(alpha: 0.12);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: label == 'Muscle Rankings'
                ? null
                : Border(
                    top: BorderSide(
                      color: AppPalette.purple.withValues(alpha: 0.08),
                      width: 1,
                    ),
                  ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: iconBg,
                ),
                child: Icon(icon, size: 14, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
              Icon(Icons.chevron_right,
                  size: 14, color: AppPalette.textDim),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Shared mini widgets ───────────────────────────────────
class _PanelCard extends StatelessWidget {
  const _PanelCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xE61A0F2B), Color(0xE6120A1F)],
        ),
        border: Border.all(
          color: AppPalette.borderViolet,
          width: 1,
        ),
      ),
      child: child,
    );
  }
}

class _PillChip extends StatelessWidget {
  const _PillChip({required this.tint, required this.child});
  final Color tint;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: tint.withValues(alpha: 0.15),
        border: Border.all(
          color: tint.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: child,
    );
  }
}

class _SmallIconButton extends StatelessWidget {
  const _SmallIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: AppPalette.purple.withValues(alpha: 0.12),
            border: Border.all(
              color: AppPalette.purple.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Icon(icon, size: 16, color: AppPalette.purpleSoft),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D1B4E), Color(0xFF1A0F2B)],
        ),
        border: Border.all(
          color: AppPalette.purple.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppPalette.purple.withValues(alpha: 0.3),
            blurRadius: 16,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/hero-bust.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
