import '../schema.dart';

class Player {
  const Player({
    this.id = 1,
    required this.displayName,
    this.age = 0,
    this.heightCm = 0,
    this.weightKg = 0,
    this.bodyFatEstimate,
    this.unitsPref = 'metric',
    this.onboardedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String displayName;
  final int age;
  final double heightCm;
  final double weightKg;
  final String? bodyFatEstimate;
  final String unitsPref;
  final int? onboardedAt;
  final int createdAt;
  final int updatedAt;

  bool get isOnboarded => onboardedAt != null;

  factory Player.fromRow(Map<String, Object?> r) => Player(
        id: r[CPlayer.id] as int,
        displayName: r[CPlayer.displayName] as String,
        age: r[CPlayer.age] as int? ?? 0,
        heightCm: (r[CPlayer.heightCm] as num?)?.toDouble() ?? 0,
        weightKg: (r[CPlayer.weightKg] as num?)?.toDouble() ?? 0,
        bodyFatEstimate: r[CPlayer.bodyFatEstimate] as String?,
        unitsPref: r[CPlayer.unitsPref] as String? ?? 'metric',
        onboardedAt: r[CPlayer.onboardedAt] as int?,
        createdAt: r[CPlayer.createdAt] as int,
        updatedAt: r[CPlayer.updatedAt] as int,
      );

  Map<String, Object?> toRow() => {
        CPlayer.id: id,
        CPlayer.displayName: displayName,
        CPlayer.age: age,
        CPlayer.heightCm: heightCm,
        CPlayer.weightKg: weightKg,
        CPlayer.bodyFatEstimate: bodyFatEstimate,
        CPlayer.unitsPref: unitsPref,
        CPlayer.onboardedAt: onboardedAt,
        CPlayer.createdAt: createdAt,
        CPlayer.updatedAt: updatedAt,
      };

  Player copyWith({
    String? displayName,
    int? age,
    double? heightCm,
    double? weightKg,
    String? bodyFatEstimate,
    String? unitsPref,
    int? onboardedAt,
    int? updatedAt,
  }) =>
      Player(
        id: id,
        displayName: displayName ?? this.displayName,
        age: age ?? this.age,
        heightCm: heightCm ?? this.heightCm,
        weightKg: weightKg ?? this.weightKg,
        bodyFatEstimate: bodyFatEstimate ?? this.bodyFatEstimate,
        unitsPref: unitsPref ?? this.unitsPref,
        onboardedAt: onboardedAt ?? this.onboardedAt,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
