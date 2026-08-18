// Tests for UsageLedger metrics aggregation and projections (T009).
//
// These tests exercise the UsageLedger read projection class that provides
// byTurn, byModel, and aggregate token metrics from a list of UsageEntry
// instances wrapping UsageLedgerEntry + Model.

import 'package:test/test.dart';
import 'package:zuraffa_agent/zuraffa_agent.dart';

UsageEntry _entry({
  required String id,
  required String callId,
  required int turnNumber,
  required String modelId,
  required String provider,
  required int inputTokens,
  required int outputTokens,
  int cacheReadTokens = 0,
  int cacheWriteTokens = 0,
}) {
  return UsageEntry(
    id: id,
    timestamp: DateTime.utc(2026, 1, 15),
    record: UsageLedgerEntry(
      id: '${id}_record',
      timestamp: DateTime.utc(2026, 1, 15),
      callId: callId,
      turnNumber: turnNumber,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      cacheReadTokens: cacheReadTokens,
      cacheWriteTokens: cacheWriteTokens,
    ),
    model: Model(
      provider: provider,
      modelId: modelId,
      contextWindow: 8192,
    ),
  );
}

void main() {
  group('UsageLedger aggregation', () {
    late UsageLedger ledger;

    setUp(() {
      ledger = UsageLedger([
        _entry(
          id: 'e_1',
          callId: 'c_1',
          turnNumber: 1,
          modelId: 'gpt-4',
          provider: 'openai',
          inputTokens: 100,
          outputTokens: 50,
        ),
        _entry(
          id: 'e_2',
          callId: 'c_2',
          turnNumber: 1,
          modelId: 'gpt-4',
          provider: 'openai',
          inputTokens: 200,
          outputTokens: 100,
        ),
        _entry(
          id: 'e_3',
          callId: 'c_3',
          turnNumber: 2,
          modelId: 'gpt-4o',
          provider: 'openai',
          inputTokens: 300,
          outputTokens: 150,
          cacheReadTokens: 50,
        ),
        _entry(
          id: 'e_4',
          callId: 'c_4',
          turnNumber: 2,
          modelId: 'gpt-4',
          provider: 'openai',
          inputTokens: 150,
          outputTokens: 75,
        ),
      ]);
    });

    test('totalInputTokens sums all entries', () {
      expect(ledger.totalInputTokens, 750);
    });

    test('totalOutputTokens sums all entries', () {
      expect(ledger.totalOutputTokens, 375);
    });

    test('totalTokens is input + output', () {
      expect(ledger.totalTokens, 1125);
    });

    test('byTurn filters to specific turn', () {
      final turn1 = ledger.byTurn(1);
      expect(turn1.totalInputTokens, 300);
      expect(turn1.totalOutputTokens, 150);
    });

    test('byTurn with no matching entries returns empty ledger', () {
      final empty = ledger.byTurn(99);
      expect(empty.totalTokens, 0);
      expect(empty.isEmpty, isTrue);
    });

    test('byModel filters to specific model', () {
      final gpt4o = ledger.byModel('gpt-4o');
      expect(gpt4o.totalInputTokens, 300);
      expect(gpt4o.totalOutputTokens, 150);
    });

    test('byModel with no matching entries returns empty ledger', () {
      final empty = ledger.byModel('claude-3');
      expect(empty.totalTokens, 0);
    });

    test('empty ledger has zero totals', () {
      final empty = UsageLedger([]);
      expect(empty.totalInputTokens, 0);
      expect(empty.totalOutputTokens, 0);
      expect(empty.totalTokens, 0);
      expect(empty.isEmpty, isTrue);
      expect(empty.isNotEmpty, isFalse);
    });

    test('byTurn preserves cache tokens', () {
      final turn2 = ledger.byTurn(2);
      expect(turn2.totalCacheReadTokens, 50);
    });

    test('length reflects entry count', () {
      expect(ledger.length, 4);
      expect(ledger.byTurn(1).length, 2);
    });

    test('totalCacheWriteTokens sums correctly', () {
      expect(ledger.totalCacheWriteTokens, 0);
    });
  });
}
