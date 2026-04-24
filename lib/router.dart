import 'package:go_router/go_router.dart';

import 'screens/age_screen.dart';
import 'state/onboarding_flag.dart';
import 'screens/body_fat_screen.dart';
import 'screens/body_type_screen.dart';
import 'screens/boss_detail_screen.dart';
import 'screens/calibrating_screen.dart';
import 'screens/challenge_system_screen.dart';
import 'screens/equipment_screen.dart';
import 'screens/exercise_picker_screen.dart';
import 'screens/height_screen.dart';
import 'screens/home_screen.dart';
import 'screens/level_up_screen.dart';
import 'screens/limitations_screen.dart';
import 'screens/notification_prefs_screen.dart';
import 'screens/paywall_screen.dart';
import 'screens/priority_muscles_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/progression_hype_screen.dart';
import 'screens/quests_screen.dart';
import 'screens/ranks_hype_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/reward_style_screen.dart';
import 'screens/session_minutes_screen.dart';
import 'screens/streak_milestone_screen.dart';
import 'screens/streak_screen.dart';
import 'screens/target_weight_screen.dart';
import 'screens/todays_workout_screen.dart';
import 'screens/tenure_screen.dart';
import 'screens/training_days_screen.dart';
import 'screens/training_styles_screen.dart';
import 'screens/weight_direction_screen.dart';
import 'screens/weight_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/workout_detail_screen.dart';
import 'screens/workout_history_screen.dart';
import 'screens/workout_screen.dart';

