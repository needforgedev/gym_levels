/// Shared "now in unix seconds" helper — keeps every service using the same
/// clock shape. Tests can swap by calling `nowOverride = () => ...`.
int Function() nowOverride = _defaultNow;

int _defaultNow() => DateTime.now().millisecondsSinceEpoch ~/ 1000;

int nowSeconds() => nowOverride();
