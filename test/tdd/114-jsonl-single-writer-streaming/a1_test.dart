library;


import 'package:test/test.dart';

import 'package:zuraffa_agent/tdd/114-jsonl-single-writer-streaming/a1_subject.dart';

void main() {
  group('A1 (AC-1)', () {
    test('A1 — every entry', () async {
      Object? outcome;
      try {
        outcome = await subject_a1();
      } on UnimplementedError catch (e) {
        outcome = e;
      }
      expect(outcome, isNot(isA<UnimplementedError>()));
      final ids = outcome as List<String>;
      expect(ids, hasLength(6), reason: 'all interleaved appends survive');
    });
  });
}
