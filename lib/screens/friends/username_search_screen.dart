import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/friend_entry.dart';
import '../../data/services/friend_service.dart';
import '../../theme/tokens.dart';
import '../../widgets/screen_base.dart';

/// Typeahead username search → Add Friend per row.
///
/// Calls [search_users_by_username] (server enforces 3-char minimum +
/// 30/min/user rate limit). Debounced 320ms locally so typing doesn't
/// burn rate-limit budget.
///
/// Add per row uses [FriendService.sendRequest]; idempotent on the
/// unique-pair index — duplicate inserts return `alreadyExists: true`,
/// flipping the button to "Sent ✓" without a server round-trip.
class UsernameSearchScreen extends StatefulWidget {
  const UsernameSearchScreen({super.key});

  @override
  State<UsernameSearchScreen> createState() => _UsernameSearchScreenState();
}

class _UsernameSearchScreenState extends State<UsernameSearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<UsernameSearchResult> _results = const [];
  bool _searching = false;
  String _lastQuery = '';
  // userId → 'sending' | 'sent' | 'error'.
  final Map<String, String> _statusByUser = {};

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    final query = q.trim();
    if (query.length < 3) {
      setState(() {
        _results = const [];
        _searching = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 320), () => _run(query));
  }

  Future<void> _run(String query) async {
    setState(() {
      _searching = true;
      _lastQuery = query;
    });
    final results = await FriendService.searchByUsername(query);
    if (!mounted || _lastQuery != query) return;
    setState(() {
      _results = results;
      _searching = false;
    });
  }

  Future<void> _add(UsernameSearchResult r) async {
    setState(() => _statusByUser[r.userId] = 'sending');
    final result = await FriendService.sendRequest(r.userId);
    if (!mounted) return;
    setState(() {
      _statusByUser[r.userId] = result.ok ? 'sent' : 'error';
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScreenBase(
      background: AppPalette.obsidian,
      child: SafeArea(
        child: Column(
          children: [
            _Header(onBack: () => context.go('/friends')),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.s6,
                0,
                AppSpace.s6,
                AppSpace.s4,
              ),
              child: TextField(
                controller: _controller,
                autofocus: true,
                onChanged: _onChanged,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9_]')),
                  LengthLimitingTextInputFormatter(20),
                ],
                style: TextStyle(
                  color: AppPalette.textPrimary,
                  fontSize: 16,
                ),
                cursorColor: AppPalette.amber,
                decoration: InputDecoration(
                  hintText: '@username',
                  hintStyle: TextStyle(color: AppPalette.textDisabled),
                  prefixIcon: Icon(
                    Icons.alternate_email,
                    color: AppPalette.textMuted,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: AppPalette.purple.withValues(alpha: 0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppPalette.purple.withValues(alpha: 0.20),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppPalette.purple.withValues(alpha: 0.20),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppPalette.amber.withValues(alpha: 0.45),
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    final query = _controller.text.trim();
    if (query.length < 3) {
      return _Hint(
        text: 'Type at least 3 characters to search.',
      );
    }
    if (_searching && _results.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppPalette.amber),
      );
    }
    if (_results.isEmpty) {
      return _Hint(text: 'No users matching "@$query".');
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.s6,
        0,
        AppSpace.s6,
        AppSpace.s8,
      ),
      itemCount: _results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final r = _results[i];
        final status = _statusByUser[r.userId] ?? 'idle';
        return _ResultTile(
          result: r,
          status: status,
          onAdd: () => _add(r),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});
  final VoidCallback onBack;

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
              'FIND BY USERNAME',
              textAlign: TextAlign.center,
              style: AppType.label(color: AppPalette.textPrimary).copyWith(
                fontSize: 14,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({
    required this.result,
    required this.status,
    required this.onAdd,
  });

  final UsernameSearchResult result;
  final String status;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final (label, color, enabled, loading) = switch (status) {
      'sending' => ('SENDING', AppPalette.amber, false, true),
      'sent' => ('SENT', AppPalette.green, false, false),
      'error' => ('RETRY', AppPalette.danger, true, false),
      _ => ('ADD', AppPalette.amber, true, false),
    };

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
          _Avatar(displayName: result.displayName),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.displayName.isEmpty
                      ? '@${result.username}'
                      : result.displayName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '@${result.username} · LV ${result.level}',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppPalette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: enabled ? onAdd : null,
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

class _Hint extends StatelessWidget {
  const _Hint({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.s8),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: AppType.bodyMD(color: AppPalette.textMuted),
        ),
      ),
    );
  }
}
