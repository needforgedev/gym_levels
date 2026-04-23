import '../schema.dart';
import '_json_list.dart';

class ExperienceRow {
  const ExperienceRow({
    this.userId = 1,
    this.tenure,
    this.equipment = const [],
    this.limitations = const [],
    this.styles = const [],
    required this.updatedAt,
  });

  final int userId;
  final String? tenure;
  final List<String> equipment;
  final List<String> limitations;
  final List<String> styles;
  final int updatedAt;

  factory ExperienceRow.fromRow(Map<String, Object?> r) => ExperienceRow(
        userId: r[CExperience.userId] as int,
        tenure: r[CExperience.tenure] as String?,
        equipment: decodeStringList(r[CExperience.equipment]),
        limitations: decodeStringList(r[CExperience.limitations]),
        styles: decodeStringList(r[CExperience.styles]),
        updatedAt: r[CExperience.updatedAt] as int,
      );

  Map<String, Object?> toRow() => {
        CExperience.userId: userId,
        CExperience.tenure: tenure,
        CExperience.equipment: encodeStringList(equipment),
        CExperience.limitations: encodeStringList(limitations),
        CExperience.styles: encodeStringList(styles),
        CExperience.updatedAt: updatedAt,
      };

  ExperienceRow copyWith({
    String? tenure,
    List<String>? equipment,
    List<String>? limitations,
    List<String>? styles,
    int? updatedAt,
  }) =>
      ExperienceRow(
        userId: userId,
        tenure: tenure ?? this.tenure,
        equipment: equipment ?? this.equipment,
        limitations: limitations ?? this.limitations,
        styles: styles ?? this.styles,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
