import '../schema.dart';
import '_json_list.dart';

class ScheduleRow {
  const ScheduleRow({
    this.userId = 1,
    this.days = const [],
    this.sessionMinutes,
    required this.updatedAt,
  });

  final int userId;
  final List<int> days;
  final int? sessionMinutes;
  final int updatedAt;

  factory ScheduleRow.fromRow(Map<String, Object?> r) => ScheduleRow(
        userId: r[CSchedule.userId] as int,
        days: decodeIntList(r[CSchedule.days]),
        sessionMinutes: r[CSchedule.sessionMinutes] as int?,
        updatedAt: r[CSchedule.updatedAt] as int,
      );

  Map<String, Object?> toRow() => {
        CSchedule.userId: userId,
        CSchedule.days: encodeIntList(days),
        CSchedule.sessionMinutes: sessionMinutes,
        CSchedule.updatedAt: updatedAt,
      };

  ScheduleRow copyWith({
    List<int>? days,
    int? sessionMinutes,
    int? updatedAt,
  }) =>
      ScheduleRow(
        userId: userId,
        days: days ?? this.days,
        sessionMinutes: sessionMinutes ?? this.sessionMinutes,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
