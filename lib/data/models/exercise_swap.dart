import '../schema.dart';

class ExerciseSwap {
  const ExerciseSwap({
    this.id,
    this.userId = 1,
    required this.originalExerciseId,
    required this.swappedToId,
    this.workoutId,
    this.reason,
    required this.createdAt,
  });

  final int? id;
  final int userId;
  final int originalExerciseId;
  final int swappedToId;
  final int? workoutId;
  final String? reason;
  final int createdAt;

  factory ExerciseSwap.fromRow(Map<String, Object?> r) => ExerciseSwap(
        id: r[CExerciseSwap.id] as int?,
        userId: r[CExerciseSwap.userId] as int,
        originalExerciseId: r[CExerciseSwap.originalExerciseId] as int,
        swappedToId: r[CExerciseSwap.swappedToId] as int,
        workoutId: r[CExerciseSwap.workoutId] as int?,
        reason: r[CExerciseSwap.reason] as String?,
        createdAt: r[CExerciseSwap.createdAt] as int,
      );

  Map<String, Object?> toRow() => {
        if (id != null) CExerciseSwap.id: id,
        CExerciseSwap.userId: userId,
        CExerciseSwap.originalExerciseId: originalExerciseId,
        CExerciseSwap.swappedToId: swappedToId,
        CExerciseSwap.workoutId: workoutId,
        CExerciseSwap.reason: reason,
        CExerciseSwap.createdAt: createdAt,
      };
}
