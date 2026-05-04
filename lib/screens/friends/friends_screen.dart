import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/friend_entry.dart';
import '../../data/services/friend_service.dart';
import '../../theme/tokens.dart';
import '../../widgets/in_app_shell.dart';
import '../../widgets/tab_bar.dart';

/// Friends hub. Matches the v1-improvements design:
///   • Header — X close, "Friends" title, QR icon (top-right).
///   • Action rows — Search Contacts, Instagram Friends, Invite Friends,
///     Share QR Code, Send Challenge Link. Implemented entries route to
///     real flows; unimplemented ones surface a "coming soon" dialog.
///   • Search bar — taps through to the existing /friends/search
///     username typeahead.
///   • Friend Requests section — pending incoming with Accept/Decline.
///   • Friends section — accepted-mutual friends, with a Leaderboard
///     CTA button on the right of the section header.
///   • Outgoing + Blocked sections retained but compact.
///
/// Uses `InAppShell` so the floating tab bar stays visible at the
/// bottom (matches the design); `showHeader: false` lets us draw the
/// custom title row. Active tab = home, since Friends is reached from
/// the home hex avatar.
class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  late Future<List<FriendEntry>> _future;
  // Per-row in-flight indicator so a slow accept doesn't lock the
  // whole screen.
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _future = FriendService.fullGraph();
  }

  Future<void> _refresh() async {
    final f = FriendService.fullGraph();
    setState(() => _future = f);
    await f;
  }

  Future<void> _runAction(
    String friendshipId,
    Future<FriendActionResult> Function() action,
  ) async {
    setState(() => _busy.add(friendshipId));
    final result = await action();
    if (!mounted) return;
    setState(() => _busy.remove(friendshipId));
    if (!result.ok && result.errorMessage != null) {
      _showInfoDialog(
        title: 'Action failed',
        body: result.errorMessage!,
        accent: AppPalette.danger,
      );
      return;
    }
    await _refresh();
  }

  Future<void> _showInfoDialog({
    required String title,
    required String body,
    Color accent = AppPalette.purpleSoft,
  }) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppPalette.bgCard,
        title: Text(title, style: TextStyle(color: accent)),
        content: Text(
          body,
          style: const TextStyle(color: AppPalette.textMuted, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK',
                style: TextStyle(color: AppPalette.textPrimary)),
          ),
        ],
      ),
    );
  }

  void _comingSoon(String featureName) => _showInfoDialog(
        title: 'Coming soon',
        body: '$featureName lands in a future release. '
            'Stay tuned.',
      );

  @override
  Widget build(BuildContext context) {
    return InAppShell(
      active: AppTab.home,
      title: 'FRIENDS',
      showHeader: false,
      child: Column(
        children: [
          _Header(
            onClose: () => context.go('/home'),
            onQr: () => _comingSoon('Share QR Code'),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              color: AppPalette.amber,
              backgroundColor: AppPalette.obsidian,
              child: FutureBuilder<List<FriendEntry>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppPalette.amber,
                      ),
                    );
                  }
                  final all = snap.data ?? const <FriendEntry>[];
                  final incoming = all.where((e) => e.isIncoming).toList();
                  final friends = all
                      .where((e) =>
                          e.isFriend &&
                          e.direction == FriendDirection.mutual)
                      .toList();
                  final outgoing = all.where((e) => e.isOutgoing).toList();
                  final blocked = all.where((e) => e.isBlocked).toList();

                  return ListView(
                    padding: EdgeInsets.fromLTRB(
                      AppSpace.s5,
                      AppSpace.s2,
                      AppSpace.s5,
                      InAppShell.tabBarSafeBottom +
                          MediaQuery.of(context).padding.bottom,
                    ),
                    children: [
                      _ActionRow(
                        icon: Icons.search,
                        label: 'Search Contacts',
                        onTap: () => context.go('/contacts-permission'),
                      ),
                      _ActionRow(
                        icon: Icons.camera_alt_outlined,
                        label: 'Instagram Friends',
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFFFC371),
                            Color(0xFFFF5F6D),
                            Color(0xFFC471F5),
                          ],
                        ),
                        onTap: () => _comingSoon('Instagram Friends'),
                      ),
                      _ActionRow(
                        icon: Icons.mail_outline,
                        label: 'Invite Friends',
                        onTap: () => _comingSoon('Invite Friends'),
                      ),
                      _ActionRow(
                        icon: Icons.qr_code_2,
                        label: 'Share QR Code',
                        onTap: () => _comingSoon('Share QR Code'),
                      ),
                      _ActionRow(
                        icon: Icons.bolt_outlined,
                        label: 'Send Challenge Link',
                        onTap: () => _comingSoon('Send Challenge Link'),
                      ),
                      const SizedBox(height: AppSpace.s4),
                      _SearchBar(
                        onTap: () => context.go('/friends/search'),
                      ),
                      const SizedBox(height: AppSpace.s5),
                      if (incoming.isNotEmpty) ...[
                        _SectionTitle(
                          label: 'Friend Requests',
                          count: incoming.length,
                          countTint: AppPalette.danger,
                        ),
                        const SizedBox(height: 10),
                        ...incoming.map(
                          (e) => _IncomingTile(
                            entry: e,
                            busy: _busy.contains(e.friendshipId),
                            onAccept: () => _runAction(
                              e.friendshipId,
                              () => FriendService.accept(e.friendshipId),
                            ),
                            onDecline: () => _runAction(
                              e.friendshipId,
                              () => FriendService.decline(e.friendshipId),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpace.s5),
                      ],
                      _FriendsHeader(
                        count: friends.length,
                        onLeaderboard: () => context.go('/leaderboard'),
                      ),
                      const SizedBox(height: 10),
                      if (friends.isEmpty && incoming.isEmpty)
                        const _EmptyFriendsBlock()
                      else
                        ...friends.map(
                          (e) => _FriendTile(
                            entry: e,
                            busy: _busy.contains(e.friendshipId),
                            onRemove: () => _runAction(
                              e.friendshipId,
                              () => FriendService.remove(e.friendshipId),
                            ),
                            onBlock: () => _runAction(
                              e.friendshipId,
                              () => FriendService.block(e.friendshipId),
                            ),
                          ),
                        ),
                      if (outgoing.isNotEmpty) ...[
                        const SizedBox(height: AppSpace.s5),
                        _SectionTitle(
                          label: 'Pending',
                          count: outgoing.length,
                          countTint: AppPalette.purpleSoft,
                        ),
                        const SizedBox(height: 10),
                        ...outgoing.map(
                          (e) => _OutgoingTile(
                            entry: e,
                            busy: _busy.contains(e.friendshipId),
                            onCancel: () => _runAction(
                              e.friendshipId,
                              () => FriendService.remove(e.friendshipId),
                            ),
                          ),
                        ),
                      ],
                      if (blocked.isNotEmpty) ...[
                        const SizedBox(height: AppSpace.s5),
                        _SectionTitle(
                          label: 'Blocked',
                          count: blocked.length,
                          countTint: AppPalette.danger,
                        ),
                        const SizedBox(height: 10),
                        ...blocked.map(
                          (e) => _BlockedTile(
                            entry: e,
                            busy: _busy.contains(e.friendshipId),
                            onUnblock: () => _runAction(
                              e.friendshipId,
                              () => FriendService.remove(e.friendshipId),
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.onClose, required this.onQr});
  final VoidCallback onClose;
  final VoidCallback onQr;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.s4,
        AppSpace.s3,
        AppSpace.s4,
        AppSpace.s2,
      ),
      child: Row(
        children: [
          _CircleIconButton(icon: Icons.close, onTap: onClose),
          Expanded(
            child: Center(
              child: Text(
                'Friends',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppPalette.textPrimary,
                ),
              ),
            ),
          ),
          _CircleIconButton(icon: Icons.qr_code_2, onTap: onQr),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppPalette.purple.withValues(alpha: 0.10),
            border: Border.all(
              color: AppPalette.purple.withValues(alpha: 0.30),
              width: 1,
            ),
          ),
          child: Icon(icon, size: 18, color: AppPalette.textPrimary),
        ),
      ),
    );
  }
}

