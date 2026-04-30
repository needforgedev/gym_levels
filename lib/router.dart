import 'package:go_router/go_router.dart';

import 'screens/age_screen.dart';
import 'state/onboarding_flag.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/phone_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/auth/sign_up_screen.dart';
import 'screens/auth/username_screen.dart';
import 'screens/auth/verify_email_screen.dart';
import 'screens/auth/contacts_permission_screen.dart';
import 'screens/auth/friends_found_screen.dart';
import 'screens/auth/welcome_back_screen.dart';
import 'screens/friends/friends_screen.dart';
import 'screens/friends/username_search_screen.dart';
import 'screens/leaderboard/leaderboard_screen.dart';
import 'screens/body_fat_screen.dart';
import 'screens/body_type_screen.dart';
import 'screens/boss_completion_screen.dart';
import 'screens/boss_detail_screen.dart';
import 'screens/calibrating_screen.dart';
import 'screens/challenge_system_screen.dart';
import 'screens/equipment_screen.dart';
import 'screens/exercise_picker_screen.dart';
import 'screens/height_screen.dart';
import 'screens/home_screen.dart';
import 'screens/level_up_screen.dart';
import 'screens/limitations_screen.dart';
import 'screens/muscle_detail_screen.dart';
import 'screens/notification_prefs_screen.dart';
import 'screens/paywall_screen.dart';
import 'screens/priority_muscles_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/progression_hype_screen.dart';
import 'screens/quests_screen.dart';
import 'screens/ranks_hype_screen.dart';
import 'screens/ranks_screen.dart';
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
import 'screens/weight_tracker_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/workout_complete_screen.dart';
import 'screens/workout_detail_screen.dart';
import 'screens/workout_history_screen.dart';
import 'screens/workout_screen.dart';
import 'package:flutter/widgets.dart';

import 'data/models/quest.dart';
import 'game/game_handlers.dart';
import 'game/quest_engine.dart';

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

    // Auth (Phase 4.1a S1) — pre-onboarding gate. Sign Up at install
    // (Path A) per socials_plan.md §6. /signin available from the
    // sign-up screen for users on a new device.
    GoRoute(path: '/signup', builder: (_, _) => const SignUpScreen()),
    GoRoute(path: '/signin', builder: (_, _) => const SignInScreen()),
    GoRoute(
      path: '/verify-email',
      builder: (_, _) => const VerifyEmailScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (_, _) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/reset-password',
      builder: (_, _) => const ResetPasswordScreen(),
    ),
    // S3b — initial-sync hydration after sign-in on a fresh install.
    GoRoute(
      path: '/welcome-back',
      builder: (_, _) => const WelcomeBackScreen(),
    ),

    // S4 — contact-match. Inserted between /loader-pre-home and /home
    // so fresh sign-ups land on it once at end of onboarding. Will
    // also be reachable from Settings → "Find friends" in S7.
    GoRoute(
      path: '/contacts-permission',
      builder: (_, _) => const ContactsPermissionScreen(),
    ),
    GoRoute(
      path: '/friends-found',
      builder: (ctx, state) {
        final extra = state.extra;
        if (extra is FriendsFoundArgs) {
          return FriendsFoundScreen(args: extra);
        }
        // Deep-link / hot-restart with no payload — bounce home.
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => ctx.go('/home'),
        );
        return const SizedBox.shrink();
      },
    ),

    // S5 — friend graph hub + username search.
    GoRoute(
      path: '/friends',
      builder: (_, _) => const FriendsScreen(),
    ),
    GoRoute(
      path: '/friends/search',
      builder: (_, _) => const UsernameSearchScreen(),
    ),

    // S6 — friend-only leaderboard (3-tab metric switcher).
    GoRoute(
      path: '/leaderboard',
      builder: (_, _) => const LeaderboardScreen(),
    ),

    // Section 1 — Player Registration (display name → local sqflite)
    // followed by socials S2 (cloud handle + phone) before flowing into
    // the rest of the local-only onboarding chain.
    GoRoute(path: '/register', builder: (_, _) => const RegistrationScreen()),
    GoRoute(path: '/username', builder: (_, _) => const UsernameScreen()),
    GoRoute(path: '/phone', builder: (_, _) => const PhoneScreen()),
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

    // Final calibrating before Home (after paywall decision). Routes
    // through the S4 contact-match flow on the way — fresh sign-ups
    // see /contacts-permission once before landing on Home. Returning
    // users (already onboarded) get redirected to /home by the
    // top-level redirect, skipping the calibrating screen entirely.
    GoRoute(
      path: '/loader-pre-home',
      builder: (ctx, _) => CalibratingScreen(
        onDone: () => ctx.go('/contacts-permission'),
      ),
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
        justFinished: state.extra is SessionSummary
            ? state.extra as SessionSummary
            : null,
      ),
    ),
    GoRoute(
      path: '/workout-complete/:id',
      builder: (ctx, state) => WorkoutCompleteScreen(
        workoutId: int.parse(state.pathParameters['id']!),
        summary: state.extra is SessionSummary
            ? state.extra as SessionSummary
            : null,
      ),
    ),
    GoRoute(path: '/weight-tracker', builder: (_, _) => const WeightTrackerScreen()),
    GoRoute(path: '/ranks', builder: (_, _) => const RanksScreen()),
    GoRoute(
      path: '/ranks/:muscle',
      builder: (ctx, state) => MuscleDetailScreen(
        muscle: state.pathParameters['muscle']!,
      ),
    ),
    GoRoute(path: '/quests', builder: (_, _) => const QuestsScreen()),
    GoRoute(
      path: '/boss-detail',
      builder: (ctx, state) => BossDetailScreen(
        quest: state.extra is Quest ? state.extra as Quest : null,
      ),
    ),
    GoRoute(
      path: '/boss-complete',
      builder: (ctx, state) {
        final extra = state.extra;
        if (extra is! ({String title, int xp, BossBuff buff})) {
          // No payload (deep-link or hot-restart) — bounce to /quests.
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => ctx.go('/quests'),
          );
          return const SizedBox.shrink();
        }
        return BossCompletionScreen(
          title: extra.title,
          xpReward: extra.xp,
          buff: extra.buff,
        );
      },
    ),
    GoRoute(path: '/streak', builder: (_, _) => const StreakScreen()),
    GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
    GoRoute(path: '/level-up', builder: (_, _) => const LevelUpScreen()),
    GoRoute(
      path: '/streak-milestone',
      builder: (_, _) => const StreakMilestoneScreen(),
    ),
  ],
);
