import '../app_db.dart';
import '../models/crash_report.dart';
import '../schema.dart';
import '_now.dart';

class CrashReportService {
  CrashReportService._();

  static Future<int> log(String payloadJson) async {
    final db = await AppDb.instance;
    return db.insert(
      T.crashReports,
      CrashReport(createdAt: nowSeconds(), payloadJson: payloadJson).toRow(),
    );
  }

  static Future<List<CrashReport>> pending({int limit = 50}) async {
    final db = await AppDb.instance;
    final rows = await db.query(
      T.crashReports,
      where: '${CCrashReport.uploadedAt} IS NULL',
      orderBy: '${CCrashReport.createdAt} ASC',
      limit: limit,
    );
    return rows.map(CrashReport.fromRow).toList();
  }

  static Future<void> markUploaded(List<int> ids) async {
    if (ids.isEmpty) return;
    final db = await AppDb.instance;
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.rawUpdate(
      'UPDATE ${T.crashReports} SET ${CCrashReport.uploadedAt} = ? '
      'WHERE ${CCrashReport.id} IN ($placeholders)',
      [nowSeconds(), ...ids],
    );
  }
}
