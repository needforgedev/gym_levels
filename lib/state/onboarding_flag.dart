import 'package:flutter/foundation.dart';

/// App-wide flag tracking whether the current player has finished onboarding.
///
/// Populated once at app start by [seedFromDb] and flipped to `true` by the
/// Home screen's first-render completion flow. The go_router `redirect`
/// listens to this notifier so returning users jump straight to `/home`
/// instead of walking through the 21-screen onboarding again.
final ValueNotifier<bool> isOnboardedNotifier = ValueNotifier<bool>(false);
