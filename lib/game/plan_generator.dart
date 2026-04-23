import '../data/models/exercise.dart';
import '../data/services/exercise_service.dart';
import '../data/services/experience_service.dart';
import '../data/services/goals_service.dart';
import '../data/services/schedule_service.dart';

/// PRD Appendix B — plan generator (v1 MVP).
///
/// Scope today: given the user's schedule (training days), goals (body type),
/// and experience (equipment + limitations), compute **today's suggested
/// session**. Not the full weekly plan, not the 4-week periodization curve —
/// that lands with the paid-tier "Custom plan regeneration" in Phase 3.6.
///
/// Return value:
/// - `SessionPlan` if today is a scheduled training day
/// - `null` if it's a rest day (no session prescribed)
class PlanGenerator {
  PlanGenerator._();

  /// Day indexes: Mon = 0 … Sun = 6, matching PRD §8 Screen 17 encoding.
  static int _todayIndex() => (DateTime.now().weekday - 1) % 7;

  /// Split buckets by training days per week. Each bucket lists per-session
  /// focus tags; the caller maps today's position within the user's sorted
  /// training days to pick the right bucket.
  static const Map<int, List<String>> _splitByDays = {
    2: ['full', 'full'],
    3: ['push', 'pull', 'legs'],
    4: ['upper', 'lower', 'upper', 'lower'],
    5: ['push', 'pull', 'legs', 'upper', 'lower'],
    6: ['push', 'pull', 'legs', 'push', 'pull', 'legs'],
    7: ['push', 'pull', 'legs', 'upper', 'lower', 'push', 'full'],
  };

  /// Muscle groups that belong to each focus.
  static const Map<String, List<String>> _muscleGroupsByFocus = {
    'push': ['chest', 'shoulders', 'triceps'],
    'pull': ['back', 'biceps'],
    'legs': ['quads', 'hamstrings', 'glutes', 'calves'],
    'upper': ['chest', 'back', 'shoulders', 'biceps', 'triceps'],
    'lower': ['quads', 'hamstrings', 'glutes', 'calves'],
    'full': [
      'chest',
      'back',
      'shoulders',
      'quads',
      'hamstrings',
      'glutes',
      'core',
    ],
  };

  /// Human-readable headline. Used by Today's Workout chip-row.
  static String _focusLabel(String focus) {
    switch (focus) {
      case 'push':
        return 'PUSH';
      case 'pull':
        return 'PULL';
      case 'legs':
        return 'LEGS';
      case 'upper':
        return 'UPPER BODY';
      case 'lower':
        return 'LOWER BODY';
      case 'full':
        return 'FULL BODY';
      default:
        return focus.toUpperCase();
    }
  }

  /// Prescribed sets × reps mapped off `goals.body_type` — loose mapping of
  /// the PRD's hypertrophy/strength/endurance mix.
  static (int sets, int reps) _setsReps(String? bodyType) {
    switch (bodyType) {
      case 'lean':
        return (3, 12); // endurance-lean
      case 'muscular':
        return (3, 10); // hypertrophy
      case 'strong':
        return (5, 5); // strength
      case 'balanced':
        return (3, 8); // balanced
      default:
        return (3, 10);
    }
  }

  /// True if every piece of equipment the exercise needs is owned by the
  /// user. An empty `equipment` list (or explicit "bodyweight") always
  /// passes.
  static bool _equipmentOk(Exercise e, Set<String> owned) {
    if (e.equipment.isEmpty) return true;
    for (final req in e.equipment) {
      if (req == 'bodyweight') continue; // always available
      if (!owned.contains(req)) return false;
    }
    return true;
  }

  /// Limitations → muscles we should avoid for the session. Minimal v1 map;
  /// expand as the catalog matures.
  static const Map<String, Set<String>> _limitationToAvoid = {
    'lower_back': {'back', 'hamstrings'},
    'knee': {'quads'},
    'shoulder': {'shoulders', 'chest'},
    'wrist_elbow': {'biceps', 'triceps'},
    'hip': {'glutes', 'hamstrings'},
    'neck': {'shoulders'},
  };

