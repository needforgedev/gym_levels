import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/services/auth_service.dart';
import '../../theme/tokens.dart';
import '../../widgets/screen_base.dart';
import 'auth_widgets.dart';

/// Sign Up — first auth-requiring screen the user hits after the hype
/// slides. Email + password + a checkbox for the terms of service.
/// Routes to `/verify-email` on success.
///
/// Has an "Already have an account? Sign in" link to `/signin` for
/// users on a new device whose account already exists.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _termsAccepted = false;
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

  bool get _passwordValid => _passwordCtrl.text.length >= 8;

  bool get _canSubmit =>
      _emailValid && _passwordValid && _termsAccepted && !_loading;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await AuthService.signUp(
      email: _emailCtrl.text,
      password: _passwordCtrl.text,
    );
    if (!mounted) return;
    if (result.ok) {
      // If "Confirm email" is OFF in the Supabase project, the user is
      // already verified at signup time — skip the verify-email screen
      // and go straight into the local-onboarding chain. With "Confirm
      // email" ON (recommended pre-launch), the user must verify before
      // we let them past `/verify-email`.
      if (AuthService.isEmailVerified) {
        context.go('/register');
      } else {
        context.go('/verify-email');
      }
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
                child: AuthBackChip(onTap: () => context.go('/hype/ranks')),
              ),
              const SizedBox(height: 24),
              const Text(
                'CREATE ACCOUNT',
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
                'Friends, leaderboards, cloud backup. Always opt-in.',
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
                hint: 'At least 8 characters',
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
              const SizedBox(height: 8),
              PasswordStrength(password: _passwordCtrl.text),
              const SizedBox(height: 18),
              TermsCheckbox(
                accepted: _termsAccepted,
                onChanged: (v) => setState(() => _termsAccepted = v),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                AuthErrorBanner(message: _error!),
              ],
              const Spacer(),
              PrimaryAuthButton(
                label: 'CREATE ACCOUNT',
                enabled: _canSubmit,
                loading: _loading,
                onTap: _submit,
              ),
              const SizedBox(height: 14),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/signin'),
                  child: const Text(
                    'Already have an account?  Sign in',
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
