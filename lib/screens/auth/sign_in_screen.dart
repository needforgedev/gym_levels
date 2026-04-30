import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/services/auth_service.dart';
import '../../data/sync/initial_sync.dart';
import '../../theme/tokens.dart';
import '../../widgets/screen_base.dart';
import 'auth_widgets.dart';

/// Sign In — for returning users on a new device (or after a logout).
/// On success, the SDK persists the session token in secure storage,
/// the user is authenticated, and we route them onward to either Home
/// (if their cloud profile and onboarding answers are present) or to
/// the next-step onboarding screen.
///
/// In v1.x.0 we route to /home unconditionally on success — the
/// initial-sync hydration path (S3b) will handle the "have we pulled
/// their cloud data yet?" question and walk them through whatever
/// missing-state screens are needed.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  bool get _emailValid {
    final v = _emailCtrl.text.trim();
    return v.contains('@') && v.contains('.') && v.length >= 5;
  }

  bool get _passwordValid => _passwordCtrl.text.isNotEmpty;

  bool get _canSubmit => _emailValid && _passwordValid && !_loading;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await AuthService.signIn(
      email: _emailCtrl.text,
      password: _passwordCtrl.text,
    );
    if (!mounted) return;
    if (result.ok) {
      // S3b — first sign-in on this device hydrates from cloud via
      // /welcome-back; subsequent sign-ins (or sign-out + sign-in on
      // a device that already has data) skip straight to /home.
      final needsHydration = await InitialSync.needed();
      if (!mounted) return;
      context.go(needsHydration ? '/welcome-back' : '/home');
    } else {
      setState(() {
        _loading = false;
        _error = result.errorMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenBase(
      background: AppPalette.voidBg,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: AuthBackChip(onTap: () => context.go('/signup')),
              ),
              const SizedBox(height: 24),
              const Text(
                'WELCOME BACK',
                style: TextStyle(
                  fontSize: 36,
                  fontFamily: 'BebasNeue',
                  letterSpacing: 1,
                  height: 1.05,
                  color: AppPalette.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Sign in to restore your level, friends, and history.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppPalette.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              AuthField(
                controller: _emailCtrl,
                label: 'EMAIL',
                hint: 'kael@example.com',
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              AuthField(
                controller: _passwordCtrl,
                label: 'PASSWORD',
                hint: 'Your password',
                obscureText: _obscurePassword,
                trailing: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 18,
                    color: AppPalette.textMuted,
                  ),
                  onPressed: () => setState(
                    () => _obscurePassword = !_obscurePassword,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.go('/forgot-password'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppPalette.teal,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                AuthErrorBanner(message: _error!),
              ],
              const Spacer(),
              PrimaryAuthButton(
                label: 'SIGN IN',
                enabled: _canSubmit,
                loading: _loading,
                onTap: _submit,
              ),
              const SizedBox(height: 14),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/signup'),
                  child: const Text(
                    "Don't have an account?  Create one",
                    style: TextStyle(
                      fontSize: 13,
                      color: AppPalette.textMuted,
                      letterSpacing: 0.3,
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
