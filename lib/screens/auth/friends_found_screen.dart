import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/models/contact_match.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/friend_service.dart';
import '../../theme/tokens.dart';
import '../../widgets/screen_base.dart';
import 'auth_widgets.dart';

/// Args bundle passed via `context.go(..., extra: ...)`.
class FriendsFoundArgs {
  const FriendsFoundArgs({
    required this.matches,
    required this.scanned,
    required this.skippedNoCountryCode,
    this.errorMessage,
  });

  final List<ContactMatch> matches;
  final int scanned;
  final int skippedNoCountryCode;
  final String? errorMessage;
}

/// Renders the result of [ContactMatchService.scanAndMatch]:
///   • non-empty matches: list with `Add Friend` per row.
///   • zero matches but contacts scanned: empty-state with invite-link
///     share CTA.
///   • error during scan/RPC: error banner + invite-link CTA so the
///     user still has a path forward.
class FriendsFoundScreen extends StatefulWidget {
  const FriendsFoundScreen({super.key, required this.args});

  final FriendsFoundArgs args;

  @override
  State<FriendsFoundScreen> createState() => _FriendsFoundScreenState();
}

class _FriendsFoundScreenState extends State<FriendsFoundScreen> {
  /// userId → 'idle' | 'sending' | 'sent' | 'error'.
  final Map<String, String> _statusByUser = {};

  Future<void> _addFriend(ContactMatch match) async {
    setState(() => _statusByUser[match.userId] = 'sending');
    final result = await FriendService.sendRequest(match.userId);
    if (!mounted) return;
    setState(() {
      _statusByUser[match.userId] =
          result.ok ? 'sent' : 'error';
    });
  }

  Future<void> _shareInvite() async {
    final username = AuthService.currentEmail?.split('@').first ?? 'me';
    // Real deep-link generation lands in S5 (invite-link route +
    // short-code creation). For S4, share a placeholder URL the user
    // can paste; recipients will be re-routed once S5 lands.
    final text = 'Train with me on Level Up IRL — '
        'https://levelup-irl.app/invite/$username';
    await Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    final args = widget.args;
    final hasMatches = args.matches.isNotEmpty;

    return ScreenBase(
      background: AppPalette.obsidian,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.s6,
            AppSpace.s4,
            AppSpace.s6,
            AppSpace.s4,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              AuthBackChip(onTap: () => context.go('/home')),
              const SizedBox(height: 28),
              Text(
                hasMatches ? 'YOUR PARTY\nIS HERE' : 'NO MATCHES\nYET',
                style: AppType.displayLG(color: AppPalette.textPrimary),
              ),
              const SizedBox(height: 12),
              Text(
                hasMatches
                    ? '${args.matches.length} contact${args.matches.length == 1 ? '' : 's'} '
                        'already train${args.matches.length == 1 ? 's' : ''} with us. '
                        'Send a friend request — leaderboards open up once they accept.'
                    : 'None of your contacts are on the app yet. '
                        'Invite a few — they\'ll show up here when they sign up.',
                style: AppType.bodyMD(color: AppPalette.textMuted),
              ),
              if (!hasMatches && args.skippedNoCountryCode > 0) ...[
                const SizedBox(height: 12),
                Text(
                  'Note: ${args.skippedNoCountryCode} contact'
                  '${args.skippedNoCountryCode == 1 ? '' : 's'} couldn\'t be checked '
                  '(saved without a country code in an unrecognised format). '
                  'Re-save them with the country code and try again.',
                  style: AppType.bodyMD(color: AppPalette.amber),
                ),
              ],
              if (args.errorMessage != null) ...[
                const SizedBox(height: 16),
                AuthErrorBanner(message: args.errorMessage!),
              ],
              const SizedBox(height: AppSpace.s6),
              Expanded(
                child: hasMatches
                    ? ListView.separated(
                        itemCount: args.matches.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 12),
                        itemBuilder: (_, i) {
                          final m = args.matches[i];
                          final status = _statusByUser[m.userId] ?? 'idle';
                          return _MatchTile(
                            match: m,
                            status: status,
                            onAdd: () => _addFriend(m),
                          );
                        },
                      )
                    : const _EmptyArt(),
              ),
              if (!hasMatches)
                SecondaryAuthButton(
                  label: 'INVITE FRIENDS',
                  onTap: _shareInvite,
                ),
              if (hasMatches) ...[
                SecondaryAuthButton(
                  label: 'INVITE MORE',
                  onTap: _shareInvite,
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 12),
              PrimaryAuthButton(
                label: 'CONTINUE',
                enabled: true,
                loading: false,
                onTap: () => context.go('/home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchTile extends StatelessWidget {
  const _MatchTile({
    required this.match,
    required this.status,
    required this.onAdd,
  });

  final ContactMatch match;
  final String status;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppPalette.purple.withValues(alpha: 0.06),
        border: Border.all(
          color: AppPalette.purple.withValues(alpha: 0.20),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _Avatar(displayName: match.displayName),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  match.displayName.isEmpty
                      ? '@${match.username}'
                      : match.displayName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '@${match.username} · LV ${match.level}'
                  '${match.currentStreak > 0 ? ' · ${match.currentStreak}-day streak' : ''}',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppPalette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _AddButton(status: status, onTap: onAdd),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.displayName});
  final String displayName;

  String get _initial {
    final t = displayName.trim();
    return t.isEmpty ? '?' : t.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppPalette.purpleDeep, AppPalette.purple],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        _initial,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppPalette.textPrimary,
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.status, required this.onTap});
  final String status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (label, color, enabled, loading) = switch (status) {
      'sending' => ('SENDING', AppPalette.amber, false, true),
      'sent' => ('SENT', AppPalette.green, false, false),
      'error' => ('RETRY', AppPalette.danger, true, false),
      _ => ('ADD', AppPalette.amber, true, false),
    };
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: color.withValues(alpha: 0.14),
            border: Border.all(
              color: color.withValues(alpha: 0.45),
              width: 1,
            ),
          ),
          child: loading
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              : Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: color,
                  ),
                ),
        ),
      ),
    );
  }
}

class _EmptyArt extends StatelessWidget {
  const _EmptyArt();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppPalette.purple.withValues(alpha: 0.08),
              border: Border.all(
                color: AppPalette.purple.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.group_add_outlined,
              size: 44,
              color: AppPalette.purpleSoft,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Be the first.',
            style: AppType.label(color: AppPalette.textMuted),
          ),
        ],
      ),
    );
  }
}
