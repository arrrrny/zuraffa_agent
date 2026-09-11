// GENERATED STUB — `zfa tdd gen U1` (spec 044-test-tdd-generation
// + issue #1259 contract derivation).
//
// behavior_id: U1
// source_criterion: FR-001, JsonlSessionStorage.guard
// description: Every `JsonlSessionStorage` mutation (`appendEntry`,
//
// Hand-step (spec 114): interleaved appends through one store serialize
// under the mutation mutex; both entries survive a reopen.
// ignore_for_file: non_constant_identifier_names
library;

import 'dart:io';

import 'package:zuraffa_agent/src/jsonl_session_storage.dart';
import 'package:zuraffa_agent/src/types.dart';

AgentMessage _msg(String text) => UserMessage(content: [TextBlock(text)]);

/// Subject for behavior U1 — declared contract:
/// `guard(mutation) -> Future<void>`.
///
/// Returns the reopened entry ids after two interleaved appends.
Future<List<String>> subject_u1(Future<void> Function()? mutation) async {
  final dir = await Directory.systemTemp.createTemp('spec114-u1');
  final path = '${dir.path}/sessions.jsonl';
  final store = JsonlSessionStorage(path);
  await store.init();
  final first = MessageEntry(
    id: 'u1-a',
    message: _msg('first'),
    timestamp: DateTime.fromMillisecondsSinceEpoch(0),
  );
  final second = MessageEntry(
    id: 'u1-b',
    message: _msg('second'),
    timestamp: DateTime.fromMillisecondsSinceEpoch(1),
  );
  // Interleaved: both futures in flight at once — the mutex serializes.
  await Future.wait([store.appendEntry(first), store.appendEntry(second)]);
  await store.close();

  final reopened = JsonlSessionStorage(path);
  await reopened.init();
  final ids = (await reopened.getEntries()).map((e) => e.id).toList()..sort();
  await reopened.close();
  await dir.delete(recursive: true);
  return ids;
}
