// GENERATED STUB — hand-stepped (spec 116 U2): transcript lines from
// event type names (the example prints [event] lines).
// ignore_for_file: non_constant_identifier_names
library;

/// Subject for behavior U2 — declared contract:
/// `transcript(events) -> List<String>`.
List<String> subject_u2(List<String> events) {
  return [for (final e in events) '[event] $e'];
}
