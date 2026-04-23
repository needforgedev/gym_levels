import '../schema.dart';

class MuscleRank {
  const MuscleRank({
    this.userId = 1,
    required this.muscle,
    required this.rank,
    this.subRank,
    this.rankXp = 0,
    required this.updatedAt,
  });

  final int userId;
  final String muscle;
  final String rank;
  final String? subRank;
  final int rankXp;
  final int updatedAt;

  factory MuscleRank.fromRow(Map<String, Object?> r) => MuscleRank(
        userId: r[CMuscleRank.userId] as int,
        muscle: r[CMuscleRank.muscle] as String,
        rank: r[CMuscleRank.rank] as String,
        subRank: r[CMuscleRank.subRank] as String?,
        rankXp: r[CMuscleRank.rankXp] as int? ?? 0,
        updatedAt: r[CMuscleRank.updatedAt] as int,
      );

  Map<String, Object?> toRow() => {
        CMuscleRank.userId: userId,
        CMuscleRank.muscle: muscle,
        CMuscleRank.rank: rank,
        CMuscleRank.subRank: subRank,
        CMuscleRank.rankXp: rankXp,
        CMuscleRank.updatedAt: updatedAt,
      };
}
