import 'package:flutter/foundation.dart';

import '../data/models/player.dart';
import '../data/services/player_service.dart';

/// Thin cache over [PlayerService]. Screens that need player data read from
/// this notifier; writes go through the service and finish with [refresh] so
/// every observer sees the new value.
///
/// Level / streak / XP are demo scalars today — they'll be backed by
/// `WorkoutService` / `StreakService` / `XpService` in Phase 2.
class PlayerState extends ChangeNotifier {
  Player? _player;
  int level = 1;
  int streak = 0;
  int xpCurrent = 0;
  int xpMax = 100;

  Player? get player => _player;
  bool get hasPlayer => _player != null;
  bool get isOnboarded => _player?.isOnboarded ?? false;

  /// Display name with a sensible fallback before the player row exists.
  String get playerName => _player?.displayName ?? 'Player';

  double get xpPercent => xpMax == 0 ? 0 : xpCurrent / xpMax;

  /// Called once from `main.dart` after `AppDb.init()`. Safe to call again
  /// after any write that may have changed the row.
  Future<void> refresh() async {
    _player = await PlayerService.getPlayer();
    notifyListeners();
  }

  void addXp(int amount) {
    xpCurrent = (xpCurrent + amount).clamp(0, xpMax);
    notifyListeners();
  }

  /// Kept for screens that already call this. Writes through the service and
  /// refreshes the cache so the UI reflects the change.
  Future<void> setDisplayName(String name) async {
    await PlayerService.setDisplayName(name);
    await refresh();
  }
}
