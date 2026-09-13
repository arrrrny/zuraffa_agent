// GENERATED STUB — hand-stepped (spec 114 U3): entries() streams the
// same set as getEntries() across all three stores, with early exit.
// ignore_for_file: non_constant_identifier_names
library;

import 'package:zuraffa_agent/src/session_storage.dart';
import 'package:zuraffa_agent/src/session_storage_impl.dart';
import 'package:zuraffa_agent/src/types.dart';

/// Subject for behavior U3 — declared contract: `entries() -> Stream`.
///
/// Seeds an in-memory store with three entries and returns the ids
/// pulled by an early-exit stream (take 2).
Future<List<String>> subject_u3() async {
  final store = InMemorySessionStorage();
  for (var i = 0; i < 3; i++) {
    await store.appendEntry(
      MessageEntry(
        id: 'e-$i',
        message: UserMessage(content: [TextBlock('m-$i')]),
        timestamp: DateTime.fromMillisecondsSinceEpoch(i),
      ),
    );
  }
  final pulled = <String>[];
  await for (final entry in store.entries().take(2)) {
    pulled.add(entry.id);
  }
  return pulled;
}
