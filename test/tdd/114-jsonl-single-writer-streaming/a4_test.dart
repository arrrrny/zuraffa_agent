library;

import 'package:test/test.dart';

import 'package:zuraffa_agent/src/session_storage_impl.dart';
import 'package:zuraffa_agent/src/types.dart';
import 'package:zuraffa_agent/tdd/114-jsonl-single-writer-streaming/a4_subject.dart';

void main() {
  group('A4 (AC-4)', () {
    test('A4 — the same entry set is yielded as', () async {
      final store = InMemorySessionStorage();
      for (var i = 0; i < 3; i++) {
        await store.appendEntry(
          MessageEntry(
            id: 'a4-$i',
            message: UserMessage(content: [TextBlock('m-$i')]),
            timestamp: DateTime.fromMillisecondsSinceEpoch(i),
          ),
        );
      }
      final verdicts = await subject_a4(store.entries(), await store.getEntries());
      expect(verdicts['sameSet'], isTrue);
      expect(verdicts['sameCount'], isTrue);
    });
  });
}
