// GENERATED STUB — hand-stepped (spec 116 A1): run the example via
// subprocess and return the exit code string.
// ignore_for_file: non_constant_identifier_names
library;

import 'dart:io';

Future<String> subject_a1() async {
  final result = await Process.run(Platform.resolvedExecutable, [
    'run',
    'example/minimal_agent.dart',
  ], workingDirectory: Directory.current.path);
  return '${result.exitCode}';
}
