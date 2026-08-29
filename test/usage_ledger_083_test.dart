// Spec 083 — R4 Usage Ledger: token accounting projection (issue #94,
// parent epic #5).
//
// RED surface (new behavior):
//   T1  Structurally-identical ledgers (distinct instances) are == and
//       hash-equal.
//   T2  Any content difference breaks equality.
//   T3  fromJson(toJson()) == ledger, all five totals preserved; fixture
//       includes cache tokens AND a null-model entry.
//   T4  Empty-ledger edge: equals every other empty ledger, round-trips,
//       totals 0, length 0, no-match sub-ledgers are empty.
//   T5  Immutability: source-list mutation changes nothing; entries
//       mutation throws UnsupportedError.
//   T6  Sub-ledgers are full projections: byTurn(1) round-trips and equals
//       an independently-built ledger of the same entries.
//
// Pin (existing behavior, unguarded):
//   T7  Chaining: byModel(m).byTurn(t) totals equal the both-filter
//       intersection.

import 'package:test/test.dart';
import 'package:zuraffa_agent/zuraffa_agent.dart';

UsageEntry _entry({
  required String id,
  required String callId,
  required int turnNumber,
  String? modelId,
  String? provider,
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
    model: modelId == null
        ? null
        : Model(
            provider: provider ?? 'openai',
            modelId: modelId,
            contextWindow: 8192,
          ),
  );
}

/// The canonical fixture: two models, three turns, cache tokens, and one
/// entry with no model at all. Built fresh on every call so that two calls
/// produce structurally-identical but instance-distinct entries.
List<UsageEntry> _fixture() => [
      _entry(
        id: 'e_1',
        callId: 'c_1',
        turnNumber: 1,
        modelId: 'gpt-4',
        provider: 'openai',
        inputTokens: 100,
        outputTokens: 50,
        cacheReadTokens: 10,
      ),
      _entry(
        id: 'e_2',
        callId: 'c_2',
        turnNumber: 1,
        modelId: 'claude-3',
        provider: 'anthropic',
        inputTokens: 200,
        outputTokens: 80,
        cacheWriteTokens: 20,
      ),
      _entry(
        id: 'e_3',
        callId: 'c_3',
        turnNumber: 2,
        modelId: 'gpt-4',
        provider: 'openai',
        inputTokens: 300,
        outputTokens: 120,
        cacheReadTokens: 30,
        cacheWriteTokens: 40,
      ),
      _entry(
        id: 'e_4',
        callId: 'c_4',
        turnNumber: 2,
        inputTokens: 40, // no model — the null-model round-trip case
        outputTokens: 10,
      ),
      _entry(
        id: 'e_5',
        callId: 'c_5',
        turnNumber: 3,
        modelId: 'claude-3',
        provider: 'anthropic',
        inputTokens: 500,
        outputTokens: 200,
      ),
    ];

