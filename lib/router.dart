import 'package:go_router/go_router.dart';

import 'screens/attributes_screen.dart';
import 'screens/boss_detail_screen.dart';
import 'screens/calibrating_screen.dart';
import 'screens/experience_screen.dart';
import 'screens/home_screen.dart';
import 'screens/level_up_screen.dart';
import 'screens/objectives_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/quests_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/streak_milestone_screen.dart';
import 'screens/streak_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/workout_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, _) => const WelcomeScreen()),
    GoRoute(path: '/register', builder: (_, _) => const RegistrationScreen()),
    GoRoute(
      path: '/calibrating',
      builder: (ctx, _) => CalibratingScreen(
        onDone: () => ctx.go('/objectives'),
      ),
    ),
    GoRoute(path: '/objectives', builder: (_, _) => const ObjectivesScreen()),
    GoRoute(path: '/experience', builder: (_, _) => const ExperienceScreen()),
    GoRoute(path: '/attributes', builder: (_, _) => const AttributesScreen()),
    GoRoute(
      path: '/loader-pre-home',
      builder: (ctx, _) => CalibratingScreen(
        onDone: () => ctx.go('/home'),
      ),
    ),
    GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
    GoRoute(path: '/workout', builder: (_, _) => const WorkoutScreen()),
    GoRoute(path: '/quests', builder: (_, _) => const QuestsScreen()),
    GoRoute(path: '/boss-detail', builder: (_, _) => const BossDetailScreen()),
    GoRoute(path: '/streak', builder: (_, _) => const StreakScreen()),
    GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
    GoRoute(path: '/level-up', builder: (_, _) => const LevelUpScreen()),
    GoRoute(
      path: '/streak-milestone',
      builder: (_, _) => const StreakMilestoneScreen(),
    ),
  ],
);
