import 'dart:convert';

/// SQLite has no native array type — PRD §11.7 stores array-shaped columns
/// as JSON-encoded `TEXT`. These helpers live here to keep the model files
/// tidy and ensure encoding is identical across models.

List<String> decodeStringList(Object? raw) {
  if (raw == null) return const [];
  if (raw is! String || raw.isEmpty) return const [];
  final d = jsonDecode(raw);
  if (d is List) return d.map((e) => e.toString()).toList();
  return const [];
}

String encodeStringList(List<String> value) => jsonEncode(value);

List<int> decodeIntList(Object? raw) {
  if (raw == null) return const [];
  if (raw is! String || raw.isEmpty) return const [];
  final d = jsonDecode(raw);
  if (d is List) return d.map((e) => (e as num).toInt()).toList();
  return const [];
}

String encodeIntList(List<int> value) => jsonEncode(value);