void main() {
  group('spec 083 — equality (FR-004)', () {
    test('T1: structurally-identical ledgers are == and hash-equal',
        () async {
      final a = UsageLedger(_fixture());
      final b = UsageLedger(_fixture());
      expect(identical(a, b), isFalse,
          reason: 'the fixtures must be distinct instances');
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('T2: any content difference breaks equality', () {
      final base = _fixture();

      final oneTokenDifferent = _fixture()
        ..[2] = _entry(
          id: 'e_3',
          callId: 'c_3',
          turnNumber: 2,
          modelId: 'gpt-4',
          provider: 'openai',
          inputTokens: 301, // one input token more
          outputTokens: 120,
          cacheReadTokens: 30,
          cacheWriteTokens: 40,
        );
      expect(UsageLedger(base), isNot(equals(UsageLedger(oneTokenDifferent))));

      final shorter = List<UsageEntry>.from(_fixture())..removeLast();
      expect(UsageLedger(base), isNot(equals(UsageLedger(shorter))));

      final reordered = List<UsageEntry>.from(_fixture())..insert(0, _fixture().removeLast());
      expect(UsageLedger(base), isNot(equals(UsageLedger(reordered))),
          reason: 'entry order is significant (ordered-sequence equality)');

      expect(UsageLedger(base), isNot(equals(UsageLedger([]))),
          reason: 'non-empty vs empty');
    });
  });

  group('spec 083 — serialization (FR-003)', () {
    test('T3: fromJson(toJson()) == ledger with all five totals preserved',
        () {
      final ledger = UsageLedger(_fixture());
      final roundTripped = UsageLedger.fromJson(ledger.toJson());

      expect(roundTripped, equals(ledger));
      expect(roundTripped.totalInputTokens, ledger.totalInputTokens);
      expect(roundTripped.totalOutputTokens, ledger.totalOutputTokens);
      expect(roundTripped.totalTokens, ledger.totalTokens);
      expect(roundTripped.totalCacheReadTokens, ledger.totalCacheReadTokens);
      expect(roundTripped.totalCacheWriteTokens, ledger.totalCacheWriteTokens);

      // Fixture arithmetic, written out: 100+200+300+40+500 = 1140 input,
      // 50+80+120+10+200 = 460 output, 10+30 = 40 cache-read,
      // 20+40 = 60 cache-write, total 1600.
      expect(ledger.totalInputTokens, 1140);
      expect(ledger.totalOutputTokens, 460);
      expect(ledger.totalCacheReadTokens, 40);
      expect(ledger.totalCacheWriteTokens, 60);
      expect(ledger.totalTokens, 1600);

      // The null-model entry survived: byModel on the round trip still
      // excludes it from both models but keeps it in the totals.
      expect(roundTripped.byModel('gpt-4').length, 2);
      expect(roundTripped.byModel('claude-3').length, 2);
      expect(roundTripped.length, 5);
    });

    test('T4: empty-ledger edge — equal, round-trips, zero totals', () {
      final empty = UsageLedger([]);
      final otherEmpty = UsageLedger([]);
      expect(empty, equals(otherEmpty));
      expect(empty.length, 0);
      expect(empty.isEmpty, isTrue);
      expect(empty.totalInputTokens, 0);
      expect(empty.totalOutputTokens, 0);
      expect(empty.totalTokens, 0);
      expect(empty.totalCacheReadTokens, 0);
      expect(empty.totalCacheWriteTokens, 0);

      final roundTripped = UsageLedger.fromJson(empty.toJson());
      expect(roundTripped, equals(empty));
      expect(roundTripped.length, 0);

      // No-match sub-ledgers are empty, not errors.
      expect(empty.byTurn(7).length, 0);
      expect(empty.byModel('nope').isEmpty, isTrue);
    });
  });

  group('spec 083 — read-only projection (FR-001, FR-002)', () {
    test('T5: source-list mutation after construction changes nothing', () {
      final source = _fixture();
      final ledger = UsageLedger(source);
      final lengthBefore = ledger.length;
      final inputBefore = ledger.totalInputTokens;

      source.add(_entry(
        id: 'e_late',
        callId: 'c_late',
        turnNumber: 9,
        inputTokens: 9999,
        outputTokens: 9999,
      ));

      expect(ledger.length, lengthBefore,
          reason: 'a projection must not see later source mutations');
      expect(ledger.totalInputTokens, inputBefore);

      expect(() => ledger.entries.add(_fixture().first),
          throwsA(isA<UnsupportedError>()),
          reason: 'the entries view is unmodifiable');
    });
  });

  group('spec 083 — sub-ledgers are full projections (FR-006)', () {
    test('T6: byTurn(1) round-trips and equals an independent ledger', () {
      final ledger = UsageLedger(_fixture());
      final turnOne = ledger.byTurn(1);

      final independent = UsageLedger([
        _fixture()[0],
        _fixture()[1],
      ]);
      expect(turnOne, equals(independent));

      final roundTripped = UsageLedger.fromJson(turnOne.toJson());
      expect(roundTripped, equals(turnOne));
      expect(roundTripped.totalInputTokens, 300); // 100 + 200
    });

    test('T7 (pin): byModel(m).byTurn(t) totals equal the intersection',
        () {
      final ledger = UsageLedger(_fixture());
      final gpt4turn2 = ledger.byModel('gpt-4').byTurn(2);

      expect(gpt4turn2.length, 1); // e_3 only
      expect(gpt4turn2.totalInputTokens, 300);
      expect(gpt4turn2.totalOutputTokens, 120);
      expect(gpt4turn2.totalCacheReadTokens, 30);
      expect(gpt4turn2.totalCacheWriteTokens, 40);

      // A no-match chain is empty, not an error.
      expect(ledger.byModel('gpt-4').byTurn(3).isEmpty, isTrue);
    });
  });
}