// ─── Action row ──────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.gradient,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Optional brand gradient for the leading icon (Instagram-style).
  /// When null the icon picks up the standard purple treatment.
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: AppPalette.purple.withValues(alpha: 0.05),
              border: Border.all(
                color: AppPalette.purple.withValues(alpha: 0.22),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: gradient,
                    color: gradient == null
                        ? AppPalette.purple.withValues(alpha: 0.18)
                        : null,
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: gradient != null
                        ? Colors.white
                        : AppPalette.purpleSoft,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppPalette.textPrimary,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppPalette.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Search bar (taps through to /friends/search) ───────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: AppPalette.purple.withValues(alpha: 0.06),
            border: Border.all(
              color: AppPalette.purple.withValues(alpha: 0.22),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.search, size: 16, color: AppPalette.textMuted),
              const SizedBox(width: 10),
              Text(
                'Search by name or username',
                style: TextStyle(
                  fontSize: 13,
                  color: AppPalette.textDim,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Section + Friends header ───────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.label,
    required this.count,
    required this.countTint,
  });
  final String label;
  final int count;
  final Color countTint;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppPalette.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(20),
            color: countTint.withValues(alpha: 0.18),
            border: Border.all(
              color: countTint.withValues(alpha: 0.40),
              width: 1,
            ),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: countTint,
            ),
          ),
        ),
      ],
    );
  }
}

