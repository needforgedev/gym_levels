import '../schema.dart';

class CrashReport {
  const CrashReport({
    this.id,
    required this.createdAt,
    required this.payloadJson,
    this.uploadedAt,
  });

  final int? id;
  final int createdAt;
  final String payloadJson;
  final int? uploadedAt;

  bool get isPending => uploadedAt == null;

  factory CrashReport.fromRow(Map<String, Object?> r) => CrashReport(
        id: r[CCrashReport.id] as int?,
        createdAt: r[CCrashReport.createdAt] as int,
        payloadJson: r[CCrashReport.payloadJson] as String,
        uploadedAt: r[CCrashReport.uploadedAt] as int?,
      );

  Map<String, Object?> toRow() => {
        if (id != null) CCrashReport.id: id,
        CCrashReport.createdAt: createdAt,
        CCrashReport.payloadJson: payloadJson,
        CCrashReport.uploadedAt: uploadedAt,
      };
}
