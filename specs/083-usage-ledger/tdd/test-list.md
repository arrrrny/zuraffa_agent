# Test List: Usage Ledger — token accounting projection (spec 083)

---
feature: 083-usage-ledger
loop: outside-in
profile: .specify/extensions/tdd/templates/tdd-test-quality-rubric.md
spec_criteria: 8 # FR-001..FR-008 in spec.md
planned_at: master (29b7fef)
updated_at: 083-usage-ledger
suite_baseline: green # 1073 passed / 2 skipped at 29b7fef
---

## Outer loop: acceptance behaviors

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| A1  | A budget snapshot is comparable and portable: structurally-identical ledgers are equal, and a ledger survives a `toJson`/`fromJson` round trip with totals, sub-ledgers, and equality intact | FR-003, FR-004, SC-001, SC-002 | example | PLANNED | `test/usage_ledger_083_test.dart` (T1–T4) |
| A2  | Gates: `dart analyze` clean vs baseline; full `dart test` green including the unmodified pre-existing `test/usage_ledger_test.dart` | FR-005, FR-008 | gate | PLANNED | gates at branch HEAD (counts in verification.md) |

## Inner loop: unit behaviors

### New surface (RED)

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U1  | Structurally-identical ledgers (distinct instances) are `==` and hash-equal | FR-004 | unit | PLANNED | T1 |
| U2  | Any content difference (one token count, empty vs non-empty) breaks equality | FR-004 | unit | PLANNED | T2 |
| U3  | `fromJson(toJson()) == ledger`; all five totals identical after the round trip; fixture includes cache tokens and a null-model entry | FR-003 | unit | PLANNED | T3 |
| U4  | Empty ledger: equals every other empty ledger, round-trips, totals 0, length 0; `byTurn`/`byModel` no-match → empty | FR-007 | unit | PLANNED | T4 |
| U5  | Immutability: source-list mutation after construction changes nothing; `entries` mutation throws `UnsupportedError` | FR-001, FR-002 | unit | PLANNED | T5 |
| U6  | Sub-ledgers are full projections: `byTurn(1)` round-trips and equals an independently-built ledger of the same entries | FR-006 | unit | PLANNED | T6 |

### Pin (existing behavior, previously unguarded)

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U7  | Chaining: `byModel(m).byTurn(t)` totals equal the entries matching both filters | FR-005, FR-006 | pin | PLANNED | T7 |

> **Pin honesty**: U7 chains `byTurn`/`byModel` behavior that ships on
> master (pinned by T009's value tests); it passes by design. The new
> equality/serialization assertions on sub-ledgers (U6) ARE red-first —
> they exercise the new members.

## Edge cases & invariants

- The null-model entry round-trips (its `toJson` omits the `model` key).
- Cache tokens (read AND write) survive the round trip (M2 guards).
- Entry order is significant: same entries in a different order are
  unequal ledgers (ordered-sequence equality).
- Equality is defined through the serialized form — equal ledgers have
  equal `toJson`.

## Out of scope

- `UsageEntry`/`UsageLedgerEntry`/`Model` changes (their JSON forms are
  the substrate).
- Cost/price projection; persistence wiring (`lib/src/data/`).
- The T009 value tests (kept unmodified as the FR-005 regression guard).

## Verification commands

```bash
dart analyze
dart test test/usage_ledger_083_test.dart
dart test test/usage_ledger_test.dart
dart test
```
