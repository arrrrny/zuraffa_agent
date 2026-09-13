// GENERATED STUB — hand-stepped (spec 114 A1): interleaved appends all
// survive a reopen.
// ignore_for_file: non_constant_identifier_names
library;

import 'dart:io';

import 'package:zuraffa_agent/src/jsonl_session_storage.dart';
import 'package:zuraffa_agent/src/types.dart';

/// Scenario runner for behavior A1.
Future<List<String>> subject_a1() async {
  final dir = await Directory.systemTemp.createTemp('spec114-a1');
  final path = '${dir.path}/sessions.jsonl';
  final store = JsonlSessionStorage(path);
  await store.init();
  final entries = <SessionTreeEntry>[
    for (var i = 0; i < 6; i++)
      MessageEntry(
        id: 'a1-$i',
        message: UserMessage(content: [TextBlock('m-$i')]),
        timestamp: DateTime.fromMillisecondsSinceEpoch(i),
      ),
  ];
  // All six appends in flight at once — the mutex serializes them.
  await Future.wait([for (final e in entries) store.appendEntry(e)]);
  await store.close();
  final reopened = JsonlSessionStorage(path);
  final opened = await reopened.init();
  final ids = (await reopened.getEntries()).map((e) => e.id).toList()..sort();
  await reopened.close();
  await dir.delete(recursive: true);
  if (opened.loadedEntriesCount != entries.length) {
    throw StateError(
      'interleaved appends lost entries: ${opened.loadedEntriesCount}',
    );
  }
  return ids;
}
