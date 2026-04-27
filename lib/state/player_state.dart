import 'package:flutter/foundation.dart';

import '../data/models/player.dart';
import '../data/models/player_class_row.dart';
import '../data/services/player_class_service.dart';
import '../data/services/player_service.dart';
import '../data/services/streak_service.dart';
import '../data/services/workout_service.dart';
import '../game/class_catalog.dart';
import '../game/xp_engine.dart';

/// Thin cache over the data services. Populated once from `main.dart` via
/// `..refresh()` and re-populated after every write that changes something
/// Home / Profile / etc. renders.
///
/// Level + XP bar are derived from `WorkoutService.totalXp()` through
/// [XpEngine.resolve]. Streak is pulled from [StreakService.get]. Everything
/// else that used to be a demo scalar is now real.
class PlayerState extends ChangeNotifier {
  Player? _player;
  PlayerClassRow? _classRow;
  int _totalXp = 0;
  int _level = 1;
  int _xpCurrent = 0;
  int _xpMax = 100;
  int _streak = 0;

  Player? get player => _player;
  bool get hasPlayer => _player != null;
  bool get isOnboarded => _player?.isOnboarded ?? false;
  String get playerName => _player?.displayName ?? 'Player';

  /// Resolved class definition (display name, descriptor, buffs, evolutions).
  /// Falls back to the catalog default until [refresh] runs or until the
  /// `player_class` row is seeded.
  ClassDef get playerClass => classFor(_classRow?.classKey);
  PlayerClassRow? get playerClassRow => _classRow;

  int get level => _level;
  int get xpCurrent => _xpCurrent;
  int get xpMax => _xpMax;
  int get totalXp => _totalXp;
  int get streak => _streak;

  double get xpPercent {
    if (_xpMax == 0) return 1.0;
    return (_xpCurrent / _xpMax).clamp(0.0, 1.0);
  }

  /// Called from `main.dart` once and from every mutation path that changes
  /// persisted player / workout / streak state.
  Future<void> refresh() async {
    final player = await PlayerService.getPlayer();
    final totalXp = await WorkoutService.totalXp();
    final snapshot = XpEngine.resolve(totalXp);
    final streak = await StreakService.get();
    var classRow = await PlayerClassService.get();

    // First-run: seed the default class so the Profile / Home class card
    // never has to render a "?" — full derivation matrix lands with §9A.7.
    if (classRow == null && player?.isOnboarded == true) {
      await PlayerClassService.assign(defaultClassKey);
      classRow = await PlayerClassService.get();
    }

    _player = player;
    _classRow = classRow;
    _totalXp = totalXp;
    _level = snapshot.level;
    _xpCurrent = snapshot.xpInLevel;
    _xpMax = snapshot.xpToNext == 0 ? 1 : snapshot.xpToNext;
    _streak = streak?.current ?? 0;

    notifyListeners();
  }

  /// Used by the onboarding name screen. Rewritten here so the screen keeps
  /// its old call site.
  Future<void> setDisplayName(String name) async {
    await PlayerService.setDisplayName(name);
    await refresh();
  }

  /// Optimistic in-memory bump — the logger fires this alongside the real
  /// SQLite write so the XP toast lands instantly. `refresh()` reconciles
  /// with the DB afterwards.
  void addXp(int amount) {
    _totalXp += amount;
    final snapshot = XpEngine.resolve(_totalXp);
    _level = snapshot.level;
    _xpCurrent = snapshot.xpInLevel;
    _xpMax = snapshot.xpToNext == 0 ? 1 : snapshot.xpToNext;
    notifyListeners();
  }
}
