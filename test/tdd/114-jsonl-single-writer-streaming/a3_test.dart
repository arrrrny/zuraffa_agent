library;


import 'package:test/test.dart';

import 'package:zuraffa_agent/tdd/114-jsonl-single-writer-streaming/a3_subject.dart';

void main() {
  group('A3 (AC-3)', () {
    test('A3 — iteration stops without requiring', () async {
      Object? outcome;
      try {
        outcome = await subject_a3();
      } on UnimplementedError catch (e) {
        outcome = e;
      }
      expect(outcome, isNot(isA<UnimplementedError>()));
      final pulled = outcome as List<String>;
      expect(pulled, ['a3-0', 'a3-1'],
          reason: 'early exit stops the pull at two entries');
    });
  });
}
