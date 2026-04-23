import '../schema.dart';

class WorkoutOverride {
  const WorkoutOverride({
    this.id,
    this.userId = 1,
    required this.scheduledFor,
    required this.overridesJson,
    required this.createdAt,
  });

  final int? id;
  final int userId;
  final int scheduledFor;
  final String overridesJson;
  final int createdAt;

  factory WorkoutOverride.fromRow(Map<String, Object?> r) => WorkoutOverride(
        id: r[CWorkoutOverride.id] as int?,
        userId: r[CWorkoutOverride.userId] as int,
        scheduledFor: r[CWorkoutOverride.scheduledFor] as int,
        overridesJson: r[CWorkoutOverride.overridesJson] as String,
        createdAt: r[CWorkoutOverride.createdAt] as int,
      );

  Map<String, Object?> toRow() => {
        if (id != null) CWorkoutOverride.id: id,
        CWorkoutOverride.userId: userId,
        CWorkoutOverride.scheduledFor: scheduledFor,
        CWorkoutOverride.overridesJson: overridesJson,
        CWorkoutOverride.createdAt: createdAt,
      };
}
