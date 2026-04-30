/// Conversion helpers for translating local-row JSON payloads into the
/// shape expected by Supabase cloud_* tables.
///
/// The local sqflite schema stores:
///   • timestamps as INTEGER unix-seconds
///   • dates as INTEGER unix-seconds (YYYY-MM-DD reconstructed)
///   • booleans as INTEGER 0/1
///   • arrays as JSON-encoded TEXT
///
/// The cloud schema (002_schema.sql) uses:
///   • TIMESTAMPTZ (ISO-8601 UTC strings)
///   • DATE (YYYY-MM-DD strings)
///   • BOOLEAN
///   • TEXT[] / INT[] PostgREST arrays
///
/// The PostgREST client takes JSON, so we hand it ISO strings + native
/// Dart booleans + native Dart Lists, and Supabase routes them to the
/// right Postgres types.
library;

import 'dart:convert';

/// Convert a unix-seconds int to an ISO-8601 UTC string. PostgREST
/// accepts both `2026-04-30T...Z` and `2026-04-30 ...+00`; we use the
/// `T...Z` form since `DateTime.toIso8601String()` produces it.
String? unixSecondsToIso(Object? raw) {
  if (raw == null) return null;
  if (raw is! int) return null;
  return DateTime.fromMillisecondsSinceEpoch(raw * 1000, isUtc: true)
      .toIso8601String();
}

/// Convert a unix-seconds int to a `YYYY-MM-DD` date string (UTC).
/// Used for columns the cloud declares as DATE — `logged_on`,
/// `last_active_date`, `freezes_period_start`, `used_on`.
String? unixSecondsToDate(Object? raw) {
  if (raw == null) return null;
  if (raw is! int) return null;
  final dt = DateTime.fromMillisecondsSinceEpoch(raw * 1000, isUtc: true);
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// SQLite-style 0/1 → Dart bool.
bool? intToBool(Object? raw) {
  if (raw == null) return null;
  if (raw is bool) return raw;
  if (raw is int) return raw != 0;
  return null;
}

/// JSON-encoded TEXT array → Dart `List<String>`. Returns an empty
/// list for null / non-string / malformed input — matches the local
/// `decodeStringList` helper's tolerance.
List<String> jsonToStringList(Object? raw) {
  if (raw == null) return const [];
  if (raw is List) return raw.map((e) => e.toString()).toList();
  if (raw is! String || raw.isEmpty) return const [];
  final d = jsonDecode(raw);
  if (d is List) return d.map((e) => e.toString()).toList();
  return const [];
}

/// JSON-encoded TEXT array → Dart `List<int>`. Used for `days` (the
/// schedule's day-of-week list).
List<int> jsonToIntList(Object? raw) {
  if (raw == null) return const [];
  if (raw is List) return raw.map((e) => (e as num).toInt()).toList();
  if (raw is! String || raw.isEmpty) return const [];
  final d = jsonDecode(raw);
  if (d is List) return d.map((e) => (e as num).toInt()).toList();
  return const [];
}

/// Decode an outbox row's `payloadJson` back into a plain Map. Returns
/// an empty map for null / malformed input — handlers should surface
/// "missing payload" as a hard failure rather than silently push
/// nothing.
Map<String, Object?> decodePayload(String? payloadJson) {
  if (payloadJson == null || payloadJson.isEmpty) return const {};
  final d = jsonDecode(payloadJson);
  if (d is! Map) return const {};
  return d.map((k, v) => MapEntry(k.toString(), v));
}

// ─────────────────────────────────────────────────────────────────
// Cloud → local (inverse of the helpers above). Used by pull
// handlers during initial-sync hydration.
// ─────────────────────────────────────────────────────────────────

/// ISO-8601 timestamp string → unix-seconds int. Returns `null` for
/// null / non-string / unparseable input.
int? isoToUnixSeconds(Object? raw) {
  if (raw == null) return null;
  if (raw is int) return raw;
  if (raw is! String || raw.isEmpty) return null;
  final dt = DateTime.tryParse(raw);
  if (dt == null) return null;
  return dt.toUtc().millisecondsSinceEpoch ~/ 1000;
}

/// `YYYY-MM-DD` date string → unix-seconds int (midnight UTC).
int? dateStringToUnixSeconds(Object? raw) {
  if (raw == null) return null;
  if (raw is int) return raw;
  if (raw is! String || raw.isEmpty) return null;
  // Accept either bare date or full timestamp; both work via DateTime.tryParse.
  final dt = DateTime.tryParse(raw);
  if (dt == null) return null;
  // Normalize to UTC midnight of the parsed calendar day.
  final day = DateTime.utc(dt.year, dt.month, dt.day);
  return day.millisecondsSinceEpoch ~/ 1000;
}

/// Dart bool (or 0/1 int) → SQLite-style 0/1 int.
int boolToInt(Object? raw) {
  if (raw is bool) return raw ? 1 : 0;
  if (raw is int) return raw == 0 ? 0 : 1;
  return 0;
}

/// Cloud `TEXT[]` / `INT[]` (Dart `List<dynamic>` from PostgREST) →
/// JSON-encoded TEXT for local storage. Empty / null → `'[]'`.
String listToJsonString(Object? raw) {
  if (raw == null) return '[]';
  if (raw is List) return jsonEncode(raw);
  if (raw is String && raw.isNotEmpty) return raw; // Already encoded.
  return '[]';
}
