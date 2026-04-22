import 'package:flutter/foundation.dart';

class PlayerState extends ChangeNotifier {
  String playerName = 'Kael·7';
  int level = 24;
  int streak = 21;
  int xpCurrent = 1420;
  int xpMax = 2000;

  double get xpPercent => xpCurrent / xpMax;

  void addXp(int amount) {
    xpCurrent = (xpCurrent + amount).clamp(0, xpMax);
    notifyListeners();
  }
}
