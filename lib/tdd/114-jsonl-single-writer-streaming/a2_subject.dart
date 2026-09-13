// GENERATED STUB — hand-stepped (spec 114 A2): a second store open on a
// locked path fails fast with a StateError naming the path.
// ignore_for_file: non_constant_identifier_names
library;

import 'dart:io';

import 'package:zuraffa_agent/src/jsonl_session_storage.dart';

/// Scenario runner for behavior A2.
Future<String> subject_a2() async {
  final dir = await Directory.systemTemp.createTemp('spec114-a2');
  final path = '${dir.path}/sessions.jsonl';
  final first = JsonlSessionStorage(path);
  await first.init();
  try {
    final second = JsonlSessionStorage(path);
    try {
      await second.init();
      return 'unlocked';
    } on StateError catch (e) {
      return e.message.toString();
    }
  } finally {
    await first.close();
    await dir.delete(recursive: true);
  }
}
