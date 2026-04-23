import '../schema.dart';

class Workout {
  const Workout({
    this.id,
    this.userId = 1,
    required this.startedAt,
    this.endedAt,
    this.xpEarned = 0,
    this.volumeKg = 0,
    this.note,
  });

  final int? id;
  final int userId;
  final int startedAt;
  final int? endedAt;
  final int xpEarned;
  final double volumeKg;
  final String? note;

  bool get isFinished => endedAt != null;

  Duration get duration =>
      Duration(seconds: (endedAt ?? startedAt) - startedAt);

  factory Workout.fromRow(Map<String, Object?> r) => Workout(
        id: r[CWorkout.id] as int?,
        userId: r[CWorkout.userId] as int,
        startedAt: r[CWorkout.startedAt] as int,
        endedAt: r[CWorkout.endedAt] as int?,
        xpEarned: r[CWorkout.xpEarned] as int? ?? 0,
        volumeKg: (r[CWorkout.volumeKg] as num?)?.toDouble() ?? 0,
        note: r[CWorkout.note] as String?,
      );

  Map<String, Object?> toRow() => {
        if (id != null) CWorkout.id: id,
        CWorkout.userId: userId,
        CWorkout.startedAt: startedAt,
        CWorkout.endedAt: endedAt,
        CWorkout.xpEarned: xpEarned,
        CWorkout.volumeKg: volumeKg,
        CWorkout.note: note,
      };
}
