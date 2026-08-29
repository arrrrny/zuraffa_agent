# TDD Cycle Log: Usage Ledger — token accounting projection (spec 083)

Append-only record of the red-green-refactor cycles. RED evidence quoted
verbatim from the failing runs.

## Cycle 1 — read-only copy + serialization + equality (U1–U6)

**Scope**: defensive copy + `entries` getter, `toJson`/`fromJson`,
`==`/`hashCode` through the encoded form. Tests T1–T7 written FIRST, in
full, before any production edit.

### RED

Step 1 — the test file alone (production untouched):

```
$ dart test test/usage_ledger_083_test.dart
test/usage_ledger_083_test.dart:156:40: Error: Member not found:
  'UsageLedger.fromJson'.
test/usage_ledger_083_test.dart:193:40: Error: Member not found:
  'UsageLedger.fromJson'.
test/usage_ledger_083_test.dart:239:40: Error: Member not found:
  'UsageLedger.fromJson'.
test/usage_ledger_083_test.dart:222:27: Error: The getter 'entries' isn't
  defined for the type 'UsageLedger'.
```

Step 2 — `toJson`/`fromJson`/`entries` + defensive copy added, `==` /
`hashCode` NOT yet:

```
$ dart test test/usage_ledger_083_test.dart
00:00 +3 -4: Some tests failed.

Failing tests:
  ... T1: structurally-identical ledgers are == and hash-equal
  ... T3: fromJson(toJson()) == ledger with all five totals preserved
  ... T4: empty-ledger edge — equal, round-trips, zero totals
  ... T6: byTurn(1) round-trips and equals an independent ledger
```

4 failing (identity `==` makes equal-content ledgers unequal — exactly the
US1 gap), 3 passing (T2 inequality holds trivially under identity, T5
immutability already green from the copy, T7 chaining pin).

### GREEN

`==`/`hashCode` via the lazy memoized `_encoded` (jsonEncode of the entry
toJson sequence):

```
$ dart test test/usage_ledger_083_test.dart
00:00 +7: All tests passed!
$ dart test test/usage_ledger_test.dart   # pre-existing T009 suite, UNMODIFIED
00:00 +11: All tests passed!
```

### REFACTOR

Reviewed; no extraction needed (the file is 97 lines, single
responsibility). Doc comments tie each member to its FR. No behavior
change.

## Cycle 2 — pin (U7)

T7 (chaining `byModel(m).byTurn(t)`) pins existing behavior that ships
unguarded on master; passes by design, justified by the T009 value tests +
its own literal-arithmetic assertions. No production change.

## Mutations (deliberate, one at a time, cp-restored)

| id  | mutant | result | evidence |
| --- | ------ | ------ | -------- |
| M1  | `==` compares entry counts only | KILLED by T2 | different-content same-length fixture passed as equal → `[E]` on T2 |
| M2  | `UsageLedgerEntry.fromJson` zeroes `cacheReadTokens` | KILLED by T3 + T6 | 2 failures — round-trip loses cache-read (totals + encoded form differ) |
| M3  | defensive copy removed (`_entries = entries`) | KILLED by T5 | source-list mutation visible through the ledger → `[E]` on T5 |
| M4  | `UsageEntry.toJson` omits the `model` key | KILLED by T3 | round-trip loses models → byModel counts wrong + encoded form differs |

(A first attempt at M2 mutated hand-written code against `final` entity
fields and failed to compile; redone as a behavioral mutant against the
generated `fromJson` — the compile-failure attempt was discarded, not
counted.)

After each restore the target file returned to 7/7 green.

## Gates

```
$ dart analyze            # 3 issues — identical to master baseline (out of scope)
$ dart test               # 00:40 +1080 ~2: All tests passed!
```

Baseline at master `29b7fef` was 1073 passed / 2 skipped; +7 new tests
(the pre-existing 11-test T009 suite passes unmodified).
