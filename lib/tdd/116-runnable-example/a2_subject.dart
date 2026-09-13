// GENERATED STUB — hand-stepped (spec 116 A2): source hygiene check —
// returns offending literals found in the example sources (empty = OK).
// ignore_for_file: non_constant_identifier_names
library;

import 'dart:io';

List<String> subject_a2() {
  const files = [
    'example/minimal_agent.dart',
    'example/engine/echo_llm_client.dart',
  ];
  const forbidden = ['sk-', 'api.openai.com', 'api.anthropic.com'];
  final offenders = <String>[];
  for (final f in files) {
    final content = File(f).readAsStringSync();
    for (final needle in forbidden) {
      if (content.contains(needle)) offenders.add('$f: $needle');
    }
  }
  return offenders;
}
