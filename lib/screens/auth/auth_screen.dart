import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/services/auth_service.dart';
import '../../data/services/public_profile_service.dart';
import '../../data/supabase/phone_hasher.dart';
import '../../data/sync/initial_sync.dart';
import '../../state/player_state.dart';
import '../../theme/tokens.dart';
import '../../widgets/screen_base.dart';
import 'auth_widgets.dart';

/// Combined Sign In / Join Now screen — replaces the separate
/// SignInScreen + SignUpScreen + UsernameScreen + PhoneScreen with a
/// single tabbed surface.
///
/// Form fields:
///   • Sign In: Email + Password.
///   • Join Now: Email + Hero Name (live username availability check) +
///     Phone Number (with country picker) + Password + Confirm
///     Password (+ strength meter) + Code of Grind & Privacy Pact.
///
/// On Join Now submit:
///   1. `AuthService.signUp(email, password)` — creates the auth user.
///   2. `PlayerService.setDisplayName(username)` — local name.
///   3. `PublicProfileService.upsertProfile(username, displayName,
///      phoneE164)` — cloud profile + phone hash for contact match.
///   4. Route to `/verify-email` (or straight to `/age` if Supabase
///      auto-verified).
///
/// On Sign In submit: `AuthService.signIn` → `/welcome-back` (first
/// device) or `/home` (returning).
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.initialMode = AuthMode.signIn});

  final AuthMode initialMode;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

enum AuthMode { signIn, signUp }

enum _UsernameStatus {
  idle,
  invalid,
  checking,
  available,
  taken,
  reserved,
  error
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late AuthMode _mode;
  late final AnimationController _shimmer;
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _showPw = false;
  bool _agree = false;
  bool _loading = false;
  String? _error;

  // Username live-availability check state.
  Timer? _usernameDebounce;
  _UsernameStatus _usernameStatus = _UsernameStatus.idle;
  String? _usernameRpcError;
  static final _usernameRegex = RegExp(r'^[a-z0-9_]{3,20}$');

  // Phone country.
  static const _defaultCountry = _Country('🇮🇳', 'India', '+91', 10);
  _Country _country = _defaultCountry;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _emailCtrl.addListener(() => setState(() {}));
    _passwordCtrl.addListener(() => setState(() {}));
    _confirmCtrl.addListener(() => setState(() {}));
    _phoneCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _shimmer.dispose();
    _usernameDebounce?.cancel();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _usernameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  bool get _isSignUp => _mode == AuthMode.signUp;

  bool get _emailValid {
    final v = _emailCtrl.text.trim();
    return v.contains('@') && v.contains('.') && v.length >= 5;
  }

  bool get _passwordValid => _passwordCtrl.text.length >= 8;

  bool get _confirmValid =>
      !_isSignUp || _confirmCtrl.text == _passwordCtrl.text;

  bool get _phoneValid {
    final digits = _phoneCtrl.text;
    if (digits.length < 7 || digits.length > 15) return false;
    return RegExp(r'^[0-9]{7,15}$').hasMatch(digits);
  }

  String? get _phoneE164 {
    if (!_phoneValid) return null;
    return PhoneHasher.normalizeToE164('${_country.dial}${_phoneCtrl.text}');
  }

  bool get _canSubmit {
    if (_loading) return false;
    if (!_emailValid || !_passwordValid) return false;
    if (_isSignUp) {
      if (!_confirmValid || !_agree) return false;
      if (_usernameStatus != _UsernameStatus.available) return false;
      if (!_phoneValid) return false;
    }
    return true;
  }

  void _switchMode(AuthMode m) {
    if (_mode == m) return;
    setState(() {
      _mode = m;
      _error = null;
    });
  }

  // ─── Username availability ────────────────────────────────────

  void _onUsernameChanged(String value) {
    _usernameDebounce?.cancel();
    setState(() {
      _usernameRpcError = null;
      if (value.isEmpty) {
        _usernameStatus = _UsernameStatus.idle;
        return;
      }
      if (!_usernameRegex.hasMatch(value)) {
        _usernameStatus = _UsernameStatus.invalid;
        return;
      }
      _usernameStatus = _UsernameStatus.checking;
    });
    if (_usernameStatus != _UsernameStatus.checking) return;
    _usernameDebounce =
        Timer(const Duration(milliseconds: 320), _runUsernameCheck);
  }

