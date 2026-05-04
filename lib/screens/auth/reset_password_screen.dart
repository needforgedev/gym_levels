import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/services/auth_service.dart';
import '../../theme/tokens.dart';
import '../../widgets/screen_base.dart';
import 'auth_widgets.dart';

/// Reset Password — landing screen for the deep link inside the
/// password-reset email. Supabase's recovery token gets parsed by the
/// SDK before this screen mounts; the user arrives already in a
/// recovery-mode session, ready to set a new password.
///
/// Form: new password + confirm. On submit, calls `updatePassword` on
/// the recovery session, then signs the user out and routes to Sign In
/// so they confirm the new credentials before re-entering the app.
///
/// Note: deep-link wiring (URL scheme `levelupirl://reset-password`)
/// must be configured on iOS (Info.plist `CFBundleURLSchemes`) and
/// Android (`AndroidManifest.xml` intent-filter) for this to actually
/// be reachable from the email link. Without that, the user can land
/// here only via direct navigation.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  bool get _passwordValid => _passwordCtrl.text.length >= 8;

  bool get _matches =>
      _passwordCtrl.text.isNotEmpty &&
      _passwordCtrl.text == _confirmCtrl.text;

  bool get _canSubmit => _passwordValid && _matches && !_loading;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await AuthService.updatePassword(_passwordCtrl.text);
    if (!mounted) return;
    if (result.ok) {
      // Sign the user out so they have to re-enter their new password
      // (confirms it works + standard security pattern after reset).
      await AuthService.signOut();
      if (!mounted) return;
      context.go('/signin');
    } else {
      setState(() {
        _loading = false;
        _error = result.errorMessage;
      });
    }
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
                'NEW PASSWORD',
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
                'Choose a new password. You\'ll sign in with it next time.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppPalette.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              AuthField(
                controller: _passwordCtrl,
                label: 'NEW PASSWORD',
                hint: 'At least 8 characters',
                obscureText: _obscure,
                trailing: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 18,
                    color: AppPalette.textMuted,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              PasswordStrength(password: _passwordCtrl.text),
              const SizedBox(height: 16),
              AuthField(
                controller: _confirmCtrl,
                label: 'CONFIRM PASSWORD',
                hint: 'Re-enter the same password',
                obscureText: _obscure,
                onChanged: (_) => setState(() {}),
              ),
              if (_confirmCtrl.text.isNotEmpty && !_matches) ...[
                const SizedBox(height: 8),
                Text(
                  "Passwords don't match.",
                  style: TextStyle(
                    fontSize: 11,
                    color: AppPalette.danger,
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                AuthErrorBanner(message: _error!),
              ],
              const Spacer(),
              PrimaryAuthButton(
                label: 'UPDATE PASSWORD',
                enabled: _canSubmit,
                loading: _loading,
                onTap: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
