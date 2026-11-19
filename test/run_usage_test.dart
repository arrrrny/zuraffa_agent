// Tests for RunUsage (issue #191) — the seam-level accumulator that folds
// LlmResponse.usage into UsageEntry rows the exported UsageLedger projects.
//
// A lean FC loop feeds every LlmResponse into one RunUsage; consumers read
// totals or emit UsageLedger-loadable entries without writing fold code.

import 'dart:convert';

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/llm/llm_client.dart';
import 'package:zuraffa_agent/zuraffa_agent.dart';

import 'llm/fake_llm_client.dart';

LlmResponse _response({
  int inputTokens = 0,
  int outputTokens = 0,
  int cachedTokens = 0,
  int thoughtTokens = 0,
}) {
  return LlmResponse(
    content: 'ok',
    usage: LlmUsage(
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      cachedTokens: cachedTokens,
      thoughtTokens: thoughtTokens,
    ),
  );
}

void main() {
  group('RunUsage', () {
    test('folds usage across scripted LlmResponses', () {
      final run = RunUsage()
        ..add(_response(inputTokens: 100, outputTokens: 50))
        ..add(_response(inputTokens: 200, outputTokens: 75, cachedTokens: 10))
        ..add(_response(inputTokens: 300, outputTokens: 125, thoughtTokens: 5));

      expect(run.totalPromptTokens, 600);
      expect(run.totalCompletionTokens, 250);
      expect(run.totalCachedTokens, 10);
      expect(run.totalThoughtTokens, 5);
      expect(run.totalTokens, 850);
      expect(run.length, 3);
    });

    test('empty accumulator reads zero', () {
      final run = RunUsage();
      expect(run.totalPromptTokens, 0);
      expect(run.totalCompletionTokens, 0);
      expect(run.totalTokens, 0);
      expect(run.length, 0);
    });

    test('toUsageEntries builds UsageLedger-loadable rows', () {
      final run = RunUsage()
        ..add(_response(inputTokens: 100, outputTokens: 50, cachedTokens: 7))
        ..add(_response(inputTokens: 200, outputTokens: 75));

      final at = DateTime.utc(2026, 11, 19, 12, 30);
      final entries = run.toUsageEntries(
        model: 'mimo-v2.6-flash',
        provider: 'raptor-ai',
        at: at,
      );

      expect(entries, hasLength(2));

      final first = entries.first;
      expect(first.record.callId, 'run-1');
      expect(first.record.turnNumber, 1);
      expect(first.record.inputTokens, 100);
      expect(first.record.outputTokens, 50);
      expect(first.record.cacheReadTokens, 7);
      expect(first.record.cacheWriteTokens, 0);
      expect(first.timestamp, at);
      expect(first.model?.modelId, 'mimo-v2.6-flash');
      expect(first.model?.provider, 'raptor-ai');

      final second = entries[1];
      expect(second.record.callId, 'run-2');
      expect(second.record.turnNumber, 2);
      expect(second.record.inputTokens, 200);

      // The existing exported projection aggregates them.
      final ledger = UsageLedger(entries);
      expect(ledger.totalInputTokens, 300);
      expect(ledger.totalOutputTokens, 125);
      expect(ledger.totalCacheReadTokens, 7);
      expect(ledger.totalTokens, 425);
    });

    test('entries round-trip via UsageLedger JSON', () {
      final run = RunUsage()..add(_response(inputTokens: 42, outputTokens: 24));
      final ledger = UsageLedger(
        run.toUsageEntries(model: 'glm-5.3', at: DateTime.utc(2026, 11, 19)),
      );

      final restored = UsageLedger.fromJson(ledger.toJson());
      expect(restored, ledger);

      final entryJson = jsonEncode(ledger.entries.single.toJson());
      final entryBack = UsageEntry.fromJson(
        Map<String, dynamic>.from(jsonDecode(entryJson) as Map),
      );
      expect(entryBack.toJson(), ledger.entries.single.toJson());
      expect(entryBack.record.inputTokens, 42);
      expect(entryBack.record.outputTokens, 24);
    });

    test('acceptance: a scripted lean loop reports exact run totals', () async {
      final client = FakeLlmClient(
        providerName: 'raptor-ai',
        model: 'mimo-v2.6-flash',
        outcomes: [
          ScriptedOutcome(
            response: _response(inputTokens: 900, outputTokens: 400),
          ),
          ScriptedOutcome(
            response: _response(inputTokens: 1500, outputTokens: 600),
          ),
          ScriptedOutcome(
            response: _response(inputTokens: 2100, outputTokens: 800),
          ),
        ],
      );

      final run = RunUsage();
      const request = LlmRequest(messages: []);
      for (var turn = 0; turn < 3; turn++) {
        final response = await client.generate(request);
        run.add(response);
      }

      // Zero per-consumer accounting code: the totals come from the fold.
      expect(run.totalPromptTokens, 4500);
      expect(run.totalCompletionTokens, 1800);
      expect(run.totalTokens, 6300);

      final ledger = UsageLedger(
        run.toUsageEntries(model: client.model, provider: client.providerName),
      );
      expect(ledger.totalInputTokens, 4500);
      expect(ledger.totalOutputTokens, 1800);
      expect(ledger.length, 3);
    });
  });
}