  Future<void> _runUsernameCheck() async {
    final candidate = _usernameCtrl.text.trim().toLowerCase();
    if (!_usernameRegex.hasMatch(candidate)) return;
    final result = await PublicProfileService.checkUsernameAvailable(candidate);
    if (!mounted) return;
    setState(() {
      if (result.available) {
        _usernameStatus = _UsernameStatus.available;
      } else {
        switch (result.reason) {
          case 'taken':
            _usernameStatus = _UsernameStatus.taken;
            break;
          case 'reserved':
            _usernameStatus = _UsernameStatus.reserved;
            break;
          case 'invalid_format':
            _usernameStatus = _UsernameStatus.invalid;
            break;
          default:
            _usernameStatus = _UsernameStatus.error;
            _usernameRpcError = result.reason;
        }
      }
    });
  }

  // ─── Country picker ───────────────────────────────────────────

  Future<void> _openCountryPicker() async {
    final picked = await showModalBottomSheet<_Country>(
      context: context,
      backgroundColor: AppPalette.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _CountryPickerSheet(),
    );
    if (picked != null && mounted) {
      setState(() {
        _country = picked;
        _phoneCtrl.clear();
      });
    }
  }

  // ─── Submit ───────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    if (_isSignUp) {
      // 1. Create the auth account.
      final signUp = await AuthService.signUp(
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
      );
      if (!mounted) return;
      if (!signUp.ok) {
        setState(() {
          _loading = false;
          _error = signUp.errorMessage;
        });
        return;
      }

      // 2. Save the username locally as the player's display name.
      final username = _usernameCtrl.text.trim().toLowerCase();
      await context.read<PlayerState>().setDisplayName(username);

      // 3. Upsert the cloud profile in one shot — username + display
      // name + phone (E.164) + phone hash for contact match.
      final phoneE164 = _phoneE164;
      final upsert = await PublicProfileService.upsertProfile(
        username: username,
        displayName: username,
        phoneE164: phoneE164,
      );
      if (!mounted) return;
      if (!upsert.ok) {
        // Soft-fail — auth user is created; the user can retry the
        // profile push later (Settings → S7). Surface the error and
        // still let them proceed so they don't get stuck.
        setState(() => _error = upsert.errorMessage);
      }

      // 4. Route forward — verify-email gate first if required.
      if (AuthService.isEmailVerified) {
        context.go('/age');
      } else {
        context.go('/verify-email');
      }
    } else {
      final result = await AuthService.signIn(
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
      );
      if (!mounted) return;
      if (!result.ok) {
        setState(() {
          _loading = false;
          _error = result.errorMessage;
        });
        return;
      }
      final needsHydration = await InitialSync.needed();
      if (!mounted) return;
      context.go(needsHydration ? '/welcome-back' : '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenBase(
      background: AppPalette.voidBg,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            children: [
              _Hero(
                mode: _mode,
                onSwitchMode: _switchMode,
                onBack: () => context.go('/'),
              ),
              _TaglineBanner(shimmer: _shimmer),
              const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: _Form(
                  isSignUp: _isSignUp,
                  emailCtrl: _emailCtrl,
                  passwordCtrl: _passwordCtrl,
                  confirmCtrl: _confirmCtrl,
                  usernameCtrl: _usernameCtrl,
                  phoneCtrl: _phoneCtrl,
                  showPw: _showPw,
                  onTogglePw: () => setState(() => _showPw = !_showPw),
                  agree: _agree,
                  onToggleAgree: () => setState(() => _agree = !_agree),
                  error: _error,
                  loading: _loading,
                  canSubmit: _canSubmit,
                  onSubmit: _submit,
                  shimmer: _shimmer,
                  confirmValid: _confirmValid,
                  usernameStatus: _usernameStatus,
                  usernameError: _usernameRpcError,
                  onUsernameChanged: _onUsernameChanged,
                  country: _country,
                  onOpenCountryPicker: _openCountryPicker,
                ),
              ),
              const SizedBox(height: 18),
              if (!_isSignUp)
                _SwitchAccountFooter(
                  onForgot: () => context.go('/forgot-password'),
                  onJoin: () => _switchMode(AuthMode.signUp),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Hero strip ──────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  const _Hero({
    required this.mode,
    required this.onSwitchMode,
    required this.onBack,
  });
  final AuthMode mode;
  final ValueChanged<AuthMode> onSwitchMode;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return SizedBox(
      height: 360 + topInset,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -10,
            top: 0,
            width: 320,
            height: 360 + topInset,
            child: Opacity(
              opacity: 0.95,
              child: Image.asset(
                'assets/hero-character.png',
                fit: BoxFit.cover,
                alignment: Alignment.topRight,
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.6, -0.4),
                    radius: 1.0,
                    colors: [
                      AppPalette.amber.withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                    stops: const [0, 0.55],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      AppPalette.voidBg,
                      AppPalette.voidBg.withValues(alpha: 0.4),
                      Colors.transparent,
                    ],
                    stops: const [0, 0.45, 0.7],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      AppPalette.voidBg,
                    ],
                    stops: const [0, 0.6, 1.0],
                  ),
                ),
              ),
            ),
          ),
          const Positioned.fill(child: _Sparkles()),
          Positioned(
            top: topInset + 12,
            left: 16,
            child: AuthBackChip(onTap: onBack),
          ),
          Positioned(
            top: topInset + 60,
            left: 16,
            right: 16,
            child: _ModeToggle(mode: mode, onChange: onSwitchMode),
          ),
          Positioned(
            left: 22,
            bottom: 78,
            right: 140,
            child: const _Headline(),
          ),
        ],
      ),
    );
  }
}