  static Set<String> _avoidedMuscles(List<String> limitations) {
    final out = <String>{};
    for (final l in limitations) {
      final mapped = _limitationToAvoid[l];
      if (mapped != null) out.addAll(mapped);
    }
    return out;
  }

  /// The public entry point. Returns a `SessionPlan` if today is a scheduled
  /// training day, `null` if it's a rest day or no schedule has been set.
  static Future<SessionPlan?> todaysSession() async {
    final schedule = await ScheduleService.get();
    if (schedule == null || schedule.days.isEmpty) return null;

    final today = _todayIndex();
    final sortedDays = [...schedule.days]..sort();
    if (!sortedDays.contains(today)) return null; // rest day

    final dayPos = sortedDays.indexOf(today);
    final splitBucket = _splitByDays[sortedDays.length] ??
        List<String>.filled(sortedDays.length, 'full');
    final focus = splitBucket[dayPos % splitBucket.length];

    final goals = await GoalsService.get();
    final experience = await ExperienceService.get();
    final owned = Set<String>.from(experience?.equipment ?? const []);
    final avoid = _avoidedMuscles(experience?.limitations ?? const []);

    // Pull the catalog once; filter in Dart (80 rows — trivially cheap).
    final catalog = await ExerciseService.getAll();
    final muscles = _muscleGroupsByFocus[focus] ?? const ['chest'];

    final picks = <PlannedExercise>[];
    final (sets, reps) = _setsReps(goals?.bodyType);
    final usedIds = <int>{};

    for (final m in muscles) {
      if (avoid.contains(m)) continue;

      final candidates = catalog.where((e) =>
          e.primaryMuscle == m &&
          _equipmentOk(e, owned) &&
          e.id != null &&
          !usedIds.contains(e.id!));

      // Prefer 1 compound (baseXp >= 5) per muscle when available.
      final compound = candidates.firstWhere(
        (e) => e.baseXp >= 5,
        orElse: () => Exercise(name: '', primaryMuscle: ''),
      );
      if (compound.id != null) {
        picks.add(PlannedExercise(
          exerciseId: compound.id!,
          name: compound.name,
          sets: sets,
          reps: reps,
        ));
        usedIds.add(compound.id!);
      }

      // One accessory to round out big muscle groups.
      if (muscles.length <= 3) {
        final accessory = candidates.firstWhere(
          (e) => e.baseXp < 5 && !usedIds.contains(e.id!),
          orElse: () => Exercise(name: '', primaryMuscle: ''),
        );
        if (accessory.id != null) {
          picks.add(PlannedExercise(
            exerciseId: accessory.id!,
            name: accessory.name,
            sets: sets,
            reps: reps + 2, // accessories get 2 more reps
          ));
          usedIds.add(accessory.id!);
        }
      }
    }

    // Cap at the user's preferred session length. Rough rule: ~6 min / exercise.
    final minutes = schedule.sessionMinutes ?? 45;
    final cap = (minutes / 6).floor().clamp(4, 8);
    final clipped = picks.take(cap).toList();

    if (clipped.isEmpty) return null;

    return SessionPlan(
      focus: _focusLabel(focus),
      exercises: clipped,
      estimatedMinutes: minutes,
    );
  }
}

class SessionPlan {
  const SessionPlan({
    required this.focus,
    required this.exercises,
    required this.estimatedMinutes,
  });

  final String focus;
  final List<PlannedExercise> exercises;
  final int estimatedMinutes;
}

class PlannedExercise {
  const PlannedExercise({
    required this.exerciseId,
    required this.name,
    required this.sets,
    required this.reps,
  });

  final int exerciseId;
  final String name;
  final int sets;
  final int reps;
}
