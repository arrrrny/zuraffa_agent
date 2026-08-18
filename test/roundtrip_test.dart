// Cross-store round-trip equivalence and typed identity retrieval tests (T010).
//
// Verifies that typed SessionTreeEntry instances persist and reload
// identically via JSON serialization, and that typed identity retrieval
// works correctly.
//
// NOTE: InMemorySessionStorage / JsonlSessionStorage round-trip tests
// will be added when those implementations land (T021 / T022).

import 'package:test/test.dart';
import 'package:zuraffa_agent/zuraffa_agent.dart';

void main() {
  final fixedTime = DateTime.utc(2026, 1, 15, 12, 0, 0);

  /// Creates a representative set of typed entries for round-trip testing.
  List<SessionTreeEntry> makeEntrySet() {
    return [
      MessageEntry(
        id: 'e_1',
        parentId: null,
        timestamp: fixedTime,
        message: UserMessage.text('Hello, agent'),
      ),
      MessageEntry(
        id: 'e_2',
        parentId: 'e_1',
        timestamp: fixedTime.add(const Duration(seconds: 1)),
        message: AssistantMessage.text('I will help you.'),
      ),
      TurnRecordEntry(
        id: 'e_3',
        parentId: 'e_2',
        timestamp: fixedTime.add(const Duration(seconds: 2)),
        record: TurnRecord(
          id: 'tr_1',
          parentId: 'e_2',
          timestamp: fixedTime.add(const Duration(seconds: 2)),
          turnNumber: 1,
          messageEntryIds: ['e_1', 'e_2'],
          toolInvocationEntryIds: ['e_4'],
          stopReason: 'toolUse',
          startedAt: fixedTime.add(const Duration(seconds: 1)),
          endedAt: fixedTime.add(const Duration(seconds: 3)),
          durationMs: 2000,
        ),
      ),
      ToolInvocationEntry(
        id: 'e_4',
        parentId: 'e_2',
        timestamp: fixedTime.add(const Duration(seconds: 2)),
        record: ToolInvocationRecord(
          id: 'ti_1',
          parentId: 'e_2',
          timestamp: fixedTime.add(const Duration(seconds: 2)),
          toolCallId: 'tc_1',
          toolName: 'search',
          isError: false,
          durationMs: 500,
        ),
        arguments: {'query': 'test'},
      ),
      UsageEntry(
        id: 'e_5',
        parentId: 'e_2',
        timestamp: fixedTime.add(const Duration(seconds: 3)),
        record: UsageLedgerEntry(
          id: 'ul_1',
          parentId: 'e_2',
          timestamp: fixedTime.add(const Duration(seconds: 3)),
          callId: 'c_1',
          turnNumber: 1,
          inputTokens: 500,
          outputTokens: 250,
          cacheReadTokens: 100,
          cacheWriteTokens: 25,
        ),
        model: Model(
          provider: 'openai',
          modelId: 'gpt-4',
          contextWindow: 8192,
        ),
      ),
    ];
  }

  group('Typed JSON round-trip equivalence', () {
    test('each entry round-trips through its own JSON serialization', () {
      for (final entry in makeEntrySet()) {
        final json = entry.toJson();
        final restored = SessionTreeEntry.fromJson(json);
        expect(restored.toJson(), json, reason: 'Entry ${entry.id} JSON mismatch');
      }
    });

    test('all entries round-trip independently', () {
      final entries = makeEntrySet();
      for (final entry in entries) {
        final json1 = entry.toJson();
        final restored = SessionTreeEntry.fromJson(json1);
        final json2 = restored.toJson();
        expect(json2, json1, reason: 'Double round-trip of ${entry.id} diverged');
      }
    });
  });

  group('Typed identity retrieval', () {
    test('each entry is identified by correct sealed subtype', () {
      for (final entry in makeEntrySet()) {
        final json = entry.toJson();
        final restored = SessionTreeEntry.fromJson(json);

        switch (entry) {
          case MessageEntry():
            expect(restored, isA<MessageEntry>());
          case TurnRecordEntry():
            expect(restored, isA<TurnRecordEntry>());
          case ToolInvocationEntry():
            expect(restored, isA<ToolInvocationEntry>());
          case UsageEntry():
            expect(restored, isA<UsageEntry>());
          default:
            fail('Unexpected entry type: ${entry.runtimeType}');
        }
      }
    });

    test('entry identity fields preserved across serialization', () {
      for (final entry in makeEntrySet()) {
        final json = entry.toJson();
        final restored = SessionTreeEntry.fromJson(json);

        expect(restored.id, entry.id);
        expect(restored.parentId, entry.parentId);
        expect(restored.timestamp, entry.timestamp);
      }
    });
  });
}
