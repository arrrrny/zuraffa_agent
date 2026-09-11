// GENERATED STUB — hand-stepped (spec 114 A3): JSONL entries() early
// exit pulls only the taken entries.
// ignore_for_file: non_constant_identifier_names
library;

import 'dart:io';

import 'package:zuraffa_agent/src/jsonl_session_storage.dart';
import 'package:zuraffa_agent/src/types.dart';

/// Scenario runner for behavior A3.
Future<List<String>> subject_a3() async {
  final dir = await Directory.systemTemp.createTemp('spec114-a3');
  final path = '${dir.path}/sessions.jsonl';
  final store = JsonlSessionStorage(path);
  await store.init();
  for (var i = 0; i < 5; i++) {
    await store.appendEntry(
      MessageEntry(
        id: 'a3-$i',
        message: UserMessage(content: [TextBlock('m-$i')]),
        timestamp: DateTime.fromMillisecondsSinceEpoch(i),
      ),
    );
  }
  final pulled = <String>[];
  await for (final e in store.entries().take(2)) {
    pulled.add(e.id);
  }
  await store.close();
  await dir.delete(recursive: true);
  return pulled;
}
