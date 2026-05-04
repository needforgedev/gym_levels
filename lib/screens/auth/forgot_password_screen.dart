import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/services/auth_service.dart';
import '../../theme/tokens.dart';
import '../../widgets/screen_base.dart';
import 'auth_widgets.dart';

/// Forgot Password — entry-point from the Sign In screen. Collects the
/// user's email, fires Supabase's `resetPasswordForEmail`, and shows a
/// "check your inbox" success state. The actual new-password form lives
/// in [ResetPasswordScreen] which is the deep-link target for the link
/// inside the recovery email.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  bool get _emailValid {
    final v = _emailCtrl.text.trim();
    return v.contains('@') && v.contains('.') && v.length >= 5;
  }

  Future<void> _submit() async {
    if (!_emailValid || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await AuthService.sendPasswordReset(_emailCtrl.text);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.ok) {
        _sent = true;
      } else {
        _error = result.errorMessage;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Shrinks the form's vertical area by the keyboard height when
    // open so Spacer compresses and the CTA rides above the keyboard.
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    return ScreenBase(
      background: AppPalette.voidBg,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(28, 16, 28, 24 + keyboardInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: AuthBackChip(onTap: () => context.go('/signin')),
              ),
              const SizedBox(height: 24),
              const Text(
                'RESET PASSWORD',
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
                _sent
                    ? "Open your inbox and tap the link to choose a new password."
                    : "Enter the email on your account. We'll send you a reset link.",
                style: const TextStyle(
                  fontSize: 13,
                  color: AppPalette.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              if (!_sent) ...[
                AuthField(
                  controller: _emailCtrl,
                  label: 'EMAIL',
                  hint: 'kael@example.com',
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) => setState(() {}),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  AuthErrorBanner(message: _error!),
                ],
                const Spacer(),
                PrimaryAuthButton(
                  label: 'SEND RESET LINK',
                  enabled: _emailValid && !_loading,
                  loading: _loading,
                  onTap: _submit,
                ),
              ] else ...[
                AuthSuccessBanner(
                  message:
                      'Sent. Check spam too if it doesn\'t arrive in a minute.',
                ),
                const Spacer(),
                PrimaryAuthButton(
                  label: 'BACK TO SIGN IN',
                  enabled: true,
                  loading: false,
                  onTap: () => context.go('/signin'),
                ),
              ],
              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }
}
