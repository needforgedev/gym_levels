import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../state/player_state.dart';
import '../theme/tokens.dart';
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
    // Socials S2 — collect cloud handle + phone before continuing into
    // the local-only onboarding (`/age`, `/height`, …).
    context.go('/username');
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      section: OnboardingSection.registration,
      percent: 10,
      subtitle: 'Scanning biological signature…',
      title: 'What shall the System call you, Player?',
      nextEnabled: _valid,
      onBack: () => context.go('/hype/progression'),
      onNext: _onSubmit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _NameField(
            controller: _ctl,
            focusNode: _focus,
            onChanged: (v) => setState(() => _value = v),
            onSubmitted: (_) => _onSubmit(),
          ),
          const SizedBox(height: AppSpace.s4),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: AppPalette.purple.withValues(alpha: 0.06),
              border: Border.all(
                color: AppPalette.purple.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '[SYS NOTE]',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppPalette.amber,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'JetBrainsMono',
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Your codename appears on the leaderboard, in notifications, and on your Player profile.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppPalette.textMuted,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          // Counter is now inline inside the input. Hint stays below.
          if (_value.isNotEmpty && !_valid) ...[
            const SizedBox(height: AppSpace.s3),
            Text(
              _hintFor(_value),
              style: AppType.system(color: AppPalette.danger),
            ),
          ],
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
      height: 60,
      decoration: BoxDecoration(
        color: AppPalette.purple.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _focused
              ? AppPalette.amber.withValues(alpha: 0.55)
              : AppPalette.purple.withValues(alpha: 0.40),
          width: 1.5,
        ),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: AppPalette.amber.withValues(alpha: 0.30),
                  blurRadius: 16,
                  spreadRadius: -4,
                ),
              ]
            : const [],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 56, 0),
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
                maxLength: 20,
                textInputAction: TextInputAction.done,
                textCapitalization: TextCapitalization.words,
                cursorColor: AppPalette.amber,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.textPrimary,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'[\n\t]')),
                ],
                decoration: InputDecoration(
                  hintText: 'Enter codename',
                  hintStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: AppPalette.textMuted,
                  ),
                  border: InputBorder.none,
                  isCollapsed: true,
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            // Inline character counter pinned to the right edge.
            Positioned(
              right: 16,
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: widget.controller,
                builder: (ctx, value, _) => Text(
                  '${value.text.length}/20',
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'JetBrainsMono',
                    color: AppPalette.textDim,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
