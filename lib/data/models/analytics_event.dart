import '../schema.dart';

class AnalyticsEvent {
  const AnalyticsEvent({
    this.id,
    required this.name,
    required this.payloadJson,
    required this.createdAt,
    this.uploadedAt,
  });

  final int? id;
  final String name;
  final String payloadJson;
  final int createdAt;
  final int? uploadedAt;

  bool get isPending => uploadedAt == null;

  factory AnalyticsEvent.fromRow(Map<String, Object?> r) => AnalyticsEvent(
        id: r[CAnalyticsEvent.id] as int?,
        name: r[CAnalyticsEvent.name] as String,
        payloadJson: r[CAnalyticsEvent.payloadJson] as String,
        createdAt: r[CAnalyticsEvent.createdAt] as int,
        uploadedAt: r[CAnalyticsEvent.uploadedAt] as int?,
      );

  Map<String, Object?> toRow() => {
        if (id != null) CAnalyticsEvent.id: id,
        CAnalyticsEvent.name: name,
        CAnalyticsEvent.payloadJson: payloadJson,
        CAnalyticsEvent.createdAt: createdAt,
        CAnalyticsEvent.uploadedAt: uploadedAt,
      };
}
