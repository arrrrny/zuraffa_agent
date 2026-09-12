// GENERATED STUB — hand-stepped (spec 116 U3): the subprocess check.
// Returns exit code + whether the lifecycle lines are present.
// ignore_for_file: non_constant_identifier_names
library;

import 'dart:io';

/// Subject for behavior U3 — declared contract:
/// `subprocess() -> ProcessResult`.
Future<Map<String, Object?>> subject_u3() async {
  final result = await Process.run(Platform.resolvedExecutable, [
    'run',
    'example/minimal_agent.dart',
  ], workingDirectory: Directory.current.path);
  final out = result.stdout as String;
  return {
    'exitCode': result.exitCode,
    'hasStart': out.contains('[event] MissionStarted'),
    'hasComplete': out.contains('[event] MissionCompleted'),
    'hasStatus': out.contains('status    : completed'),
  };
}
