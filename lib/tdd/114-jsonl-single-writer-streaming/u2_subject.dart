// GENERATED STUB — hand-stepped (spec 114 U2): a second store open on a
// locked path fails fast with a StateError naming the path.
// ignore_for_file: non_constant_identifier_names
library;

import 'dart:io';

import 'package:zuraffa_agent/src/jsonl_session_storage.dart';
import 'package:zuraffa_agent/src/session_lock.dart';
import 'package:zuraffa_agent/src/types.dart';

/// Subject for behavior U2 — declared contract: `acquire() -> Future<void>`.
///
/// Acquires the lock for a temp path, then attempts a second acquire.
/// Returns the second acquire's error message, or the empty string when
/// no error surfaced.
Future<String> subject_u2() async {
  final dir = await Directory.systemTemp.createTemp('spec114-u2');
  final path = '${dir.path}/sessions.jsonl';
  final first = SessionLock(path);
  await first.acquire();
  try {
    final second = SessionLock(path);
    try {
      await second.acquire();
      return '';
    } on StateError catch (e) {
      return e.message.toString();
    }
  } finally {
    await first.release();
    await dir.delete(recursive: true);
  }
}