class _FriendsHeader extends StatelessWidget {
  const _FriendsHeader({
    required this.count,
    required this.onLeaderboard,
  });
  final int count;
  final VoidCallback onLeaderboard;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _SectionTitle(
          label: 'Friends',
          count: count,
          countTint: AppPalette.purpleSoft,
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onLeaderboard,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: AppPalette.amber.withValues(alpha: 0.14),
                border: Border.all(
                  color: AppPalette.amber.withValues(alpha: 0.55),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.leaderboard_outlined,
                      size: 14, color: AppPalette.amber),
                  const SizedBox(width: 6),
                  Text(
                    'Leaderboard',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppPalette.amber,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right,
                      size: 14, color: AppPalette.amber),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Tiles ───────────────────────────────────────────────────────

class _BaseTile extends StatelessWidget {
  const _BaseTile({required this.entry, required this.trailing});
  final FriendEntry entry;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
          _Avatar(displayName: entry.displayName),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.displayName.isEmpty
                      ? '@${entry.username}'
                      : entry.displayName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '@${entry.username} · LV ${entry.level}'
                  '${entry.currentStreak > 0 ? ' · ${entry.currentStreak}-day streak' : ''}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppPalette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}

class _IncomingTile extends StatelessWidget {
  const _IncomingTile({
    required this.entry,
    required this.busy,
    required this.onAccept,
    required this.onDecline,
  });
  final FriendEntry entry;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return _BaseTile(
      entry: entry,
      trailing: busy
          ? const _BusySpinner()
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SquareIcon(
                  icon: Icons.close,
                  color: AppPalette.textMuted,
                  onTap: onDecline,
                ),
                const SizedBox(width: 6),
                _SquareIcon(
                  icon: Icons.check,
                  color: AppPalette.green,
                  filled: true,
                  onTap: onAccept,
                ),
              ],
            ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  const _FriendTile({
    required this.entry,
    required this.busy,
    required this.onRemove,
    required this.onBlock,
  });
  final FriendEntry entry;
  final bool busy;
  final VoidCallback onRemove;
  final VoidCallback onBlock;

  @override
  Widget build(BuildContext context) {
    return _BaseTile(
      entry: entry,
      trailing: busy
          ? const _BusySpinner()
          : PopupMenuButton<String>(
              icon: Icon(Icons.more_horiz, color: AppPalette.textMuted),
              color: AppPalette.obsidian,
              onSelected: (v) {
                if (v == 'remove') onRemove();
                if (v == 'block') onBlock();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'remove',
                  child: Text(
                    'Remove friend',
                    style: TextStyle(color: AppPalette.textPrimary),
                  ),
                ),
                const PopupMenuItem(
                  value: 'block',
                  child: Text(
                    'Block',
                    style: TextStyle(color: AppPalette.danger),
                  ),
                ),
              ],
            ),
    );
  }
}

class _OutgoingTile extends StatelessWidget {
  const _OutgoingTile({
    required this.entry,
    required this.busy,
    required this.onCancel,
  });
  final FriendEntry entry;
  final bool busy;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return _BaseTile(
      entry: entry,
      trailing: busy
          ? const _BusySpinner()
          : _ActionPill(
              label: 'CANCEL',
              color: AppPalette.textMuted,
              onTap: onCancel,
            ),
    );
  }
}

class _BlockedTile extends StatelessWidget {
  const _BlockedTile({
    required this.entry,
    required this.busy,
    required this.onUnblock,
  });
  final FriendEntry entry;
  final bool busy;
  final VoidCallback onUnblock;

  @override
  Widget build(BuildContext context) {
    return _BaseTile(
      entry: entry,
      trailing: busy
          ? const _BusySpinner()
          : _ActionPill(
              label: 'UNBLOCK',
              color: AppPalette.danger,
              onTap: onUnblock,
            ),
    );
  }
}

// ─── Tiny widgets ────────────────────────────────────────────────

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
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppPalette.purpleDeep, AppPalette.purple],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        _initial,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppPalette.textPrimary,
        ),
      ),
    );
  }
}

class _SquareIcon extends StatelessWidget {
  const _SquareIcon({
    required this.icon,
    required this.color,
    required this.onTap,
    this.filled = false,
  });
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: filled
                ? color.withValues(alpha: 0.85)
                : color.withValues(alpha: 0.14),
            border: Border.all(
              color: color.withValues(alpha: 0.55),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: filled ? AppPalette.voidBg : color,
          ),
        ),
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.label,
    required this.color,
    required this.onTap,
  });
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: color.withValues(alpha: 0.14),
          border: Border.all(
            color: color.withValues(alpha: 0.45),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _BusySpinner extends StatelessWidget {
  const _BusySpinner();
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: AppPalette.amber,
      ),
    );
  }
}

class _EmptyFriendsBlock extends StatelessWidget {
  const _EmptyFriendsBlock();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppPalette.purple.withValues(alpha: 0.05),
        border: Border.all(
          color: AppPalette.purple.withValues(alpha: 0.20),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.people_alt_outlined,
            size: 32,
            color: AppPalette.purpleSoft,
          ),
          const SizedBox(height: 10),
          const Text(
            'No friends yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Search by username, scan your contacts,\nor invite a friend.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppPalette.textMuted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
