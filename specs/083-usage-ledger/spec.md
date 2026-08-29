# Feature Specification: R4: Usage Ledger — token accounting projection

**Branch**: `083-usage-ledger` (off master `29b7fef`) | **Date**: 2026-08-29

**Status**: Draft → implemented on this branch

**Input**: User description: "R4: Usage Ledger — token accounting projection.
A read-only aggregate projection over usage entries (input / output / cache
tokens) with byTurn and byModel sub-ledgers for budget tracking. Parent
epic: R4 providers & fallback (issue #5). Scope: the ledger aggregates token
usage entries into a read-only projection. It exposes totals plus per-turn
(byTurn) and per-model (byModel) sub-ledgers so budget/tracking logic can
query spend. All operations are pure projections over immutable entries;
define equality and serialization for engine/provider consumption."

## Summary

`UsageLedger` (lib/src/usage_ledger.dart, from T009) already aggregates
`UsageEntry` records into totals (`totalInputTokens`, `totalOutputTokens`,
`totalTokens`, `totalCacheReadTokens`, `totalCacheWriteTokens`) and
`byTurn(int)` / `byModel(String)` sub-ledgers, and is covered by
`test/usage_ledger_test.dart`. What the R4 contract (issue #94) asks for
that the class does not yet satisfy:

1. **It is not actually read-only.** The constructor aliases the caller's
   list (`const UsageLedger(this._entries)`), so a later mutation of the
   source list silently changes every previously-computed total — a
   projection over mutable state is not a projection.
2. **No equality.** Two ledgers over structurally-identical entries are
   unequal (identity `==`), so engine/provider code cannot compare budget
   snapshots, and sub-ledgers cannot be diffed.
3. **No serialization.** There is no `toJson`/`fromJson` on the ledger, so
   a budget snapshot cannot cross the engine/provider boundary (event
   payloads, persistence, logs).

This spec closes all three: the constructor defensively copies into a
`List.unmodifiable`, the ledger exposes an unmodifiable `entries` view,
equality is ordered-sequence equality defined through the serialized form
(so equality and serialization can never disagree), and `toJson`/`fromJson`
round-trip. All existing getters and sub-ledger semantics stay
byte-compatible.

**Out of scope**: changing `UsageEntry`/`UsageLedgerEntry`/`Model`
(their `toJson`/`fromJson` already exist and are reused); cost/price
projection (currencies are not part of the R4 seed); persistence wiring
(datasource/repo layers already exist under `lib/src/data/`).

## Files

- `lib/src/usage_ledger.dart` — EDIT: unmodifiable copy + `entries` getter +
  `toJson`/`fromJson` + `==`/`hashCode` (additive; existing getters and
  `byTurn`/`byModel` unchanged in behavior).
- `test/usage_ledger_083_test.dart` — NEW: equality, serialization
  round-trip, immutability, sub-ledger projections, chaining pin.
- `specs/083-usage-ledger/` — this artifact set.

## User scenarios

### US1 — Compare budget snapshots (P1)

As budget-tracking logic in the engine, I can compare two `UsageLedger`
snapshots for equality (and use them as map keys / in sets), where equality
means: same entries, in the same order, with structurally identical
contents — regardless of instance identity.

**Why this priority**: equality is the primitive every downstream consumer
(diffing, caching, assertions, dedup) needs; without it the projection
cannot be consumed safely.

**Independent test**: two ledgers built from separately-constructed but
structurally-identical entry lists are `==` and hash-equal; a ledger with
one different token count is not.

### US2 — Ship a snapshot across the boundary (P1)

As a provider/engine consumer, I can serialize a ledger (`toJson`) and
rebuild an equal one (`fromJson`) — totals, sub-ledgers, and equality all
survive the round trip, including cache tokens and the `null`-model case.

**Why this priority**: the ledger crosses process/layer boundaries
(events, persistence); without serialization it is trapped in memory.

**Independent test**: `UsageLedger.fromJson(ledger.toJson()) == ledger`,
and all five totals are identical after the round trip.

### US3 — Trust the projection (P2)

As any consumer, the ledger is immutable: mutating the list I constructed
it from changes nothing, and mutating `ledger.entries` throws. Sub-ledgers
(`byTurn`, `byModel`) are themselves read-only projections that chain.

**Why this priority**: a projection over mutable state produces
inconsistent totals; the read-only guarantee is what makes the aggregate
trustworthy.

**Independent test**: source-list mutation after construction leaves the
ledger's `length`/totals unchanged; `entries.add` throws
`UnsupportedError`; `byModel(...).byTurn(...)` totals equal the
intersection.

## Requirements

### Functional requirements

- **FR-001**: `UsageLedger` is constructed by defensive copy into an
  unmodifiable list; the caller's later mutations of the source list do
  not affect any previously-computed total, `length`, or sub-ledger.
- **FR-002**: `UsageLedger.entries` exposes the (unmodifiable) entry
  sequence for inspection; mutation attempts throw `UnsupportedError`.
- **FR-003**: `UsageLedger.toJson()` serializes the projection as
  `{'entries': [<UsageEntry.toJson>...]}`; `UsageLedger.fromJson` rebuilds
  an equal ledger. Round-trip preserves all five totals, sub-ledgers, and
  the `null`-model case.
- **FR-004**: Equality is ordered-sequence equality over structurally
  identical entries, defined via the serialized form (equal ledgers have
  equal `toJson`); `hashCode` is consistent with `==`.
- **FR-005**: Existing aggregate surface is unchanged:
  `totalInputTokens`, `totalOutputTokens`, `totalTokens`,
  `totalCacheReadTokens`, `totalCacheWriteTokens`, `byTurn(int)`,
  `byModel(String)`, `length`, `isEmpty`, `isNotEmpty` behave exactly as
  the T009 tests pinned (regression: the pre-existing
  `test/usage_ledger_test.dart` stays green unmodified).
- **FR-006**: Sub-ledgers are themselves full projections: `byTurn` /
  `byModel` results support equality, serialization, and chaining
  (`ledger.byModel(m).byTurn(t)` totals equal the entries matching both
  filters).
- **FR-007**: Edge cases: an empty ledger equals every other empty ledger,
  serializes/round-trips, and reports all totals as 0; `byTurn`/`byModel`
  with no matches return an empty ledger (not an error).
- **FR-008**: Gates — `dart analyze` reports no new issues relative to the
  master baseline (3 pre-existing, out of scope); the full `dart test`
  suite is green.

### Key entities

- `UsageLedger` — gains `entries`, `toJson`, `fromJson`, `==`, `hashCode`;
  constructor becomes defensively copying.
- `UsageEntry` / `UsageLedgerEntry` / `Model` — unchanged; their existing
  JSON forms are the ledger's serialization substrate.

## Success criteria

- **SC-001**: Structurally-identical ledgers are `==` (and hash-equal);
  any content difference breaks equality (US1).
- **SC-002**: `fromJson(toJson()) == ledger` with all totals and sub-ledger
  semantics preserved, including cache tokens and the `null`-model entry
  (US2).
- **SC-003**: Source-list mutation after construction and `entries`
  mutation both fail to alter the projection; chained sub-ledger totals
  are exact (US3).
- **SC-004**: Gates green (FR-008); the pre-existing
  `test/usage_ledger_test.dart` passes unmodified (FR-005).

## Dependencies

- Builds on: the T009 UsageLedger projection (master `29b7fef`) and the
  zfa-generated `UsageLedgerEntry` entity's existing JSON forms.
- Independent of: every other subsystem (the file is standalone under
  `lib/src/`, exported from `lib/zuraffa_agent.dart`).
