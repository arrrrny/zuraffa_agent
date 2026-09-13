// GENERATED STUB — hand-wired contract seam (spec 114 contract:A3).
// ignore_for_file: non_constant_identifier_names
library;

import 'dart:io';

import 'package:zuraffa_agent/src/jsonl_session_storage.dart';
import 'package:zuraffa_agent/src/types.dart';

/// Call-through shim: the real mutation mutex runs an append through a
/// real store. Null-probe safe (zuraffa#1541).
Future<void> guard(dynamic mutation) async {
  final dir = await Directory.systemTemp.createTemp('spec114-ca3');
  final store = JsonlSessionStorage('${dir.path}/probe.jsonl');
  await store.init();
  await store.appendEntry(
    MessageEntry(
      id: 'probe',
      message: UserMessage(content: [TextBlock('probe')]),
      timestamp: DateTime.fromMillisecondsSinceEpoch(0),
    ),
  );
  await store.close();
  await dir.delete(recursive: true);
}
