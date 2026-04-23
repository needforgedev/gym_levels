import '../schema.dart';

class NotificationPrefs {
  const NotificationPrefs({
    this.userId = 1,
    this.workoutReminders = true,
    this.streakWarnings = true,
    this.weeklyReports = true,
  });

  final int userId;
  final bool workoutReminders;
  final bool streakWarnings;
  final bool weeklyReports;

  factory NotificationPrefs.fromRow(Map<String, Object?> r) => NotificationPrefs(
        userId: r[CNotificationPrefs.userId] as int,
        workoutReminders: (r[CNotificationPrefs.workoutReminders] as int? ?? 1) == 1,
        streakWarnings: (r[CNotificationPrefs.streakWarnings] as int? ?? 1) == 1,
        weeklyReports: (r[CNotificationPrefs.weeklyReports] as int? ?? 1) == 1,
      );

  Map<String, Object?> toRow() => {
        CNotificationPrefs.userId: userId,
        CNotificationPrefs.workoutReminders: workoutReminders ? 1 : 0,
        CNotificationPrefs.streakWarnings: streakWarnings ? 1 : 0,
        CNotificationPrefs.weeklyReports: weeklyReports ? 1 : 0,
      };

  NotificationPrefs copyWith({
    bool? workoutReminders,
    bool? streakWarnings,
    bool? weeklyReports,
  }) =>
      NotificationPrefs(
        userId: userId,
        workoutReminders: workoutReminders ?? this.workoutReminders,
        streakWarnings: streakWarnings ?? this.streakWarnings,
        weeklyReports: weeklyReports ?? this.weeklyReports,
      );
}
