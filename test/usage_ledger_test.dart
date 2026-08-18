// Unit tests for the UsageLedger read-side projection
// (contracts/support-assets.md).
library;

import 'package:test/test.dart';
import 'package:zuraffa_agent/zuraffa_agent.dart';

const _modelA = Model(provider: 'anthropic', modelId: 'sonnet', contextWindow: 200000);
const _modelB = Model(provider: 'openai', modelId: 'gpt-4o', contextWindow: 128000);

UsageLedgerEntry entry(
  String id,
  int turn,
  Model model,
  int input,
  int output, {
  int? cacheCreation,
  int? cacheRead,
}) =>
    UsageLedgerEntry(
      id: id,
      parentId: 'p',
      timestamp: DateTime.utc(2026, 7, 1),
      callId: 'call-$id',
      turnNumber: turn,
      model: model,
      inputTokens: input,
      outputTokens: output,
      cacheCreationInputTokens: cacheCreation,
      cacheReadInputTokens: cacheRead,
    );

void main() {
  test('empty ledger reports zero totals and empty projections', () {
    final ledger = UsageLedger.fromEntries(const []);
    expect(ledger.totalInputTokens, 0);
    expect(ledger.totalOutputTokens, 0);
    expect(ledger.byTurn(), isEmpty);
    expect(ledger.byModel(), isEmpty);
  });

  test('totals sum input and output tokens across all records', () {
    final ledger = UsageLedger.fromEntries([
      entry('a', 1, _modelA, 10, 20),
      entry('b', 2, _modelA, 100, 50),
      entry('c', 3, _modelB, 7, 3),
    ]);
    expect(ledger.totalInputTokens, 117);
    expect(ledger.totalOutputTokens, 73);
  });

  test('byTurn keys records by turn number (last record wins per turn)', () {
    final e1 = entry('a', 1, _modelA, 10, 20);
    final e1b = entry('b', 1, _modelA, 5, 5);
    final e2 = entry('c', 2, _modelB, 100, 50);
    final ledger = UsageLedger.fromEntries([e1, e1b, e2]);
    expect(ledger.byTurn(), hasLength(2));
    expect(ledger.byTurn()[1], equals(e1b),
        reason: 'multiple records in one turn: last wins');
    expect(ledger.byTurn()[2], equals(e2));
  });

  test('byModel aggregates total tokens per modelId', () {
    final ledger = UsageLedger.fromEntries([
      entry('a', 1, _modelA, 10, 20),
      entry('b', 1, _modelA, 30, 10),
      entry('c', 2, _modelB, 100, 50),
    ]);
    expect(ledger.byModel(), {'sonnet': 70, 'gpt-4o': 150});
  });

  test('cache tokens are not double-counted in totals', () {
    final ledger = UsageLedger.fromEntries([
      entry('a', 1, _modelA, 10, 20, cacheCreation: 100, cacheRead: 50),
    ]);
    expect(ledger.totalInputTokens, 10);
    expect(ledger.totalOutputTokens, 20);
  });
}
