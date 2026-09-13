library;


import 'package:test/test.dart';

import 'package:zuraffa_agent/tdd/114-jsonl-single-writer-streaming/a2_subject.dart';

void main() {
  group('A2 (AC-2)', () {
    test('A2 — acquisition fails fast', () async {
      Object? outcome;
      try {
        outcome = await subject_a2();
      } on UnimplementedError catch (e) {
        outcome = e;
      }
      expect(outcome, isNot(isA<UnimplementedError>()));
      final message = outcome as String;
      expect(message, contains('locked by another writer'));
      expect(message, contains('sessions.jsonl'));
    });
  });
}
