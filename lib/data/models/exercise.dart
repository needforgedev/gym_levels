import '../schema.dart';
import '_json_list.dart';

class Exercise {
  const Exercise({
    this.id,
    required this.name,
    required this.primaryMuscle,
    this.secondaryMuscles = const [],
    this.equipment = const [],
    this.baseXp = 3,
    this.demoVideoUrl,
    this.cueText,
  });

  final int? id;
  final String name;
  final String primaryMuscle;
  final List<String> secondaryMuscles;
  final List<String> equipment;
  final int baseXp;
  final String? demoVideoUrl;
  final String? cueText;

  factory Exercise.fromRow(Map<String, Object?> r) => Exercise(
        id: r[CExercise.id] as int?,
        name: r[CExercise.name] as String,
        primaryMuscle: r[CExercise.primaryMuscle] as String,
        secondaryMuscles: decodeStringList(r[CExercise.secondaryMuscles]),
        equipment: decodeStringList(r[CExercise.equipment]),
        baseXp: r[CExercise.baseXp] as int? ?? 3,
        demoVideoUrl: r[CExercise.demoVideoUrl] as String?,
        cueText: r[CExercise.cueText] as String?,
      );

  Map<String, Object?> toRow() => {
        if (id != null) CExercise.id: id,
        CExercise.name: name,
        CExercise.primaryMuscle: primaryMuscle,
        CExercise.secondaryMuscles: encodeStringList(secondaryMuscles),
        CExercise.equipment: encodeStringList(equipment),
        CExercise.baseXp: baseXp,
        CExercise.demoVideoUrl: demoVideoUrl,
        CExercise.cueText: cueText,
      };
}
