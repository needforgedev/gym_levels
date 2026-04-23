import '../schema.dart';

class WeightLog {
  const WeightLog({
    this.id,
    this.userId = 1,
    required this.loggedOn,
    required this.weightKg,
    this.note,
  });

  final int? id;
  final int userId;
  final int loggedOn;
  final double weightKg;
  final String? note;

  factory WeightLog.fromRow(Map<String, Object?> r) => WeightLog(
        id: r[CWeightLog.id] as int?,
        userId: r[CWeightLog.userId] as int,
        loggedOn: r[CWeightLog.loggedOn] as int,
        weightKg: (r[CWeightLog.weightKg] as num).toDouble(),
        note: r[CWeightLog.note] as String?,
      );

  Map<String, Object?> toRow() => {
        if (id != null) CWeightLog.id: id,
        CWeightLog.userId: userId,
        CWeightLog.loggedOn: loggedOn,
        CWeightLog.weightKg: weightKg,
        CWeightLog.note: note,
      };
}
