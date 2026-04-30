import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/services/contact_match_service.dart';
import '../../data/supabase/supabase_client.dart';
import '../../theme/tokens.dart';
import '../../widgets/screen_base.dart';
import 'auth_widgets.dart';
import 'friends_found_screen.dart';

/// First half of the S4 contact-match flow. Explains the privacy
/// posture (hashed-on-device) and asks the user to grant the OS
/// contacts permission. On grant: runs [ContactMatchService.scanAndMatch]
/// and routes to [FriendsFoundScreen] with the result. On skip:
/// straight to /home.
///
/// Insertion point: after /paywall in the post-onboarding flow.
/// Long-term it'll also be reachable from Settings → "Find friends"
/// (S7), which makes the same call against a fresh permission state.
class ContactsPermissionScreen extends StatefulWidget {
  const ContactsPermissionScreen({super.key});

  @override
  State<ContactsPermissionScreen> createState() =>
      _ContactsPermissionScreenState();
}

class _ContactsPermissionScreenState extends State<ContactsPermissionScreen> {
  bool _running = false;
  String? _error;

  Future<void> _allow() async {
    if (_running) return;
    setState(() {
      _running = true;
      _error = null;
    });
    final result = await ContactMatchService.scanAndMatch();
    if (!mounted) return;
    setState(() => _running = false);

    if (!result.ok) {
      // Permission denial is the only soft-failure that should block
      // the next step — every other error still surfaces the matched-
      // friends screen (possibly empty) so the user can pick up an
      // invite link instead.
      if (result.permissionDenied) {
        setState(() => _error = result.errorMessage);
        return;
      }
    }
    context.go(
      '/friends-found',
      extra: FriendsFoundArgs(
        matches: result.matches,
        scanned: result.contactsScanned,
        skippedNoCountryCode: result.contactsSkippedNoCountryCode,
        errorMessage: result.errorMessage,
      ),
    );
  }

  void _skip() => context.go('/home');

  @override
  Widget build(BuildContext context) {
    final socialsConfigured = SupabaseConfig.isConfigured;

    return ScreenBase(
      background: AppPalette.obsidian,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.s6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              AuthBackChip(onTap: _skip),
              const SizedBox(height: 28),
              Text(
                'FIND YOUR\nGYM PARTY',
                style: AppType.displayLG(color: AppPalette.textPrimary),
              ),
              const SizedBox(height: 12),
              Text(
                'See which of your contacts already train with us.',
                style: AppType.bodyMD(color: AppPalette.textMuted),
              ),
              const SizedBox(height: AppSpace.s7),
              const _PrivacyExplainer(),
              const Spacer(),
              if (_error != null) ...[
                AuthErrorBanner(message: _error!),
                const SizedBox(height: 16),
              ],
              if (!socialsConfigured) ...[
                AuthErrorBanner(
                  message: 'Cloud is not configured on this build.',
                ),
                const SizedBox(height: 16),
              ],
              PrimaryAuthButton(
                label: 'ALLOW CONTACTS ACCESS',
                enabled: socialsConfigured && !_running,
                loading: _running,
                onTap: _allow,
              ),
              const SizedBox(height: 12),
              SecondaryAuthButton(label: 'SKIP FOR NOW', onTap: _skip),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrivacyExplainer extends StatelessWidget {
  const _PrivacyExplainer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppPalette.purple.withValues(alpha: 0.06),
        border: Border.all(
          color: AppPalette.purple.withValues(alpha: 0.20),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PrivacyRow(
            icon: Icons.lock_outline,
            title: 'Phone numbers stay on your device',
            body: 'We hash each number with a server-side salt before '
                'sending. Plain numbers never leave your phone.',
          ),
          const SizedBox(height: 14),
          _PrivacyRow(
            icon: Icons.visibility_off_outlined,
            title: 'Names + emails stay private',
            body: 'We only read phone numbers — never contact names, '
                'photos, or email addresses.',
          ),
          const SizedBox(height: 14),
          _PrivacyRow(
            icon: Icons.delete_outline,
            title: 'Hashes are deleted after matching',
            body: 'Server compares hashes once, returns matches, then '
                'discards the upload. Nothing stored.',
          ),
        ],
      ),
    );
  }
}

class _PrivacyRow extends StatelessWidget {
  const _PrivacyRow({
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppPalette.purpleSoft),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.textPrimary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: TextStyle(
                  fontSize: 12,
                  color: AppPalette.textMuted,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
