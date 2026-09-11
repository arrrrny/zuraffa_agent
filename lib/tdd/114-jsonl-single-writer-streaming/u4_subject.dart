// GENERATED STUB — hand-stepped (spec 114 U4): the Hive store header
// documents the single-writer contract. The subject validates the given
// header text (the test reads the real file).
// ignore_for_file: non_constant_identifier_names
library;

/// Subject for behavior U4 — declared contract: `entries() -> Stream`
/// (Hive documentation slice).
///
/// Throws when the Hive store header does not document the single-writer
/// assumption.
void subject_u4(String hiveHeader) {
  final normalized = hiveHeader.toLowerCase();
  for (final marker in ['single-writer', 'cross-process']) {
    if (!normalized.contains(marker)) {
      throw StateError(
        'HiveSessionStorage header missing "$marker" single-writer note',
      );
    }
  }
}
