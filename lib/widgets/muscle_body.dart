import 'package:flutter/material.dart';

/// Which side of the body a muscle's panel lives on. Used by callers
/// (workout_complete) that render front + back views side-by-side and
/// need to pick the dominant muscle on each side independently.
enum BodyView { front, back }

/// Polished single-muscle highlight image.
///
/// The art pack ships one fully-rendered body PNG per tracked muscle —
/// chest, shoulders, biceps, core, quads (front view) and back, traps,
/// triceps, glutes, hamstrings+calves (back view). Each panel paints
/// the entire body in neutral gray with the target muscle group lit
/// purple. Picking the right panel for the active muscle is the entire
/// "highlight" implementation — there's no compositing or runtime
/// tinting.
///
/// Caller pattern:
///
/// ```dart
/// // Workout Complete — show the dominant muscle's panel.
/// MuscleBody(muscle: bundle.muscleSplit.first.muscle)
///
/// // Muscle Detail — show the tapped muscle's panel.
/// MuscleBody(muscle: widget.muscle)
/// ```
///
/// `null` or unrecognised muscle keys fall back to the chest panel so
/// the screen never renders a blank box.
class MuscleBody extends StatelessWidget {
  const MuscleBody({super.key, required this.muscle, this.fit = BoxFit.contain});

  final String? muscle;
  final BoxFit fit;

  /// Maps the canonical muscle name (matches `RankEngine.trackedMuscles`)
  /// to the polished panel asset that highlights it. `hamstrings` and
  /// `calves` share `panel_1_4` because the artist shipped a single
  /// lower-leg panel that highlights both groups together.
  static const Map<String, String> _panels = {
    'chest':      'assets/muscle_images/panel_0_0.jpeg',
    'shoulders':  'assets/muscle_images/panel_0_1.jpeg',
    'biceps':     'assets/muscle_images/panel_0_2.jpeg',
    'core':       'assets/muscle_images/panel_0_3.jpeg',
    'quads':      'assets/muscle_images/panel_0_4.jpeg',
    'back':       'assets/muscle_images/panel_1_0.jpeg',
    'traps':      'assets/muscle_images/panel_1_1.jpeg',
    'triceps':    'assets/muscle_images/panel_1_2.jpeg',
    'glutes':     'assets/muscle_images/panel_1_3.jpeg',
    'hamstrings': 'assets/muscle_images/panel_1_4.jpeg',
    'calves':     'assets/muscle_images/panel_1_4.jpeg',
  };

  static const String _fallback = 'assets/muscle_images/panel_0_0.jpeg';

  /// Which body view a given muscle's panel lives on. Lets callers that
  /// render front+back side-by-side pick a different dominant muscle
  /// per side.
  static BodyView viewFor(String muscle) {
    const back = {'back', 'traps', 'triceps', 'glutes', 'hamstrings', 'calves'};
    return back.contains(muscle) ? BodyView.back : BodyView.front;
  }

  /// Whether we have a panel for [muscle]. Useful for picking a
  /// dominant muscle that's actually renderable.
  static bool has(String? muscle) =>
      muscle != null && _panels.containsKey(muscle);

  @override
  Widget build(BuildContext context) {
    final asset = _panels[muscle] ?? _fallback;
    return Image.asset(asset, fit: fit);
  }
}