/// Full PRD §8 onboarding flow:
///
///   /  → /hype/ranks → /hype/progression
///   → /register → /age → /height                       (Section 1 — teal)
///   → /calibrating/1
///   → /body-type → /priority-muscles → /reward-style   (Section 2 — purple)
///   → /calibrating/2
///   → /tenure → /equipment → /limitations → /training-styles  (Section 3 — yellow)
///   → /calibrating/3
///   → /weight → /weight-direction → /target-weight → /body-fat  (Section 4 — teal)
///   → /calibrating/4
///   → /training-days → /session-minutes                (Section 5 — green)
///   → /calibrating/5
///   → /notification-prefs                              (Section 6 — white)
///   → /calibrating/6
///   → /challenge-system → /paywall                     (outro)
///   → /loader-pre-home → /home
final appRouter = GoRouter(
  initialLocation: '/',
  // When [isOnboardedNotifier] flips, re-evaluate redirects so the Home
  // screen's completion trigger also kicks returning users forward.
  refreshListenable: isOnboardedNotifier,
  redirect: (context, state) {
    // If the player has already finished onboarding, skip the Welcome →
    // hype → quiz flow and land them straight on Home. Other routes stay
    // reachable (so "Edit onboarding" in Settings can still deep-link
    // into specific screens later).
    if (!isOnboardedNotifier.value) return null;
    if (state.matchedLocation == '/') return '/home';
    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (_, _) => const WelcomeScreen()),

    // Pre-quiz hype
    GoRoute(path: '/hype/ranks', builder: (_, _) => const RanksHypeScreen()),
    GoRoute(
      path: '/hype/progression',
      builder: (_, _) => const ProgressionHypeScreen(),
    ),

    // Section 1 — Player Registration
    GoRoute(path: '/register', builder: (_, _) => const RegistrationScreen()),
    GoRoute(path: '/age', builder: (_, _) => const AgeScreen()),
    GoRoute(path: '/height', builder: (_, _) => const HeightScreen()),

    // Section 2 — Mission Objectives
    GoRoute(path: '/body-type', builder: (_, _) => const BodyTypeScreen()),
    GoRoute(
      path: '/priority-muscles',
      builder: (_, _) => const PriorityMusclesScreen(),
    ),
    GoRoute(
      path: '/reward-style',
      builder: (_, _) => const RewardStyleScreen(),
    ),

    // Section 3 — Combat Experience
    GoRoute(path: '/tenure', builder: (_, _) => const TenureScreen()),
    GoRoute(path: '/equipment', builder: (_, _) => const EquipmentScreen()),
    GoRoute(
      path: '/limitations',
      builder: (_, _) => const LimitationsScreen(),
    ),
    GoRoute(
      path: '/training-styles',
      builder: (_, _) => const TrainingStylesScreen(),
    ),

    // Section 4 — Physical Attributes
    GoRoute(path: '/weight', builder: (_, _) => const WeightScreen()),
    GoRoute(
      path: '/weight-direction',
      builder: (_, _) => const WeightDirectionScreen(),
    ),
    GoRoute(
      path: '/target-weight',
      builder: (_, _) => const TargetWeightScreen(),
    ),
    GoRoute(path: '/body-fat', builder: (_, _) => const BodyFatScreen()),

    // Section 5 — Daily Operations
    GoRoute(
      path: '/training-days',
      builder: (_, _) => const TrainingDaysScreen(),
    ),
    GoRoute(
      path: '/session-minutes',
      builder: (_, _) => const SessionMinutesScreen(),
    ),

    // Section 6 — System Settings
    GoRoute(
      path: '/notification-prefs',
      builder: (_, _) => const NotificationPrefsScreen(),
    ),

    // Calibrating interstitials (one per section boundary, PRD §8).
    GoRoute(
      path: '/calibrating/1',
      builder: (ctx, _) =>
          CalibratingScreen(onDone: () => ctx.go('/body-type')),
    ),
    GoRoute(
      path: '/calibrating/2',
      builder: (ctx, _) => CalibratingScreen(onDone: () => ctx.go('/tenure')),
    ),
    GoRoute(
      path: '/calibrating/3',
      builder: (ctx, _) => CalibratingScreen(onDone: () => ctx.go('/weight')),
    ),
    GoRoute(
      path: '/calibrating/4',
      builder: (ctx, _) =>
          CalibratingScreen(onDone: () => ctx.go('/training-days')),
    ),
    GoRoute(
      path: '/calibrating/5',
      builder: (ctx, _) =>
          CalibratingScreen(onDone: () => ctx.go('/notification-prefs')),
    ),
    GoRoute(
      path: '/calibrating/6',
      builder: (ctx, _) =>
          CalibratingScreen(onDone: () => ctx.go('/challenge-system')),
    ),

    // Outro — monetization
    GoRoute(
      path: '/challenge-system',
      builder: (_, _) => const ChallengeSystemScreen(),
    ),
    GoRoute(path: '/paywall', builder: (_, _) => const PaywallScreen()),

    // Final calibrating before Home (after paywall decision).
    GoRoute(
      path: '/loader-pre-home',
      builder: (ctx, _) => CalibratingScreen(onDone: () => ctx.go('/home')),
    ),

    // In-app tabs + post-onboarding
    GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
    GoRoute(
      path: '/home/todays-workout',
      builder: (_, _) => const TodaysWorkoutScreen(),
    ),
    GoRoute(
      path: '/exercise-picker',
      builder: (_, _) => const ExercisePickerScreen(),
    ),
    GoRoute(
      path: '/workout/new/:exerciseId',
      builder: (ctx, state) {
        final queueParam = state.uri.queryParameters['queue'];
        final queue = (queueParam == null || queueParam.isEmpty)
            ? const <int>[]
            : queueParam
                .split(',')
                .map((s) => int.tryParse(s))
                .whereType<int>()
                .toList();
        return WorkoutScreen(
          exerciseId: int.parse(state.pathParameters['exerciseId']!),
          queue: queue,
        );
      },
    ),
    GoRoute(
      path: '/workouts',
      builder: (_, _) => const WorkoutHistoryScreen(),
    ),
    GoRoute(
      path: '/workouts/:id',
      builder: (ctx, state) => WorkoutDetailScreen(
        workoutId: int.parse(state.pathParameters['id']!),
      ),
    ),
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
