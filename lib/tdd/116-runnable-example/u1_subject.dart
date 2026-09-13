// GENERATED STUB — hand-stepped (spec 116 U1): run the example mission
// in-process by executing the example script's logic (subprocess form:
// U3). Returns the exit-code string '0' when the mission completes.
// ignore_for_file: non_constant_identifier_names
library;

import 'dart:io';

/// Subject for behavior U1 — declared contract: `run() -> Future<MissionResult>`.
Future<String> subject_u1() async {
  final result = await Process.run(Platform.resolvedExecutable, [
    'run',
    'example/minimal_agent.dart',
  ], workingDirectory: Directory.current.path);
  return '${result.exitCode}';
}
