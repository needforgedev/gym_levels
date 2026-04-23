import '../schema.dart';

class StreakFreezeEvent {
  const StreakFreezeEvent({
    this.id,
    this.userId = 1,
    required this.usedOn,
    this.reason,
  });

  final int? id;
  final int userId;
  final int usedOn;
  final String? reason;

  factory StreakFreezeEvent.fromRow(Map<String, Object?> r) => StreakFreezeEvent(
        id: r[CStreakFreezeEvent.id] as int?,
        userId: r[CStreakFreezeEvent.userId] as int,
        usedOn: r[CStreakFreezeEvent.usedOn] as int,
        reason: r[CStreakFreezeEvent.reason] as String?,
      );

  Map<String, Object?> toRow() => {
        if (id != null) CStreakFreezeEvent.id: id,
        CStreakFreezeEvent.userId: userId,
        CStreakFreezeEvent.usedOn: usedOn,
        CStreakFreezeEvent.reason: reason,
      };
}
