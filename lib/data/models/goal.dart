import '../schema.dart';
import '_json_list.dart';

class Goal {
  const Goal({
    this.userId = 1,
    this.bodyType,
    this.priorityMuscles = const [],
    this.rewardStyle,
    this.weightDirection,
    this.targetWeightKg,
    required this.updatedAt,
  });

  final int userId;
  final String? bodyType;
  final List<String> priorityMuscles;
  final String? rewardStyle;
  final String? weightDirection;
  final double? targetWeightKg;
  final int updatedAt;

  factory Goal.fromRow(Map<String, Object?> r) => Goal(
        userId: r[CGoals.userId] as int,
        bodyType: r[CGoals.bodyType] as String?,
        priorityMuscles: decodeStringList(r[CGoals.priorityMuscles]),
        rewardStyle: r[CGoals.rewardStyle] as String?,
        weightDirection: r[CGoals.weightDirection] as String?,
        targetWeightKg: (r[CGoals.targetWeightKg] as num?)?.toDouble(),
        updatedAt: r[CGoals.updatedAt] as int,
      );

  Map<String, Object?> toRow() => {
        CGoals.userId: userId,
        CGoals.bodyType: bodyType,
        CGoals.priorityMuscles: encodeStringList(priorityMuscles),
        CGoals.rewardStyle: rewardStyle,
        CGoals.weightDirection: weightDirection,
        CGoals.targetWeightKg: targetWeightKg,
        CGoals.updatedAt: updatedAt,
      };

  Goal copyWith({
    String? bodyType,
    List<String>? priorityMuscles,
    String? rewardStyle,
    String? weightDirection,
    double? targetWeightKg,
    int? updatedAt,
  }) =>
      Goal(
        userId: userId,
        bodyType: bodyType ?? this.bodyType,
        priorityMuscles: priorityMuscles ?? this.priorityMuscles,
        rewardStyle: rewardStyle ?? this.rewardStyle,
        weightDirection: weightDirection ?? this.weightDirection,
        targetWeightKg: targetWeightKg ?? this.targetWeightKg,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
