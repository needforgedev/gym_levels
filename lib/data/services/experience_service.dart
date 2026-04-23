import 'package:sqflite/sqflite.dart';

import '../app_db.dart';
import '../models/experience_row.dart';
import '../schema.dart';
import '_now.dart';

class ExperienceService {
  ExperienceService._();

  static Future<ExperienceRow?> get() async {
    final db = await AppDb.instance;
    final rows = await db.query(T.experience,
        where: '${CExperience.userId} = ?', whereArgs: [1], limit: 1);
    return rows.isEmpty ? null : ExperienceRow.fromRow(rows.first);
  }

  static Future<void> upsert(ExperienceRow row) async {
    final db = await AppDb.instance;
    await db.insert(
      T.experience,
      ExperienceRow(
        userId: 1,
        tenure: row.tenure,
        equipment: row.equipment,
        limitations: row.limitations,
        styles: row.styles,
        updatedAt: nowSeconds(),
      ).toRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Patches a subset of experience columns. Creates the row if missing.
  static Future<void> patch({
    String? tenure,
    List<String>? equipment,
    List<String>? limitations,
    List<String>? styles,
  }) async {
    final existing = (await get()) ?? ExperienceRow(updatedAt: nowSeconds());
    await upsert(existing.copyWith(
      tenure: tenure,
      equipment: equipment,
      limitations: limitations,
      styles: styles,
    ));
  }
}
