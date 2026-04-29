import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/services/auth_service.dart';
import '../../theme/tokens.dart';
import '../../widgets/screen_base.dart';
import 'auth_widgets.dart';

/// Email verification gate — shown immediately after Sign Up. The user
/// has an authenticated session but their `email_confirmed_at` is still
/// null, so they can't add friends yet.
///
/// Two ways forward:
///   1. They tap the link in their email (deep-links back to the app
///      via `levelupirl://email-confirmed`). Auth state stream fires
///      with `userUpdated`, we detect `emailConfirmedAt != null`, and
///      auto-route to the next onboarding step.
///   2. They tap "I've verified — continue" after manually confirming
///      in a browser. We re-check the session, see the flag flipped,
///      and route on.
///
/// "Skip for now" lets them continue offline-first; socials (friends,
/// leaderboard) stay locked until they verify, but the rest of the
/// app works.
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  StreamSubscription<AuthState>? _authSub;
  bool _resending = false;
  bool _checking = false;
  String? _info;
  String? _error;
  int _resendCooldown = 0;
  Timer? _cooldownTicker;

  @override
  void initState() {
    super.initState();
    // Auto-detect verification when the deep-link path lands.
    _authSub = AuthService.authStateChanges.listen((state) {
      if (!mounted) return;
      if (AuthService.isEmailVerified) {
        _onVerified();
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _cooldownTicker?.cancel();
    super.dispose();
  }

  void _onVerified() {
    // Onboarding chain hand-off — once S2 (username + phone) screens
    // land, route to /username here. For v1.x.0's S1 milestone the
    // existing local onboarding starts at /register.
    context.go('/register');
  }

  Future<void> _resend() async {
    final email = AuthService.currentEmail;
    if (email == null) return;
    setState(() {
      _resending = true;
      _info = null;
      _error = null;
    });
    final result = await AuthService.resendVerification(email);
    if (!mounted) return;
    if (result.ok) {
      setState(() {
        _resending = false;
        _info = 'Verification email re-sent. Check your inbox + spam folder.';
        _resendCooldown = 60;
      });
      _startCooldown();
    } else {
      setState(() {
        _resending = false;
        _error = result.errorMessage;
      });
    }
  }

  void _startCooldown() {
    _cooldownTicker?.cancel();
    _cooldownTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _resendCooldown = (_resendCooldown - 1).clamp(0, 999);
      });
      if (_resendCooldown == 0) _cooldownTicker?.cancel();
    });
  }

  Future<void> _checkAndContinue() async {
    setState(() => _checking = true);
    // Refresh the session so the SDK pulls the latest user record.
    if (AuthService.isConfigured) {
      try {
        await Supabase.instance.client.auth.refreshSession();
      } catch (_) {
        // ignore — we'll re-evaluate via the flag.
      }
    }
    if (!mounted) return;
    setState(() => _checking = false);
    if (AuthService.isEmailVerified) {
      _onVerified();
    } else {
      setState(() {
        _error = 'Email not yet verified. Tap the link in your inbox.';
      });
    }
  }

  void _skipForNow() {
    // User opts to keep going offline-first. Socials stay locked until
    // they verify, but the rest of onboarding proceeds normally.
    context.go('/register');
  }

  @override
  Widget build(BuildContext context) {
    final email = AuthService.currentEmail ?? 'your inbox';
    return ScreenBase(
      background: AppPalette.voidBg,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const Center(child: _MailIcon()),
              const SizedBox(height: 28),
              const Text(
                'CHECK YOUR EMAIL',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 36,
                  fontFamily: 'BebasNeue',
                  letterSpacing: 1,
                  height: 1.05,
                  color: AppPalette.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: "We sent a verification link to "),
                    TextSpan(
                      text: email,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppPalette.textPrimary,
                      ),
                    ),
                    const TextSpan(text: '. Tap the link to confirm your address.'),
                  ],
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppPalette.textMuted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              if (_info != null) ...[
                AuthSuccessBanner(message: _info!),
                const SizedBox(height: 12),
              ],
              if (_error != null) ...[
                AuthErrorBanner(message: _error!),
                const SizedBox(height: 12),
              ],
              const Spacer(),
              PrimaryAuthButton(
                label: "I'VE VERIFIED — CONTINUE",
                enabled: !_checking,
                loading: _checking,
                onTap: _checkAndContinue,
              ),
              const SizedBox(height: 10),
              SecondaryAuthButton(
                label: _resendCooldown > 0
                    ? 'RESEND IN ${_resendCooldown}S'
                    : (_resending ? 'SENDING…' : 'RESEND EMAIL'),
                onTap: _resendCooldown > 0 || _resending ? () {} : _resend,
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: _skipForNow,
                  child: const Text(
                    "I'll do this later",
                    style: TextStyle(
                      fontSize: 13,
                      color: AppPalette.textMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MailIcon extends StatelessWidget {
  const _MailIcon();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppPalette.amber, AppPalette.amberSoft],
        ),
        boxShadow: [
          BoxShadow(
            color: AppPalette.amber.withValues(alpha: 0.55),
            blurRadius: 36,
          ),
        ],
      ),
      child: const Icon(
        Icons.mail_outline,
        size: 40,
        color: AppPalette.voidBg,
      ),
    );
  }
}
