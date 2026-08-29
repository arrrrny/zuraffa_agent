# Implementation Plan: Usage Ledger — token accounting projection (spec 083)

**Branch**: `083-usage-ledger` | **Date**: 2026-08-29 | **Spec**:
`specs/083-usage-ledger/spec.md`

## Summary

Additive value-object completion of the existing `UsageLedger` projection:
defensive copy + unmodifiable `entries` view, `toJson`/`fromJson` over the
entries' existing JSON forms, and ordered-sequence equality defined THROUGH
the serialized form so equality and serialization cannot disagree. The
aggregate getters and `byTurn`/`byModel` are untouched.

## Technical Context

**Language/Version**: Dart 3.13.2 (SDK `^3.8.0`), pure Dart, no new
dependencies (`dart:convert` for `jsonEncode` is core).

**Primary Dependencies**: `UsageEntry` (lib/src/types.dart — has
`toJson`/`fromJson` incl. the `null`-model omission), `UsageLedgerEntry`
and `Model` entities (zfa-generated JSON), `test` ^1.25.

**Storage**: N/A (in-memory projection; the datasource/repo layers under
`lib/src/data/` are out of scope).

**Serialization determinism**: `UsageEntry.toJson` builds its map from a
fixed literal key order (Dart maps preserve insertion order), so
`jsonEncode` of the entry list is deterministic — a sound substrate for
equality.

## Components

### 1. Read-only guarantee (FR-001, FR-002)

```dart
class UsageLedger {
  final List<UsageEntry> _entries;
  UsageLedger(List<UsageEntry> entries) : _entries = List.unmodifiable(entries);
  List<UsageEntry> get entries => _entries;
  // …existing getters unchanged…
}
```

The `const` constructor is dropped (a `const` constructor cannot run
`List.unmodifiable`); the only call sites are the class's own `byTurn` /
`byModel` and tests, all non-const — verified by search.

### 2. Serialization (FR-003)

```dart
Map<String, dynamic> toJson() => {'entries': [for (final e in _entries) e.toJson()]};
factory UsageLedger.fromJson(Map<String, dynamic> json) => UsageLedger(
    [for (final e in (json['entries'] as List)) UsageEntry.fromJson(Map<String, dynamic>.from(e as Map))]);
```

No `_type` tag: the ledger is monomorphic (unlike the polymorphic
`SessionTreeEntry` family that needs one).

### 3. Equality through serialization (FR-004)

```dart
late final String _encoded = jsonEncode([for (final e in _entries) e.toJson()]);
@override
bool operator ==(Object other) =>
    identical(this, other) || (other is UsageLedger && _encoded == other._encoded);
@override
int get hashCode => _encoded.hashCode;
```

Lazy + memoized: sub-ledger construction (`byTurn`/`byModel`) stays cheap;
equality pays the encode once per instance at first use. Ordered-sequence
semantics: a ledger is an ordered projection, so entry order is
significant — documented in the spec.

### 4. Tests (`test/usage_ledger_083_test.dart` — NEW)

RED (new members missing → compile failure first; then, with members added
but no `==`, the equality/round-trip assertions fail):

- T1: structurally-identical ledgers (distinct instances) are `==` and
  hash-equal (US1).
- T2: one differing token count → not equal; empty vs non-empty → not
  equal (US1 negative).
- T3: `fromJson(toJson()) == ledger` + all five totals identical after the
  round trip, over a fixture that includes cache tokens AND a `null`-model
  entry (US2, SC-002).
- T4: empty ledger — equals every other empty ledger, round-trips, all
  totals 0, `length` 0 (FR-007).
- T5: immutability — source-list mutation after construction leaves
  `length`/totals unchanged; `entries.add` throws `UnsupportedError`
  (US3, SC-003).
- T6: sub-ledgers are full projections — `byTurn(1)` round-trips and
  equals an independently-built ledger of the same entries (FR-006).
- T7 (pin): chaining — `byModel('gpt-4').byTurn(2)` totals equal the
  entries matching both filters (existing behavior, unguarded).

### 5. Mutations (one at a time, cp-restored, each must KILL)

- M1: `==` compares lengths only → T1/T3 kill.
- M2: `fromJson` zeroes `cacheReadTokens`/`cacheWriteTokens` → T3 kills
  (totals + encoded form differ).
- M3: defensive copy removed (`_entries = entries` alias) → T5 kills.
- M4: `toJson` omits the `model` key → T3 kills (round-trip loses model →
  byModel differs). Applied by mutating `UsageEntry.toJson`'s conditional —
  if that proves invasive, mutate the ledger's `toJson` to drop entries
  with `model == null` instead (same kill path via T3's null-model fixture).

## Sequencing

1. `/speckit.specify` → spec.md (done).
2. RED — test file: compile failure on missing `toJson`/`fromJson`/
   `entries`; record. Add members WITHOUT `==`/`hashCode` → capture failing
   equality/round-trip assertions (T1, T3, T4, T6). Evidence →
   `tdd/cycle-log.md`.
3. GREEN — `==`/`hashCode` + defensive copy; target file 7/7.
4. Pin T7 verified green against unmodified chaining behavior.
5. Mutations M1–M4, one at a time, cp-restored.
6. Gates (`dart analyze`, full `dart test` incl. the unmodified
   pre-existing `test/usage_ledger_test.dart`), `tdd/verification.md`,
   commit + PR (base master).

## Risks / decisions

- **Dropping `const`**: no `const UsageLedger(` call sites exist (verified
  by search); the constructor signature otherwise unchanged.
- **Equality via `jsonEncode`**: costs one encode per instance at first
  equality/hash use; deterministic because entry `toJson` maps are built
  from fixed literal key orders. The alternative (hand-written field-wise
  deep equality over `UsageEntry`/`UsageLedgerEntry`/`Model`) duplicates
  the serialization logic and can drift from it — rejected.
- **`late final` memoization**: single-threaded event-loop Dart; no
  concurrency hazard.
- **Sub-ledger equality**: `byTurn`/`byModel` return `UsageLedger`, so they
  inherit the new equality/serialization automatically — no separate
  implementation to drift.
