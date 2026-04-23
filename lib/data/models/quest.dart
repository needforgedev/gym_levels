import '../schema.dart';

class Quest {
  const Quest({
    this.id,
    this.userId = 1,
    required this.type,
    required this.title,
    this.description,
    required this.target,
    this.progress = 0,
    required this.xpReward,
    required this.issuedAt,
    this.expiresAt,
    this.completedAt,
    this.locked = false,
  });

  final int? id;
  final int userId;
  final String type; // 'daily' | 'weekly' | 'boss'
  final String title;
  final String? description;
  final int target;
  final int progress;
  final int xpReward;
  final int issuedAt;
  final int? expiresAt;
  final int? completedAt;
  final bool locked;

  bool get isCompleted => completedAt != null;
  double get progressRatio =>
      target == 0 ? 0 : (progress / target).clamp(0, 1).toDouble();

  factory Quest.fromRow(Map<String, Object?> r) => Quest(
        id: r[CQuest.id] as int?,
        userId: r[CQuest.userId] as int,
        type: r[CQuest.type] as String,
        title: r[CQuest.title] as String,
        description: r[CQuest.description] as String?,
        target: r[CQuest.target] as int,
        progress: r[CQuest.progress] as int? ?? 0,
        xpReward: r[CQuest.xpReward] as int,
        issuedAt: r[CQuest.issuedAt] as int,
        expiresAt: r[CQuest.expiresAt] as int?,
        completedAt: r[CQuest.completedAt] as int?,
        locked: (r[CQuest.locked] as int? ?? 0) == 1,
      );

  Map<String, Object?> toRow() => {
        if (id != null) CQuest.id: id,
        CQuest.userId: userId,
        CQuest.type: type,
        CQuest.title: title,
        CQuest.description: description,
        CQuest.target: target,
        CQuest.progress: progress,
        CQuest.xpReward: xpReward,
        CQuest.issuedAt: issuedAt,
        CQuest.expiresAt: expiresAt,
        CQuest.completedAt: completedAt,
        CQuest.locked: locked ? 1 : 0,
      };
}