class _Sparkles extends StatefulWidget {
  const _Sparkles();
  @override
  State<_Sparkles> createState() => _SparklesState();
}

class _SparklesState extends State<_Sparkles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;
  late final List<_Spark> _sparks;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    final rng = math.Random(7);
    _sparks = List.generate(10, (i) {
      return _Spark(
        leftFrac: 0.10 + ((i * 31) % 80) / 100,
        topFrac: 0.20 + ((i * 17) % 60) / 100,
        size: 2.0 + (i % 3),
        amber: i % 3 == 0,
        delay: rng.nextDouble() * 2.5,
        period: 2 + rng.nextInt(3).toDouble(),
      );
    });
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctl,
        builder: (_, _) => CustomPaint(
          painter: _SparklesPainter(_sparks, _ctl.value * 3),
        ),
      ),
    );
  }
}

class _Spark {
  const _Spark({
    required this.leftFrac,
    required this.topFrac,
    required this.size,
    required this.amber,
    required this.period,
    required this.delay,
  });
  final double leftFrac;
  final double topFrac;
  final double size;
  final bool amber;
  final double period;
  final double delay;
}

class _SparklesPainter extends CustomPainter {
  _SparklesPainter(this.sparks, this.time);
  final List<_Spark> sparks;
  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in sparks) {
      final phase = (time - s.delay) % s.period;
      final t = phase / s.period;
      final pulse = 1 - (t - 0.5).abs() * 2;
      final opacity = (0.3 + 0.7 * pulse).clamp(0.0, 1.0);
      final scale = 0.8 + 0.4 * pulse;
      final color = s.amber ? AppPalette.amber : const Color(0xFFC4B5FD);
      final cx = s.leftFrac * size.width;
      final cy = s.topFrac * size.height;
      final paint = Paint()
        ..color = color.withValues(alpha: 0.5 * opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s.size * 1.6);
      canvas.drawCircle(Offset(cx, cy), s.size * scale, paint);
      final core = Paint()..color = color.withValues(alpha: opacity);
      canvas.drawCircle(Offset(cx, cy), s.size * scale * 0.7, core);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklesPainter old) => true;
}

