import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/friend_entry.dart';
import '../../data/services/friend_service.dart';
import '../../theme/tokens.dart';
import '../../widgets/screen_base.dart';

/// Friends hub. Loads the full friend graph via [FriendService.fullGraph]
/// and renders it as four stacked sections: Incoming (with Accept /
/// Decline), Friends (with Block / Remove via long-press menu),
/// Outgoing (with Cancel), Blocked (collapsed).
///
/// Search button in the app bar routes to /friends/search for the
/// username typeahead flow. Pull-to-refresh re-runs the RPC.
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorMessage!)),
      );
      return;
    }
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenBase(
      background: AppPalette.obsidian,
      child: SafeArea(
        child: Column(
          children: [
            _Header(
              onBack: () => context.go('/profile'),
              onSearch: () => context.go('/friends/search'),
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
                    final incoming =
                        all.where((e) => e.isIncoming).toList();
                    final friends = all
                        .where((e) =>
                            e.isFriend &&
                            e.direction == FriendDirection.mutual)
                        .toList();
                    final outgoing =
                        all.where((e) => e.isOutgoing).toList();
                    final blocked = all.where((e) => e.isBlocked).toList();

                    if (all.isEmpty) {
                      return const _EmptyState();
                    }
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpace.s6,
                        AppSpace.s2,
                        AppSpace.s6,
                        AppSpace.s8,
                      ),
                      children: [
                        if (incoming.isNotEmpty) ...[
                          _SectionHeader(
                            label: 'INCOMING',
                            count: incoming.length,
                          ),
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
                        if (friends.isNotEmpty) ...[
                          _SectionHeader(
                            label: 'FRIENDS',
                            count: friends.length,
                          ),
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
                          const SizedBox(height: AppSpace.s5),
                        ],
                        if (outgoing.isNotEmpty) ...[
                          _SectionHeader(
                            label: 'PENDING',
                            count: outgoing.length,
                          ),
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
                          const SizedBox(height: AppSpace.s5),
                        ],
                        if (blocked.isNotEmpty) ...[
                          _SectionHeader(
                            label: 'BLOCKED',
                            count: blocked.length,
                          ),
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
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.onBack, required this.onSearch});
  final VoidCallback onBack;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.s4,
        AppSpace.s4,
        AppSpace.s4,
        AppSpace.s2,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            color: AppPalette.textPrimary,
            onPressed: onBack,
          ),
          Expanded(
            child: Text(
              'FRIENDS',
              textAlign: TextAlign.center,
              style: AppType.label(color: AppPalette.textPrimary).copyWith(
                fontSize: 14,
                letterSpacing: 2,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            color: AppPalette.textPrimary,
            onPressed: onSearch,
          ),
        ],
      ),
    );
  }
}

// ─── Section header ─────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.count});
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: AppPalette.textMuted,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppPalette.purple.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppPalette.textPrimary,
              ),
            ),
          ),
        ],
      ),
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
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '@${entry.username} · LV ${entry.level}'
                  '${entry.currentStreak > 0 ? ' · ${entry.currentStreak}-day streak' : ''}',
                  style: TextStyle(
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
                _ActionPill(
                  label: 'ACCEPT',
                  color: AppPalette.green,
                  onTap: onAccept,
                ),
                const SizedBox(width: 6),
                _ActionPill(
                  label: 'DECLINE',
                  color: AppPalette.textMuted,
                  onTap: onDecline,
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
              icon: Icon(
                Icons.more_horiz,
                color: AppPalette.textMuted,
              ),
              color: AppPalette.obsidian,
              onSelected: (v) {
                if (v == 'remove') onRemove();
                if (v == 'block') onBlock();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'remove',
                  child: Text(
                    'Remove friend',
                    style: TextStyle(color: AppPalette.textPrimary),
                  ),
                ),
                PopupMenuItem(
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
    return SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: AppPalette.amber,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpace.s8),
      children: [
        const SizedBox(height: 80),
        Center(
          child: Container(
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
              Icons.people_alt_outlined,
              size: 44,
              color: AppPalette.purpleSoft,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'No friends yet.',
          textAlign: TextAlign.center,
          style: AppType.label(color: AppPalette.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          'Search by username or scan your contacts.',
          textAlign: TextAlign.center,
          style: AppType.bodyMD(color: AppPalette.textMuted),
        ),
      ],
    );
  }
}
