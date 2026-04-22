import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'router.dart';
import 'state/player_state.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );
  runApp(const LevelUpApp());
}

class LevelUpApp extends StatelessWidget {
  const LevelUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PlayerState>(
      create: (_) => PlayerState(),
      child: MaterialApp.router(
        title: 'Level Up IRL',
        theme: AppTheme.dark(),
        debugShowCheckedModeBanner: false,
        routerConfig: appRouter,
      ),
    );
  }
}
