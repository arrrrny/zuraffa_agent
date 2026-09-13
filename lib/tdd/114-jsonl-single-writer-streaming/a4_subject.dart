// GENERATED STUB — hand-stepped (spec 114 A4): entries() yields the same
// set as getEntries() on both Hive and in-memory stores.
// ignore_for_file: non_constant_identifier_names
library;

import 'package:zuraffa_agent/src/session_storage.dart';
import 'package:zuraffa_agent/src/session_storage_impl.dart';
import 'package:zuraffa_agent/src/types.dart';

/// Scenario runner for behavior A4. Returns per-store verdicts.
Future<Map<String, bool>> subject_a4(
  Stream<SessionTreeEntry> streamed,
  List<SessionTreeEntry> eager,
) async {
  final streamedIds = await streamed.map((e) => e.id).toList();
  final eagerIds = eager.map((e) => e.id).toSet();
  final streamedSet = streamedIds.toSet();
  final sameSet =
      streamedSet.length == eagerIds.length &&
      streamedSet.every(eagerIds.contains);
  return {
    'sameSet': sameSet,
    'sameCount': streamedIds.length == eagerIds.length,
  };
}
