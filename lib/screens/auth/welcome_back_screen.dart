import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/services/player_service.dart';
import '../../data/sync/initial_sync.dart';
import '../../state/onboarding_flag.dart';
import '../../theme/tokens.dart';
import '../../widgets/progress_bar.dart';
import '../../widgets/screen_base.dart';

/// Initial-sync hydration screen, shown the first time a returning
/// user signs in on a fresh install. Drives [InitialSync.run] and
/// surfaces progress to the user.
///
/// On `complete` → routes to `/home` (or `/register` for the
/// edge case where the cloud profile somehow has no onboarded_at
/// stamp; the local onboarding flow then takes over and re-pushes
/// updated rows).
///
/// On `error` → shows a "Try again" button that re-runs `InitialSync`
/// from the resume cursor (so a partial pull doesn't restart from
/// scratch).
class WelcomeBackScreen extends StatefulWidget {
  const WelcomeBackScreen({super.key});

  @override
  State<WelcomeBackScreen> createState() => _WelcomeBackScreenState();
}

class _WelcomeBackScreenState extends State<WelcomeBackScreen> {
  late final InitialSync _initial;
  InitialSyncProgress? _last;
  bool _running = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _initial = InitialSync();
    _start();
  }

  Future<void> _start() async {
    if (_running) return;
    setState(() {
      _running = true;
      _error = null;
    });
    final result = await _initial.run(
      onProgress: (p) {
        if (!mounted) return;
        setState(() => _last = p);
      },
    );
    if (!mounted) return;
    setState(() {
      _running = false;
      _error = result.error;
    });
    if (result.complete && mounted) {
      // Refresh the global onboarding-flag from the freshly-hydrated
      // player row before navigating, so the router's redirect lets
      // /home through. (`isOnboardedNotifier` was set during cold-boot
      // when the local DB was empty.)
      final player = await PlayerService.getPlayer();
      isOnboardedNotifier.value = player?.isOnboarded ?? false;
      // Brief beat so the user actually sees the "Done" state.
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      // If the cloud profile didn't have `onboarded_at` (returning
      // user who never finished onboarding), fall through to /age —
      // identity (handle + phone) is already in the cloud row at
      // this point, so the only thing left is the local onboarding.
      context.go(isOnboardedNotifier.value ? '/home' : '/age');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _last;
    final pct = ((p?.fractionComplete ?? 0) * 100).round();
    final tableLabel = p?.tableDisplayName ?? 'Profile';
    final rowsLabel = p == null
        ? '…'
        : (p.complete
            ? 'All set.'
            : '${p.tableDisplayName} · ${p.rowsThisTable} rows');

    return ScreenBase(
      background: AppPalette.obsidian,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.s8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: AppPalette.teal),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  boxShadow: [
                    BoxShadow(
                      color: AppPalette.teal.withValues(alpha: 0.4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Text(
                  'WELCOME BACK',
                  style: AppType.label(color: AppPalette.teal),
                ),
              ),
              const SizedBox(height: AppSpace.s6),
              Text(
                'RESTORING\nYOUR HISTORY',
                textAlign: TextAlign.center,
                style: AppType.displayLG(color: AppPalette.textPrimary),
              ),
              const SizedBox(height: AppSpace.s6),
              SizedBox(
                width: 280,
                child: Column(
                  children: [
                    Bar(percent: pct.toDouble(), color: AppPalette.teal, height: 4),
                    const SizedBox(height: 10),
                    Text(
                      '$pct%',
                      textAlign: TextAlign.center,
                      style: AppType.monoMD(color: AppPalette.teal),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.s6),
              Text(
                rowsLabel,
                textAlign: TextAlign.center,
                style: AppType.system(color: AppPalette.textMuted),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpace.s6),
                Text(
                  'Sync paused — check your connection.',
                  textAlign: TextAlign.center,
                  style: AppType.system(color: AppPalette.amber),
                ),
                const SizedBox(height: AppSpace.s4),
                _RetryButton(onTap: _start, enabled: !_running),
                const SizedBox(height: AppSpace.s2),
                _SkipButton(onTap: () => context.go('/home')),
              ] else if (!_running && p != null && !p.complete) ...[
                const SizedBox(height: AppSpace.s6),
                _SkipButton(onTap: () => context.go('/home')),
              ],
              if (p != null && !p.complete) ...[
                const SizedBox(height: AppSpace.s2),
                Text(
                  'Step ${p.tableIndex + 1} of ${p.tableCount} · $tableLabel',
                  textAlign: TextAlign.center,
                  style: AppType.system(color: AppPalette.textDisabled),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RetryButton extends StatelessWidget {
  const _RetryButton({required this.onTap, required this.enabled});
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: enabled ? onTap : null,
      child: Text(
        'Try again',
        style: AppType.label(color: AppPalette.teal),
      ),
    );
  }
}

class _SkipButton extends StatelessWidget {
  const _SkipButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: Text(
        'Continue without sync',
        style: AppType.label(color: AppPalette.textMuted),
      ),
    );
  }
}