// ─── Mode toggle (sliding pill) ──────────────────────────────────

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.onChange});
  final AuthMode mode;
  final ValueChanged<AuthMode> onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppPalette.voidBg.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppPalette.purple.withValues(alpha: 0.30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (_, constraints) {
          final pillWidth = (constraints.maxWidth - 8) / 2;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 280),
                curve: const Cubic(0.2, 0.9, 0.3, 1),
                left: mode == AuthMode.signUp ? pillWidth : 0,
                top: 0,
                bottom: 0,
                width: pillWidth,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(11),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppPalette.purple.withValues(alpha: 0.45),
                        AppPalette.purpleDeep.withValues(alpha: 0.55),
                      ],
                    ),
                    border: Border.all(
                      color: AppPalette.purpleSoft.withValues(alpha: 0.65),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppPalette.purple.withValues(alpha: 0.7),
                        blurRadius: 18,
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _ToggleLabel(
                      label: 'Sign In',
                      active: mode == AuthMode.signIn,
                      onTap: () => onChange(AuthMode.signIn),
                    ),
                  ),
                  Expanded(
                    child: _ToggleLabel(
                      label: 'Join Now',
                      active: mode == AuthMode.signUp,
                      onTap: () => onChange(AuthMode.signUp),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ToggleLabel extends StatelessWidget {
  const _ToggleLabel({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: active ? Colors.white : AppPalette.textMuted,
            shadows: active
                ? [
                    Shadow(
                      color: AppPalette.purpleSoft.withValues(alpha: 0.6),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }
}

// ─── Headline ────────────────────────────────────────────────────

class _Headline extends StatelessWidget {
  const _Headline();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.workspace_premium_outlined,
              size: 14,
              color: AppPalette.amber,
            ),
            const SizedBox(width: 6),
            Text(
              'TRAIN. EARN. LEVEL UP.',
              style: TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 10,
                letterSpacing: 2.4,
                fontWeight: FontWeight.w800,
                color: AppPalette.amber,
                shadows: [
                  Shadow(
                    color: AppPalette.amber.withValues(alpha: 0.5),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ShaderMask(
          shaderCallback: (rect) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppPalette.textPrimary, Color(0xFFC4B5FD)],
          ).createShader(rect),
          child: Text(
            'STRONGER',
            style: AppType.displayLG(color: Colors.white).copyWith(
              fontSize: 40,
              height: 0.92,
              letterSpacing: 1,
            ),
          ),
        ),
        Text(
          'EVERY DAY',
          style: AppType.displayLG(color: AppPalette.amber).copyWith(
            fontSize: 40,
            height: 0.92,
            letterSpacing: 1,
            shadows: [
              Shadow(
                color: AppPalette.amber.withValues(alpha: 0.55),
                blurRadius: 24,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFFC4B5FD),
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
            children: [
              const TextSpan(text: 'Your journey. Your rank.\n'),
              TextSpan(
                text: 'Your community.',
                style: TextStyle(color: AppPalette.purpleSoft),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Tagline banner ──────────────────────────────────────────────

class _TaglineBanner extends StatelessWidget {
  const _TaglineBanner({required this.shimmer});
  final Animation<double> shimmer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Transform.translate(
        offset: const Offset(0, -22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF1A0F2B).withValues(alpha: 0.95),
                const Color(0xFF120A1F).withValues(alpha: 0.95),
              ],
            ),
            border: Border.all(
              color: AppPalette.amber.withValues(alpha: 0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: AppPalette.amber.withValues(alpha: 0.4),
                blurRadius: 24,
                spreadRadius: -6,
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: SizedBox(
                  height: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppPalette.amber.withValues(alpha: 0.7),
                          Colors.transparent,
                        ],
                        stops: const [0.2, 0.5, 0.8],
                      ),
                    ),
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: shimmer,
                builder: (_, _) => Positioned.fill(
                  child: IgnorePointer(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Align(
                        alignment: Alignment(-1.5 + shimmer.value * 3, 0),
                        child: FractionallySizedBox(
                          widthFactor: 0.45,
                          heightFactor: 1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  AppPalette.amber.withValues(alpha: 0.12),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        center: Alignment(-0.4, -0.4),
                        colors: [
                          Color(0xFFFCD34D),
                          AppPalette.amber,
                          Color(0xFF8C5814),
                        ],
                        stops: [0, 0.55, 1.0],
                      ),
                      border: Border.all(
                        color: const Color(0xFFFCD34D),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppPalette.amber.withValues(alpha: 0.7),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.workspace_premium,
                      size: 18,
                      color: AppPalette.voidBg,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'NO CROWN WITHOUT',
                          style: AppType.displaySM(
                            color: AppPalette.textPrimary,
                          ).copyWith(
                            fontSize: 18,
                            height: 1,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'THE GRIND',
                          style: AppType.displayLG(
                            color: AppPalette.amber,
                          ).copyWith(
                            fontSize: 22,
                            height: 1,
                            letterSpacing: 2,
                            shadows: [
                              Shadow(
                                color: AppPalette.amber.withValues(alpha: 0.6),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Form ────────────────────────────────────────────────────────

class _Form extends StatelessWidget {
  const _Form({
    required this.isSignUp,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.confirmCtrl,
    required this.usernameCtrl,
    required this.phoneCtrl,
    required this.showPw,
    required this.onTogglePw,
    required this.agree,
    required this.onToggleAgree,
    required this.error,
    required this.loading,
    required this.canSubmit,
    required this.onSubmit,
    required this.shimmer,
    required this.confirmValid,
    required this.usernameStatus,
    required this.usernameError,
    required this.onUsernameChanged,
    required this.country,
    required this.onOpenCountryPicker,
  });

  final bool isSignUp;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final TextEditingController confirmCtrl;
  final TextEditingController usernameCtrl;
  final TextEditingController phoneCtrl;
  final bool showPw;
  final VoidCallback onTogglePw;
  final bool agree;
  final VoidCallback onToggleAgree;
  final String? error;
  final bool loading;
  final bool canSubmit;
  final VoidCallback onSubmit;
  final Animation<double> shimmer;
  final bool confirmValid;
  final _UsernameStatus usernameStatus;
  final String? usernameError;
  final ValueChanged<String> onUsernameChanged;
  final _Country country;
  final VoidCallback onOpenCountryPicker;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthField(
          controller: emailCtrl,
          label: 'EMAIL',
          hint: 'you@example.com',
          keyboardType: TextInputType.emailAddress,
        ),
        if (isSignUp) ...[
          const SizedBox(height: 14),
          _UsernameField(
            controller: usernameCtrl,
            status: usernameStatus,
            onChanged: onUsernameChanged,
          ),
          const SizedBox(height: 6),
          _UsernameStatusLabel(
            status: usernameStatus,
            rpcError: usernameError,
          ),
          const SizedBox(height: 14),
          _PhoneField(
            controller: phoneCtrl,
            country: country,
            onOpenCountryPicker: onOpenCountryPicker,
          ),
          const SizedBox(height: 8),
          const _PhoneHelperNote(),
        ],
        const SizedBox(height: 14),
        AuthField(
          controller: passwordCtrl,
          label: 'PASSWORD',
          hint: 'Enter your password',
          obscureText: !showPw,
          trailing: IconButton(
            onPressed: onTogglePw,
            icon: Icon(
              showPw
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: showPw ? AppPalette.amber : AppPalette.textDisabled,
              size: 18,
            ),
          ),
        ),
        if (isSignUp) ...[
          const SizedBox(height: 14),
          AuthField(
            controller: confirmCtrl,
            label: 'CONFIRM PASSWORD',
            hint: 'Repeat password',
            obscureText: !showPw,
          ),
          if (passwordCtrl.text.isNotEmpty) ...[
            const SizedBox(height: 10),
            _StrengthMeter(password: passwordCtrl.text),
          ],
          if (confirmCtrl.text.isNotEmpty && !confirmValid) ...[
            const SizedBox(height: 8),
            Text(
              'Passwords don\'t match',
              style: TextStyle(
                fontSize: 11,
                color: const Color(0xFFFF6B35),
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ],
          const SizedBox(height: 14),
          _CodeOfGrindCheckbox(
            checked: agree,
            onTap: onToggleAgree,
          ),
        ],
        if (error != null) ...[
          const SizedBox(height: 14),
          AuthErrorBanner(message: error!),
        ],
        const SizedBox(height: 18),
        _SubmitButton(
          label: isSignUp ? 'JOIN NOW' : 'SIGN IN',
          loading: loading,
          enabled: canSubmit,
          onTap: onSubmit,
          shimmer: shimmer,
        ),
      ],
    );
  }
}

class _StrengthMeter extends StatelessWidget {
  const _StrengthMeter({required this.password});
  final String password;

  int get _score {
    final l = password.length;
    if (l >= 12) return 4;
    if (l >= 8) return 3;
    if (l >= 6) return 2;
    if (l >= 3) return 1;
    return 0;
  }

  static const _colors = [
    Color(0xFFFF6B35),
    AppPalette.amber,
    AppPalette.purpleSoft,
    AppPalette.teal,
  ];

  @override
  Widget build(BuildContext context) {
    final s = _score;
    return Row(
      children: List.generate(4, (i) {
        final filled = i < s;
        final color = _colors[(s - 1).clamp(0, _colors.length - 1)];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < 3 ? 4 : 0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: filled
                    ? color
                    : AppPalette.purple.withValues(alpha: 0.15),
                boxShadow: filled
                    ? [
                        BoxShadow(
                          color: color,
                          blurRadius: 6,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _CodeOfGrindCheckbox extends StatelessWidget {
  const _CodeOfGrindCheckbox({required this.checked, required this.onTap});
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppPalette.bgCard.withValues(alpha: 0.5),
          border: Border.all(
            color: AppPalette.purple.withValues(alpha: 0.18),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 18,
              height: 18,
              margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                gradient: checked
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppPalette.amber, Color(0xFFFBBF24)],
                      )
                    : null,
                border: Border.all(
                  color: checked
                      ? AppPalette.amber
                      : AppPalette.purple.withValues(alpha: 0.4),
                ),
                boxShadow: checked
                    ? [
                        BoxShadow(
                          color: AppPalette.amber.withValues(alpha: 0.6),
                          blurRadius: 10,
                          spreadRadius: -2,
                        ),
                      ]
                    : null,
              ),
              child: checked
                  ? Icon(Icons.check, size: 12, color: AppPalette.voidBg)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 11,
                    color: AppPalette.textMuted,
                    height: 1.45,
                  ),
                  children: [
                    const TextSpan(text: 'I accept the '),
                    TextSpan(
                      text: 'Code of Grind',
                      style: TextStyle(
                        color: AppPalette.amber,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const TextSpan(text: ' & '),
                    TextSpan(
                      text: 'Privacy Pact',
                      style: TextStyle(
                        color: AppPalette.purpleSoft,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.label,
    required this.loading,
    required this.enabled,
    required this.onTap,
    required this.shimmer,
  });
  final String label;
  final bool loading;
  final bool enabled;
  final VoidCallback onTap;
  final Animation<double> shimmer;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(27),
        child: Container(
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(27),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF1A0F2B).withValues(alpha: 0.6),
                AppPalette.bgCard.withValues(alpha: 0.8),
              ],
            ),
            border: Border.all(
              color: enabled
                  ? AppPalette.amber
                  : AppPalette.amber.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: AppPalette.amber.withValues(alpha: 0.6),
                      blurRadius: 24,
                      spreadRadius: -4,
                    ),
                  ]
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (enabled)
                AnimatedBuilder(
                  animation: shimmer,
                  builder: (_, _) => Positioned.fill(
                    child: IgnorePointer(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(27),
                        child: Align(
                          alignment: Alignment(-1.5 + shimmer.value * 3, 0),
                          child: FractionallySizedBox(
                            widthFactor: 0.5,
                            heightFactor: 1,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    AppPalette.amber.withValues(alpha: 0.2),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (loading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: AppPalette.amber,
                  ),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.6,
                        color: AppPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: AppPalette.amber,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwitchAccountFooter extends StatelessWidget {
  const _SwitchAccountFooter({
    required this.onForgot,
    required this.onJoin,
  });
  final VoidCallback onForgot;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        children: [
          TextButton(
            onPressed: onForgot,
            child: Text(
              'Forgot password?',
              style: TextStyle(
                fontSize: 12,
                color: AppPalette.purpleSoft,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_outline,
                size: 13,
                color: AppPalette.textDisabled,
              ),
              const SizedBox(width: 6),
              Text(
                'New here?',
                style: TextStyle(
                  fontSize: 12,
                  color: AppPalette.textDisabled,
                ),
              ),
              TextButton(
                onPressed: onJoin,
                child: Text(
                  'Join Now',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppPalette.purpleSoft,
                    decoration: TextDecoration.underline,
                    decorationColor:
                        AppPalette.purpleSoft.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Username field (with live availability check) ───────────────

class _UsernameField extends StatelessWidget {
  const _UsernameField({
    required this.controller,
    required this.status,
    required this.onChanged,
  });

  final TextEditingController controller;
  final _UsernameStatus status;
  final ValueChanged<String> onChanged;

  Widget _statusIcon() {
    switch (status) {
      case _UsernameStatus.checking:
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
      case _UsernameStatus.available:
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Icon(
            Icons.check_circle,
            color: AppPalette.success,
            size: 22,
          ),
        );
      case _UsernameStatus.taken:
      case _UsernameStatus.reserved:
      case _UsernameStatus.invalid:
      case _UsernameStatus.error:
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Icon(Icons.cancel, color: AppPalette.danger, size: 22),
        );
      case _UsernameStatus.idle:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'HERO NAME',
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
          textCapitalization: TextCapitalization.none,
          autocorrect: false,
          enableSuggestions: false,
          maxLength: 20,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9_]')),
            LengthLimitingTextInputFormatter(20),
          ],
          style: const TextStyle(
            fontSize: 15,
            color: AppPalette.textPrimary,
            fontFamily: 'JetBrainsMono',
          ),
          decoration: InputDecoration(
            hintText: 'warriorname',
            hintStyle: TextStyle(
              fontSize: 14,
              fontFamily: 'JetBrainsMono',
              color: AppPalette.textMuted.withValues(alpha: 0.5),
            ),
            counterText: '',
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 12, right: 8),
              child: Icon(
                Icons.person_outline,
                size: 18,
                color: AppPalette.purpleSoft,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            suffixIcon: _statusIcon(),
            suffixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            filled: true,
            fillColor: AppPalette.purple.withValues(alpha: 0.08),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: _border(0.28),
            enabledBorder: _border(0.28),
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

class _UsernameStatusLabel extends StatelessWidget {
  const _UsernameStatusLabel({
    required this.status,
    required this.rpcError,
  });
  final _UsernameStatus status;
  final String? rpcError;

  @override
  Widget build(BuildContext context) {
    final (text, color) = switch (status) {
      _UsernameStatus.idle => (
          'At least 3 characters.',
          AppPalette.textMuted,
        ),
      _UsernameStatus.checking => ('Checking…', AppPalette.textMuted),
      _UsernameStatus.available => ('Available!', AppPalette.success),
      _UsernameStatus.taken => ('Already taken.', AppPalette.danger),
      _UsernameStatus.reserved => (
          'Reserved — pick another.',
          AppPalette.danger,
        ),
      _UsernameStatus.invalid => (
          'Lowercase letters, digits, and _ only. 3-20 characters.',
          AppPalette.danger,
        ),
      _UsernameStatus.error => (
          rpcError ?? 'Could not check. Try again.',
          AppPalette.danger,
        ),
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

// ─── Phone field (country chip + number input) ───────────────────

class _PhoneField extends StatelessWidget {
  const _PhoneField({
    required this.controller,
    required this.country,
    required this.onOpenCountryPicker,
  });

  final TextEditingController controller;
  final _Country country;
  final VoidCallback onOpenCountryPicker;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PHONE NUMBER',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: AppPalette.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _CountryChip(country: country, onTap: onOpenCountryPicker),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(15),
                ],
                style: const TextStyle(
                  fontSize: 15,
                  color: AppPalette.textPrimary,
                  fontFamily: 'JetBrainsMono',
                ),
                decoration: InputDecoration(
                  hintText: '5551234567',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    fontFamily: 'JetBrainsMono',
                    color: AppPalette.textMuted.withValues(alpha: 0.5),
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 12, right: 8),
                    child: Icon(
                      Icons.notifications_outlined,
                      size: 18,
                      color: AppPalette.purpleSoft,
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 0,
                    minHeight: 0,
                  ),
                  filled: true,
                  fillColor: AppPalette.purple.withValues(alpha: 0.08),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  border: _border(0.28),
                  enabledBorder: _border(0.28),
                  focusedBorder: _border(0.55),
                ),
              ),
            ),
          ],
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

class _PhoneHelperNote extends StatelessWidget {
  const _PhoneHelperNote();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              Icons.diamond_outlined,
              size: 11,
              color: AppPalette.purpleSoft,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 11,
                  color: AppPalette.textMuted,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(text: 'We use this to help you '),
                  TextSpan(
                    text: 'connect with friends',
                    style: TextStyle(
                      color: AppPalette.purpleSoft,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const TextSpan(
                      text: ' directly — no searching required.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Country picker (chip + bottom sheet) ────────────────────────

class _Country {
  const _Country(this.flag, this.name, this.dial, this.expectedDigits);
  final String flag;
  final String name;
  final String dial;
  final int expectedDigits;

  @override
  bool operator ==(Object other) =>
      other is _Country && other.dial == dial && other.name == name;

  @override
  int get hashCode => Object.hash(dial, name);
}

const List<_Country> _commonCountries = [
  _Country('🇮🇳', 'India', '+91', 10),
  _Country('🇺🇸', 'United States', '+1', 10),
  _Country('🇬🇧', 'United Kingdom', '+44', 10),
  _Country('🇨🇦', 'Canada', '+1', 10),
  _Country('🇦🇺', 'Australia', '+61', 9),
  _Country('🇦🇪', 'United Arab Emirates', '+971', 9),
  _Country('🇸🇬', 'Singapore', '+65', 8),
  _Country('🇸🇦', 'Saudi Arabia', '+966', 9),
  _Country('🇳🇿', 'New Zealand', '+64', 9),
  _Country('🇮🇪', 'Ireland', '+353', 9),
  _Country('🇵🇰', 'Pakistan', '+92', 10),
  _Country('🇧🇩', 'Bangladesh', '+880', 10),
  _Country('🇳🇵', 'Nepal', '+977', 10),
  _Country('🇱🇰', 'Sri Lanka', '+94', 9),
  _Country('🇲🇾', 'Malaysia', '+60', 9),
  _Country('🇮🇩', 'Indonesia', '+62', 10),
  _Country('🇵🇭', 'Philippines', '+63', 10),
  _Country('🇯🇵', 'Japan', '+81', 10),
  _Country('🇰🇷', 'South Korea', '+82', 10),
  _Country('🇨🇳', 'China', '+86', 11),
  _Country('🇫🇷', 'France', '+33', 9),
  _Country('🇩🇪', 'Germany', '+49', 11),
  _Country('🇪🇸', 'Spain', '+34', 9),
  _Country('🇮🇹', 'Italy', '+39', 10),
  _Country('🇧🇷', 'Brazil', '+55', 11),
  _Country('🇲🇽', 'Mexico', '+52', 10),
  _Country('🇿🇦', 'South Africa', '+27', 9),
  _Country('🇪🇬', 'Egypt', '+20', 10),
  _Country('🇰🇪', 'Kenya', '+254', 9),
  _Country('🇳🇬', 'Nigeria', '+234', 10),
];

class _CountryChip extends StatelessWidget {
  const _CountryChip({required this.country, required this.onTap});
  final _Country country;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: AppPalette.purple.withValues(alpha: 0.08),
            border: Border.all(
              color: AppPalette.purple.withValues(alpha: 0.30),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(country.flag, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text(
                country.dial,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'JetBrainsMono',
                  fontWeight: FontWeight.w700,
                  color: AppPalette.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.expand_more,
                size: 16,
                color: AppPalette.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountryPickerSheet extends StatefulWidget {
  const _CountryPickerSheet();

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? _commonCountries
        : _commonCountries.where((c) {
            final q = _query.toLowerCase();
            return c.name.toLowerCase().contains(q) || c.dial.contains(q);
          }).toList();

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppPalette.textDim,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'SELECT COUNTRY',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                color: AppPalette.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                style: const TextStyle(
                  fontSize: 15,
                  color: AppPalette.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Search country or +code',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: AppPalette.textMuted.withValues(alpha: 0.6),
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 18,
                    color: AppPalette.textMuted,
                  ),
                  filled: true,
                  fillColor: AppPalette.purple.withValues(alpha: 0.08),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppPalette.purple.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final c = filtered[i];
                  return ListTile(
                    leading: Text(
                      c.flag,
                      style: const TextStyle(fontSize: 22),
                    ),
                    title: Text(
                      c.name,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppPalette.textPrimary,
                      ),
                    ),
                    trailing: Text(
                      c.dial,
                      style: const TextStyle(
                        fontSize: 13,
                        fontFamily: 'JetBrainsMono',
                        fontWeight: FontWeight.w700,
                        color: AppPalette.purpleSoft,
                      ),
                    ),
                    onTap: () => Navigator.of(context).pop(c),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
