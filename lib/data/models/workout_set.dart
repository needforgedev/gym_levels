import '../schema.dart';

/// `sets` row. Named `WorkoutSet` to avoid collision with `dart:core Set`.
class WorkoutSet {
  const WorkoutSet({
    this.id,
    required this.workoutId,
    required this.exerciseId,
    required this.setNumber,
    this.weightKg,
    required this.reps,
    this.rpe,
    this.isPr = false,
    this.xpEarned = 0,
    required this.completedAt,
  });

  final int? id;
  final int workoutId;
  final int exerciseId;
  final int setNumber;
  final double? weightKg;
  final int reps;
  final int? rpe;
  final bool isPr;
  final int xpEarned;
  final int completedAt;

  factory WorkoutSet.fromRow(Map<String, Object?> r) => WorkoutSet(
        id: r[CSet.id] as int?,
        workoutId: r[CSet.workoutId] as int,
        exerciseId: r[CSet.exerciseId] as int,
        setNumber: r[CSet.setNumber] as int,
        weightKg: (r[CSet.weightKg] as num?)?.toDouble(),
        reps: r[CSet.reps] as int,
        rpe: r[CSet.rpe] as int?,
        isPr: (r[CSet.isPr] as int? ?? 0) == 1,
        xpEarned: r[CSet.xpEarned] as int? ?? 0,
        completedAt: r[CSet.completedAt] as int,
      );

  Map<String, Object?> toRow() => {
        if (id != null) CSet.id: id,
        CSet.workoutId: workoutId,
        CSet.exerciseId: exerciseId,
        CSet.setNumber: setNumber,
        CSet.weightKg: weightKg,
        CSet.reps: reps,
        CSet.rpe: rpe,
        CSet.isPr: isPr ? 1 : 0,
        CSet.xpEarned: xpEarned,
        CSet.completedAt: completedAt,
      };
}
