import 'dart:async';

import 'package:flutter/widgets.dart';

import 'sync_engine.dart';

/// App-lifecycle glue for [SyncEngine].
///
/// Two triggers:
///   • App foreground (`AppLifecycleState.resumed`) — drain immediately
///     so a user who logged a workout offline sees it pushed the moment
///     they reopen the app on Wi-Fi.
///   • Periodic timer (default 30s) while the app is foregrounded —
///     catches rows enqueued *during* the session and retries any
///     backed-off rows whose window has elapsed.
///
/// The engine itself short-circuits when:
///   • not authenticated → [SyncEngine.drainOnce] returns
///     `skippedNoAuth`.
///   • another drain is already running → returns
///     `skippedAlreadyRunning`.
/// So this lifecycle hook can fire freely without coordination logic.
class SyncLifecycle with WidgetsBindingObserver {
  SyncLifecycle({
    required this.engine,
    this.foregroundInterval = const Duration(seconds: 30),
  });

  final SyncEngine engine;
  final Duration foregroundInterval;

  Timer? _timer;
  bool _attached = false;

  /// Register the lifecycle observer + start the periodic timer + run
  /// one drain immediately. Idempotent — double-attach is a no-op.
  void attach() {
    if (_attached) return;
    _attached = true;
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
    // Kick off an initial drain — covers the case where the app was
    // killed mid-session and just relaunched. Don't await — caller is
    // typically `main()` which doesn't want to block on Supabase.
    unawaited(engine.drainOnce());
  }

  /// Tear down (tests, sign-out flow, app shutdown).
  void detach() {
    if (!_attached) return;
    _attached = false;
    WidgetsBinding.instance.removeObserver(this);
    _stopTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Foregrounded — drain now and (re)start the periodic timer.
      _startTimer();
      unawaited(engine.drainOnce());
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      // Backgrounded — pause the timer to avoid burning battery and
      // racing with iOS / Android suspension.
      _stopTimer();
    }
  }

  void _startTimer() {
    _stopTimer();
    _timer = Timer.periodic(foregroundInterval, (_) {
      unawaited(engine.drainOnce());
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }
}
