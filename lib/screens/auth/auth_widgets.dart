import 'package:flutter/material.dart';

import '../../theme/tokens.dart';

/// Shared building blocks for the auth screens (Sign Up, Sign In,
/// Verify Email, Forgot Password, Reset Password). All visual primitives
/// — no business logic. Keeping them here so every auth screen has a
/// consistent look without duplicating widget code.

class AuthBackChip extends StatelessWidget {
  const AuthBackChip({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppPalette.purple.withValues(alpha: 0.12),
            border: Border.all(
              color: AppPalette.purple.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: const Icon(
            Icons.chevron_left,
            size: 20,
            color: AppPalette.textPrimary,
          ),
        ),
      ),
    );
  }
}

class AuthField extends StatelessWidget {
  const AuthField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.trailing,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? trailing;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: AppPalette.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          autocorrect: false,
          enableSuggestions: false,
          onChanged: onChanged,
          style: const TextStyle(
            fontSize: 15,
            color: AppPalette.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 14,
              color: AppPalette.textMuted.withValues(alpha: 0.6),
            ),
            filled: true,
            fillColor: AppPalette.purple.withValues(alpha: 0.08),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            suffixIcon: trailing,
            border: _border(0.25),
            enabledBorder: _border(0.25),
            focusedBorder: _border(0.55),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _border(double alpha) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppPalette.purple.withValues(alpha: alpha),
          width: 1,
        ),
      );
}

class PasswordStrength extends StatelessWidget {
  const PasswordStrength({super.key, required this.password});
  final String password;

  int get _score {
    var s = 0;
    if (password.length >= 8) s++;
    if (password.length >= 12) s++;
    if (RegExp(r'[A-Z]').hasMatch(password)) s++;
    if (RegExp(r'[0-9]').hasMatch(password)) s++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) s++;
    return s;
  }

  String get _label {
    if (password.isEmpty) return '';
    if (_score <= 1) return 'WEAK';
    if (_score <= 3) return 'OK';
    return 'STRONG';
  }

  Color get _color {
    if (_score <= 1) return AppPalette.danger;
    if (_score <= 3) return AppPalette.amber;
    return AppPalette.success;
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox(height: 8);
    final filledSegs = _score.clamp(0, 5);
    return Row(
      children: [
        for (var i = 0; i < 5; i++) ...[
          Expanded(
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: i < filledSegs
                    ? _color
                    : AppPalette.purple.withValues(alpha: 0.12),
              ),
            ),
          ),
          if (i < 4) const SizedBox(width: 4),
        ],
        const SizedBox(width: 10),
        Text(
          _label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: _color,
          ),
        ),
      ],
    );
  }
}

class TermsCheckbox extends StatelessWidget {
  const TermsCheckbox({
    super.key,
    required this.accepted,
    required this.onChanged,
  });
  final bool accepted;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!accepted),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: accepted
                    ? AppPalette.amber.withValues(alpha: 0.25)
                    : Colors.transparent,
                border: Border.all(
                  color: accepted
                      ? AppPalette.amber
                      : AppPalette.purple.withValues(alpha: 0.40),
                  width: 1.5,
                ),
              ),
              child: accepted
                  ? const Icon(
                      Icons.check,
                      size: 14,
                      color: AppPalette.amber,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text.rich(
                TextSpan(
                  style: TextStyle(
                    fontSize: 12,
                    color: AppPalette.textMuted,
                    height: 1.4,
                  ),
                  children: [
                    TextSpan(text: 'I agree to the '),
                    TextSpan(
                      text: 'Terms of Service',
                      style: TextStyle(
                        color: AppPalette.teal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: TextStyle(
                        color: AppPalette.teal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(text: '.'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: AppPalette.danger.withValues(alpha: 0.10),
        border: Border.all(
          color: AppPalette.danger.withValues(alpha: 0.40),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            size: 16,
            color: AppPalette.danger,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                color: AppPalette.danger,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthSuccessBanner extends StatelessWidget {
  const AuthSuccessBanner({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: AppPalette.success.withValues(alpha: 0.10),
        border: Border.all(
          color: AppPalette.success.withValues(alpha: 0.40),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 16,
            color: AppPalette.success,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                color: AppPalette.success,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PrimaryAuthButton extends StatelessWidget {
  const PrimaryAuthButton({
    super.key,
    required this.label,
    required this.enabled,
    required this.loading,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: enabled
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppPalette.amber, AppPalette.amberSoft],
                  )
                : null,
            color: enabled
                ? null
                : AppPalette.amber.withValues(alpha: 0.18),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: AppPalette.amber.withValues(alpha: 0.45),
                      blurRadius: 18,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppPalette.voidBg,
                    ),
                  )
                : Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: enabled
                          ? AppPalette.voidBg
                          : AppPalette.textMuted,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class SecondaryAuthButton extends StatelessWidget {
  const SecondaryAuthButton({
    super.key,
    required this.label,
    required this.onTap,
  });
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: AppPalette.purple.withValues(alpha: 0.12),
            border: Border.all(
              color: AppPalette.purple.withValues(alpha: 0.30),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: AppPalette.purpleSoft,
            ),
          ),
        ),
      ),
    );
  }
}
