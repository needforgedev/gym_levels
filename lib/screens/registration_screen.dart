import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../state/player_state.dart';
import '../theme/tokens.dart';
import '../widgets/neon_card.dart';
import '../widgets/onboarding_scaffold.dart';
import '../widgets/progress_header.dart';

/// PRD §8 Section 1 — Player Registration screen 3.
/// "What shall the System call you, Player?"
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  late final TextEditingController _ctl;
  late final FocusNode _focus;
  String _value = '';

  @override
  void initState() {
    super.initState();
    final player = context.read<PlayerState>().player;
    _value = player?.displayName ?? '';
    _ctl = TextEditingController(text: _value);
    _focus = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _ctl.dispose();
    _focus.dispose();
    super.dispose();
  }

  bool get _valid => _value.trim().length >= 2 && _value.trim().length <= 20;

  Future<void> _onSubmit() async {
    if (!_valid) return;
    await context.read<PlayerState>().setDisplayName(_value.trim());
    if (!mounted) return;
    context.go('/age');
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      section: OnboardingSection.registration,
      percent: 10,
      kicker: 'PLAYER REGISTRATION',
      subtitle: '…assigning callsign to new recruit.',
      nextEnabled: _valid,
      onBack: () => context.go('/hype/progression'),
      onNext: _onSubmit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NeonCard(
            glow: GlowColor.teal,
            padding: const EdgeInsets.all(AppSpace.s6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What shall the\nSystem call you,\nPlayer?',
                  style: AppType.displayLG(color: AppPalette.textPrimary),
                ),
                const SizedBox(height: AppSpace.s3),
                Text(
                  'THIS IS YOUR DISPLAY NAME. 2–20 CHARACTERS.',
                  style: AppType.bodySM(color: AppPalette.textMuted),
                ),
                const SizedBox(height: AppSpace.s6),
                _NameField(
                  controller: _ctl,
                  focusNode: _focus,
                  onChanged: (v) => setState(() => _value = v),
                  onSubmitted: (_) => _onSubmit(),
                ),
                const SizedBox(height: AppSpace.s3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _hintFor(_value),
                      style: AppType.system(
                        color: _valid || _value.isEmpty
                            ? AppPalette.textMuted
                            : AppPalette.danger,
                      ),
                    ),
                    Text(
                      '${_value.length} / 20',
                      style: AppType.monoMD(color: AppPalette.textMuted)
                          .copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.s4),
          NeonCard(
            glow: GlowColor.none,
            padding: const EdgeInsets.all(AppSpace.s4),
            pulse: false,
            child: Text(
              '> identity packet will be bound to local player profile.',
              style: AppType.system(color: AppPalette.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  String _hintFor(String v) {
    final t = v.trim();
    if (t.isEmpty) return '…awaiting input.';
    if (t.length < 2) return '⚠ minimum 2 characters.';
    if (t.length > 20) return '⚠ maximum 20 characters.';
    return '…callsign accepted.';
  }
}

class _NameField extends StatefulWidget {
  const _NameField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  State<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends State<_NameField> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocus);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocus);
    super.dispose();
  }

  void _onFocus() {
    if (mounted) setState(() => _focused = widget.focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 56,
      decoration: BoxDecoration(
        color: AppPalette.slate,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: _focused ? AppPalette.teal : AppPalette.strokeSubtle,
          width: 1,
        ),
        boxShadow: _focused
            ? AppGlow.shadow(GlowColor.teal, intensity: 0.8, alpha: 0.4)
            : const [],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                '>',
                style: AppType.monoLG(color: AppPalette.teal).copyWith(
                  fontSize: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  maxLength: 20,
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.words,
                  cursorColor: AppPalette.teal,
                  style: AppType.bodyLG(color: AppPalette.textPrimary),
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp(r'[\n\t]')),
                  ],
                  decoration: InputDecoration(
                    hintText: 'ENTER NAME…',
                    hintStyle: AppType.bodyLG(color: AppPalette.textMuted),
                    border: InputBorder.none,
                    isCollapsed: true,
                    counterText: '',
                    contentPadding: EdgeInsets.zero,
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
