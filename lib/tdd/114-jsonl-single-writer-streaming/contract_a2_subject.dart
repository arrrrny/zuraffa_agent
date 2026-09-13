// GENERATED STUB — hand-wired contract seam (spec 114 contract:A2).
// ignore_for_file: non_constant_identifier_names
library;

import 'package:zuraffa_agent/src/session_lock.dart';
import 'dart:io';

/// Call-through shim: acquire then release on a temp path; release must
/// free the slot so a fresh acquire succeeds (zuraffa#1541 null-probe).
Future<void> release() async {
  final dir = await Directory.systemTemp.createTemp('spec114-ca2');
  final lock = SessionLock('${dir.path}/probe.jsonl');
  await lock.acquire();
  await lock.release();
  await lock.acquire();
  await lock.release();
  await dir.delete(recursive: true);
}
