import '../schema.dart';

class SchemaVersionRow {
  const SchemaVersionRow({
    required this.version,
    required this.appliedAt,
    this.note,
  });

  final int version;
  final int appliedAt;
  final String? note;

  factory SchemaVersionRow.fromRow(Map<String, Object?> r) => SchemaVersionRow(
        version: r[CSchemaVersion.version] as int,
        appliedAt: r[CSchemaVersion.appliedAt] as int,
        note: r[CSchemaVersion.note] as String?,
      );

  Map<String, Object?> toRow() => {
        CSchemaVersion.version: version,
        CSchemaVersion.appliedAt: appliedAt,
        CSchemaVersion.note: note,
      };
}
