import '../schema.dart';
import '_json_list.dart';

class PlayerClassRow {
  const PlayerClassRow({
    this.userId = 1,
    required this.classKey,
    required this.assignedAt,
    required this.lastChangedAt,
    this.evolutionHistory = const [],
  });

  final int userId;
  final String classKey;
  final int assignedAt;
  final int lastChangedAt;
  final List<String> evolutionHistory;

  factory PlayerClassRow.fromRow(Map<String, Object?> r) => PlayerClassRow(
        userId: r[CPlayerClass.userId] as int,
        classKey: r[CPlayerClass.classKey] as String,
        assignedAt: r[CPlayerClass.assignedAt] as int,
        lastChangedAt: r[CPlayerClass.lastChangedAt] as int,
        evolutionHistory: decodeStringList(r[CPlayerClass.evolutionHistory]),
      );

  Map<String, Object?> toRow() => {
        CPlayerClass.userId: userId,
        CPlayerClass.classKey: classKey,
        CPlayerClass.assignedAt: assignedAt,
        CPlayerClass.lastChangedAt: lastChangedAt,
        CPlayerClass.evolutionHistory: encodeStringList(evolutionHistory),
      };
}
