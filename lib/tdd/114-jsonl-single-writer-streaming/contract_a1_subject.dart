// GENERATED STUB — hand-wired contract seam (spec 114 contract:A1).
// ignore_for_file: non_constant_identifier_names
library;

import 'dart:io';

import 'package:zuraffa_agent/src/session_lock.dart';
import 'package:zuraffa_agent/src/types.dart';

/// Call-through shim: real SessionLock acquire on a temp path.
/// Null-tolerant per the mechanical probe (zuraffa#1541).
Future<void> acquire() async {
  final dir = await Directory.systemTemp.createTemp('spec114-ca1');
  final lock = SessionLock('${dir.path}/probe.jsonl');
  await lock.acquire();
  await lock.release();
  await dir.delete(recursive: true);
}
