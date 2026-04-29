import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../data/services/public_profile_service.dart';
import '../../data/supabase/phone_hasher.dart';
import '../../theme/tokens.dart';
import '../../widgets/screen_base.dart';
import 'auth_widgets.dart';

/// Phone Number — final cloud-account screen before the local
/// onboarding chain (`/age`, `/height`, …) takes over. Optional input;
/// users can skip with a clear "consequence" message ("friends won't
/// find you in their contacts unless you add a phone").
///
/// On submit, both the raw phone (E.164) and the salted SHA-256 hash
/// are pushed to `public_profiles`. The raw value is used for the
/// "your number on file" display in Settings; the hash is what
/// `find_users_by_phone_hashes` matches against.
class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key});

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  static const _defaultCountry = _Country('🇮🇳', 'India', '+91', 10);
  _Country _country = _defaultCountry;
  final _controller = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _phoneValid {
    final digits = _controller.text;
    if (digits.length < 7) return false;
    if (digits.length > 15) return false;
    return RegExp(r'^[0-9]{7,15}$').hasMatch(digits);
  }

  String? get _e164 {
    if (!_phoneValid) return null;
    final raw = '${_country.dial}${_controller.text}';
    return PhoneHasher.normalizeToE164(raw);
  }

  Future<void> _save() async {
    final phoneE164 = _e164;
    if (phoneE164 == null || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final result = await PublicProfileService.upsertProfile(
      phoneE164: phoneE164,
    );
    if (!mounted) return;
    if (result.ok) {
      _continueToOnboarding();
    } else {
      setState(() {
        _submitting = false;
        _error = result.errorMessage;
      });
    }
  }

  void _skip() => _continueToOnboarding();

  void _continueToOnboarding() {
    // First step in the existing local-onboarding chain after the
    // socials block. /register collected display_name; /age is the
    // first local-only attribute screen.
    context.go('/age');
  }

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
        _controller.clear();
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
                child: AuthBackChip(onTap: () => context.go('/username')),
              ),
              const SizedBox(height: 24),
              const Text(
                'ADD YOUR NUMBER',
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
                "So friends already on the app find you in their contacts. "
                "Used only for matching — never shared with anyone.",
                style: TextStyle(
                  fontSize: 13,
                  color: AppPalette.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'PHONE',
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
                  _CountryChip(
                    country: _country,
                    onTap: _openCountryPicker,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      keyboardType: TextInputType.phone,
                      autocorrect: false,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(15),
                      ],
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'JetBrainsMono',
                        color: AppPalette.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: '98765 43210',
                        hintStyle: TextStyle(
                          fontSize: 15,
                          fontFamily: 'JetBrainsMono',
                          color: AppPalette.textMuted.withValues(alpha: 0.5),
                        ),
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
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const _PrivacyNote(),
              if (_error != null) ...[
                const SizedBox(height: 12),
                AuthErrorBanner(message: _error!),
              ],
              const Spacer(),
              PrimaryAuthButton(
                label: 'SAVE PHONE',
                enabled: _phoneValid && !_submitting,
                loading: _submitting,
                onTap: _save,
              ),
              const SizedBox(height: 10),
              SecondaryAuthButton(
                label: 'SKIP FOR NOW',
                onTap: _skip,
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  "Skipping means friends can't find you via contacts. "
                  "Add it later from Settings.",
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

  OutlineInputBorder _border(double alpha) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppPalette.purple.withValues(alpha: alpha),
          width: 1,
        ),
      );
}

// ─── Country model + picker sheet ─────────────────────────────

class _Country {
  const _Country(this.flag, this.name, this.dial, this.expectedDigits);
  final String flag;
  final String name;
  final String dial; // e.g. '+91'
  final int expectedDigits; // for hint placement; not strictly enforced

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
            return c.name.toLowerCase().contains(q) ||
                c.dial.contains(q);
          }).toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
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
                    leading: Text(c.flag, style: const TextStyle(fontSize: 22)),
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

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: AppPalette.purple.withValues(alpha: 0.06),
        border: Border.all(
          color: AppPalette.purple.withValues(alpha: 0.20),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lock_outline,
            size: 16,
            color: AppPalette.purpleSoft,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'We hash your number with a server-side salt before storing. '
              'Used only to match against contacts already on the app.',
              style: TextStyle(
                fontSize: 11,
                color: AppPalette.textMuted,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
