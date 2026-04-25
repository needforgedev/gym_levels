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

  /// ISO-week ordinal for the current local date. Used as a rotation offset
  /// so the same weekday in different weeks picks different compounds from
  /// the candidate pool (stable within a day, varied across weeks).
  static int _weekOrdinal() {
    final now = DateTime.now();
    final jan1 = DateTime(now.year, 1, 1);
    return ((now.difference(jan1).inDays) / 7).floor();
  }

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

  /// Human-readable headline. Matches design v2 sample copy
  /// (`design/v2/shared.jsx` USER.nextWorkout.title) — push/pull/legs get
  /// a "DAY" suffix, upper/lower/full keep the "BODY" suffix.
  static String _focusLabel(String focus) {
    switch (focus) {
      case 'push':
        return 'PUSH DAY';
      case 'pull':
        return 'PULL DAY';
      case 'legs':
        return 'LEG DAY';
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

  /// The public entry point. Always returns a `SessionPlan` as long as the
  /// user has at least one scheduled training day — on non-scheduled days
  /// the returned plan has `isScheduled: false` and its focus is the next
  /// upcoming scheduled day's focus (so users get a useful preview /
  /// "optional training" session instead of an empty Home).
  ///
  /// Returns `null` only when no schedule has been set at all (onboarding
  /// wasn't finished). Callers render a "set your training days" empty
  /// state in that case.
  static Future<SessionPlan?> todaysSession() async {
    final schedule = await ScheduleService.get();
    if (schedule == null || schedule.days.isEmpty) return null;

    final today = _todayIndex();
    final sortedDays = [...schedule.days]..sort();
    final isScheduled = sortedDays.contains(today);

    // Pick the bucket position. On a scheduled day, use today's index in the
    // sorted list; on a rest day, use the next upcoming scheduled day
    // (wraps to index 0 if today is after the last scheduled day of the
    // week) — gives the user a preview of what's coming.
    final int dayPos;
    if (isScheduled) {
      dayPos = sortedDays.indexOf(today);
    } else {
      final upcoming = sortedDays.indexWhere((d) => d > today);
      dayPos = upcoming >= 0 ? upcoming : 0;
    }

    final splitBucket = _splitByDays[sortedDays.length] ??
        List<String>.filled(sortedDays.length, 'full');
    final focus = splitBucket[dayPos % splitBucket.length];

    final goals = await GoalsService.get();
    final experience = await ExperienceService.get();
    final owned = Set<String>.from(experience?.equipment ?? const []);
    final avoid = _avoidedMuscles(experience?.limitations ?? const []);
    final priority = goals?.priorityMuscles ?? const <String>[];

    // Pull the catalog once; filter in Dart (80 rows — trivially cheap).
    final catalog = await ExerciseService.getAll();
    final focusMuscles = _muscleGroupsByFocus[focus] ?? const ['chest'];

    // Reorder muscles: any muscle the user flagged as a priority leads the
    // list so it always gets a compound slot, even if we later hit the
    // session-length cap.
    final muscles = <String>[
      ...focusMuscles.where(priority.contains),
      ...focusMuscles.where((m) => !priority.contains(m)),
    ];

    final picks = <PlannedExercise>[];
    final (sets, reps) = _setsReps(goals?.bodyType);
    final usedIds = <int>{};
    final rotation = _weekOrdinal();

    for (final m in muscles) {
      if (avoid.contains(m)) continue;

      final allCandidates = catalog
          .where((e) =>
              e.primaryMuscle == m &&
              _equipmentOk(e, owned) &&
              e.id != null &&
              !usedIds.contains(e.id!))
          .toList();
      if (allCandidates.isEmpty) continue;

      // Week-based rotation so the same weekday picks different compounds
      // across weeks (e.g. Push Monday alternates Bench → Incline → DB
      // Press → …). Stable within a single day because `rotation` is
      // week-keyed.
      final offset = rotation % allCandidates.length;
      final candidates = [
        ...allCandidates.skip(offset),
        ...allCandidates.take(offset),
      ];

      final isPriority = priority.contains(m);

      // Prefer 1 compound (baseXp >= 5) per muscle; fall back to the first
      // available exercise for that muscle (bodyweight-only setups often
      // have no compound rated ≥5 but we still want a prescription).
      final compound = candidates.firstWhere(
        (e) => e.baseXp >= 5,
        orElse: () => candidates.first,
      );
      picks.add(PlannedExercise(
        exerciseId: compound.id!,
        name: compound.name,
        sets: isPriority ? sets + 1 : sets,
        reps: reps,
        isPriority: isPriority,
      ));
      usedIds.add(compound.id!);

      // Accessory: always added for priority muscles (extra volume where
      // the user asked for it). For non-priority muscles, only on smaller
      // muscle groups so we don't blow the session-length cap.
      if (isPriority || muscles.length <= 3) {
        final accessory = candidates.firstWhere(
          (e) => e.id != compound.id && !usedIds.contains(e.id!),
          orElse: () => Exercise(name: '', primaryMuscle: ''),
        );
        if (accessory.id != null) {
          picks.add(PlannedExercise(
            exerciseId: accessory.id!,
            name: accessory.name,
            sets: sets,
            reps: reps + 2, // accessories get 2 more reps
            isPriority: isPriority,
          ));
          usedIds.add(accessory.id!);
        }
      }
    }

    // If today's focus doesn't overlap with the user's priority muscles at
    // all, append one bonus priority exercise — users flagged those muscles
    // because they want them hit *every* session.
    if (priority.isNotEmpty &&
        !focusMuscles.any(priority.contains) &&
        picks.isNotEmpty) {
      for (final pm in priority) {
        if (avoid.contains(pm)) continue;
        final bonus = catalog.firstWhere(
          (e) =>
              e.primaryMuscle == pm &&
              _equipmentOk(e, owned) &&
              e.id != null &&
              !usedIds.contains(e.id!),
          orElse: () => Exercise(name: '', primaryMuscle: ''),
        );
        if (bonus.id != null) {
          picks.add(PlannedExercise(
            exerciseId: bonus.id!,
            name: bonus.name,
            sets: sets,
            reps: reps + 2,
            isPriority: true,
          ));
          usedIds.add(bonus.id!);
          break;
        }
      }
    }

    // Cap at the user's preferred session length. Rough rule: ~6 min / exercise.
    final minutes = schedule.sessionMinutes ?? 45;
    final cap = (minutes / 6).floor().clamp(4, 8);
    final clipped = picks.take(cap).toList();

    // Always return a SessionPlan when the user has a schedule — even if no
    // catalog exercises survived the filter. Callers use `exercises.isEmpty`
    // to render a "no equipment matches" state, distinct from "no schedule
    // at all" (which is the only case that returns null).
    return SessionPlan(
      focus: _focusLabel(focus),
      exercises: clipped,
      estimatedMinutes: minutes,
      isScheduled: isScheduled,
      daysPerWeek: sortedDays.length,
      bodyType: goals?.bodyType,
      priorityMuscles: priority,
      ownedEquipment: experience?.equipment ?? const [],
    );
  }
}

class SessionPlan {
  const SessionPlan({
    required this.focus,
    required this.exercises,
    required this.estimatedMinutes,
    this.isScheduled = true,
    this.daysPerWeek = 0,
    this.bodyType,
    this.priorityMuscles = const [],
    this.ownedEquipment = const [],
  });

  final String focus;
  final List<PlannedExercise> exercises;
  final int estimatedMinutes;

  /// `true` when today's weekday is in `schedule.days`; `false` means this
  /// plan is an **optional** suggestion (user is off-schedule but we're
  /// still happy to show the next upcoming session).
  final bool isScheduled;

  // Inputs that drove the plan — surfaced on the UI so the user can see
  // which profile settings produced this prescription.
  final int daysPerWeek;
  final String? bodyType;
  final List<String> priorityMuscles;
  final List<String> ownedEquipment;
}

class PlannedExercise {
  const PlannedExercise({
    required this.exerciseId,
    required this.name,
    required this.sets,
    required this.reps,
    this.isPriority = false,
  });

  final int exerciseId;
  final String name;
  final int sets;
  final int reps;

  /// True when the exercise hits one of the user's priority muscles from
  /// onboarding (or was added as the "bonus priority" pick when today's
  /// focus didn't overlap). Drives the PRIORITY tag on Today's Workout.
  final bool isPriority;
}
