import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/services/public_profile_service.dart';
import '../../state/player_state.dart';
import '../../theme/tokens.dart';
import '../../widgets/screen_base.dart';
import 'auth_widgets.dart';

/// Pick Username — second-to-last cloud-account screen before the user
/// dives into the local onboarding chain. Hits between `/register`
/// (display name → local sqflite) and `/phone` (phone for contact
/// match → cloud).
///
/// Live availability check via `check_username_available` RPC. Format
/// rule: 3-20 chars, lowercase letters, digits, underscore. Reserved
/// words rejected server-side.
///
/// On submit: UPSERTs the user's `public_profiles` row with username +
/// display_name (read from local PlayerState — set by /register).
class UsernameScreen extends StatefulWidget {
  const UsernameScreen({super.key});

  @override
  State<UsernameScreen> createState() => _UsernameScreenState();
}

enum _Status { idle, invalid, checking, available, taken, reserved, error }

class _UsernameScreenState extends State<UsernameScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  _Status _status = _Status.idle;
  String? _error;
  bool _submitting = false;

  static final _formatRegex = RegExp(r'^[a-z0-9_]{3,20}$');

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    setState(() {
      _error = null;
      if (value.isEmpty) {
        _status = _Status.idle;
        return;
      }
      if (!_formatRegex.hasMatch(value)) {
        _status = _Status.invalid;
        return;
      }
      _status = _Status.checking;
    });
    if (_status != _Status.checking) return;
    _debounce = Timer(const Duration(milliseconds: 320), _runCheck);
  }

  Future<void> _runCheck() async {
    final candidate = _controller.text.trim().toLowerCase();
    if (!_formatRegex.hasMatch(candidate)) return;
    final result = await PublicProfileService.checkUsernameAvailable(candidate);
    if (!mounted) return;
    setState(() {
      if (result.available) {
        _status = _Status.available;
      } else {
        switch (result.reason) {
          case 'taken':
            _status = _Status.taken;
            break;
          case 'reserved':
            _status = _Status.reserved;
            break;
          case 'invalid_format':
            _status = _Status.invalid;
            break;
          default:
            _status = _Status.error;
            _error = result.reason;
        }
      }
    });
  }

  Future<void> _submit() async {
    if (_status != _Status.available || _submitting) return;
    final username = _controller.text.trim().toLowerCase();
    final displayName =
        context.read<PlayerState>().player?.displayName ?? username;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final result = await PublicProfileService.upsertProfile(
      username: username,
      displayName: displayName,
    );
    if (!mounted) return;
    if (result.ok) {
      context.go('/phone');
    } else {
      setState(() {
        _submitting = false;
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
                child: AuthBackChip(onTap: () => context.go('/register')),
              ),
              const SizedBox(height: 24),
              const Text(
                'PICK A HANDLE',
                style: TextStyle(
                  fontSize: 36,
                  fontFamily: 'BebasNeue',
                  letterSpacing: 1,
                  height: 1.05,
                  color: AppPalette.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Friends will find you by this handle. Lowercase letters, "
                "digits, and underscores only.",
                style: TextStyle(
                  fontSize: 13,
                  color: AppPalette.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              _UsernameField(
                controller: _controller,
                onChanged: _onChanged,
                trailing: _StatusIcon(status: _status),
              ),
              const SizedBox(height: 8),
              _StatusLabel(status: _status),
              if (_error != null) ...[
                const SizedBox(height: 12),
                AuthErrorBanner(message: _error!),
              ],
              const Spacer(),
              PrimaryAuthButton(
                label: 'CLAIM HANDLE',
                enabled: _status == _Status.available && !_submitting,
                loading: _submitting,
                onTap: _submit,
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'You can change this later, but only once every 30 days.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppPalette.textMuted.withValues(alpha: 0.7),
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

class _UsernameField extends StatelessWidget {
  const _UsernameField({
    required this.controller,
    required this.onChanged,
    required this.trailing,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'HANDLE',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: AppPalette.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: TextInputType.text,
          textCapitalization: TextCapitalization.none,
          autocorrect: false,
          enableSuggestions: false,
          maxLength: 20,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9_]')),
            LengthLimitingTextInputFormatter(20),
          ],
          style: const TextStyle(
            fontSize: 17,
            color: AppPalette.textPrimary,
            fontFamily: 'JetBrainsMono',
          ),
          decoration: InputDecoration(
            hintText: 'kael_irl',
            hintStyle: TextStyle(
              fontSize: 17,
              fontFamily: 'JetBrainsMono',
              color: AppPalette.textMuted.withValues(alpha: 0.5),
            ),
            counterText: '',
            prefixText: '@ ',
            prefixStyle: const TextStyle(
              fontSize: 17,
              fontFamily: 'JetBrainsMono',
              fontWeight: FontWeight.w700,
              color: AppPalette.purpleSoft,
            ),
            suffixIcon: trailing,
            filled: true,
            fillColor: AppPalette.purple.withValues(alpha: 0.08),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
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

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status});
  final _Status status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case _Status.checking:
        return const Padding(
          padding: EdgeInsets.all(14),
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppPalette.purpleSoft,
            ),
          ),
        );
      case _Status.available:
        return const Icon(
          Icons.check_circle,
          color: AppPalette.success,
          size: 22,
        );
      case _Status.taken:
      case _Status.reserved:
      case _Status.invalid:
      case _Status.error:
        return const Icon(
          Icons.cancel,
          color: AppPalette.danger,
          size: 22,
        );
      case _Status.idle:
        return const SizedBox.shrink();
    }
  }
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.status});
  final _Status status;

  @override
  Widget build(BuildContext context) {
    final (text, color) = switch (status) {
      _Status.idle => (
          'At least 3 characters.',
          AppPalette.textMuted,
        ),
      _Status.checking => ('Checking…', AppPalette.textMuted),
      _Status.available => ('Available!', AppPalette.success),
      _Status.taken => ('Already taken.', AppPalette.danger),
      _Status.reserved => ('Reserved — pick another.', AppPalette.danger),
      _Status.invalid => (
          'Lowercase letters, digits, and _ only. 3-20 characters.',
          AppPalette.danger,
        ),
      _Status.error => ('Could not check. Try again.', AppPalette.danger),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
