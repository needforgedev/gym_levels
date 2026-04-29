import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'data/app_db.dart';
import 'data/services/player_service.dart';
import 'data/supabase/supabase_client.dart';
import 'router.dart';
import 'state/onboarding_flag.dart';
import 'state/player_state.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );
  // Open the offline-first SQLite database. PRD §11.1 — source of truth
  // for every read on the device. Supabase is a separate, opt-in mirror
  // for socials + Scope B sync (see socials_plan.md).
  await AppDb.init();

  // Initialize Supabase (auth + Scope B sync backend) if `.env` is
  // present. Safe to call when `.env` is missing — degrades to
  // anonymous offline-only mode without throwing.
  await SupabaseConfig.initialize();

  // Decide whether to resume at /home or start from Welcome. Read once,
  // synchronously before first paint, so the router's `redirect` has the
  // right answer on the very first navigation decision.
  final player = await PlayerService.getPlayer();
  isOnboardedNotifier.value = player?.isOnboarded ?? false;

  runApp(const LevelUpApp());
}

class LevelUpApp extends StatelessWidget {
  const LevelUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PlayerState>(
      // `..refresh()` kicks off a one-shot read from PlayerService so the
      // cache populates without blocking the first paint.
      create: (_) => PlayerState()..refresh(),
      child: MaterialApp.router(
        title: 'Level Up IRL',
        theme: AppTheme.dark(),
        debugShowCheckedModeBanner: false,
        routerConfig: appRouter,
      ),
    );
  }
}
