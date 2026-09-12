// spec 116 (issue #111) — the runnable example: subprocess execution +
// source hygiene. All fixtures are the real example/ files.

import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('A1: dart run example/minimal_agent.dart exits 0 with lifecycle lines',
      () async {
    final result = await Process.run(
      Platform.resolvedExecutable,
      ['run', 'example/minimal_agent.dart'],
      workingDirectory: Directory.current.path,
    );
    expect(result.exitCode, 0, reason: 'stderr: ${result.stderr}');
    expect(result.stdout, contains('[event] MissionStarted'));
    expect(result.stdout, contains('[event] MissionCompleted'));
    expect(result.stdout, contains('status    : completed'));
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('A2: the example source has no API-key literals or endpoints',
      () async {
    final source = File('example/minimal_agent.dart').readAsStringSync();
    final echo = File('example/engine/echo_llm_client.dart').readAsStringSync();
    final combined = source + echo;
    expect(combined, isNot(contains('sk-')));
    expect(combined, isNot(contains('api.openai.com')));
    expect(combined, isNot(contains('api.anthropic.com')));
    // The scripted client's base URL is a documentation-only sentinel.
    expect(echo, contains('example.invalid'));
  });
}
