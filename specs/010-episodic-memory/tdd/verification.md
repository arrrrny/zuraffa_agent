---
feature: 010-episodic-memory
verdict: PASS_WITH_GAPS
standard: .specify/extensions/tdd/templates/tdd-test-quality-rubric.md # rubric graded against
verified_at: d5e5d20 # short SHA audited
behaviors: 16
proven: 11
likely: 0
test_after: 5
no_test: 0
high_smells: 0
criteria_total: 5
criteria_covered: 5
mutation_score: 100 # deliberate-mutant sampling: 3/3 killed (list-slice off-by-one, snapshot-branch drop, restore-filter invert)
mutants_survived: 0
suite: 469 passed, 6 failed (all 6 pre-date the feature: unrelated loading failures), 26s
---

# TDD Verification: Episodic Memory

**Verdict: PASS_WITH_GAPS.** All five acceptance criteria are covered through
the feature's real entry points (compressor, persistent store, tool), every
unit behavior had a genuine loading red before its implementation, and all
three deliberate mutants were killed. The gap: the five acceptance behaviors
landed after their underlying units were already green (by design of the
outside-in loop), so their own first reds were fixture repairs (A1, A5) or
never happened (A2-A4); they are mutant- and unit-covered instead.

## Test-first evidence

| Behavior | Class      | Evidence |
| -------- | ---------- | -------- |
| U1       | PROVEN     | loading-red (file missing), fixture API repaired pre-green; `63afeeb`/`f23a80d` |
| U2-U4    | PROVEN     | compile-red (`list` undefined) against the existing store; `4cd1bb9`; mutant killed (slice off-by-one) |
| U5-U8    | PROVEN     | loading-red (tool file missing); `01c5177`; mutant killed (snapshot branch dropped) |
| U9-U11   | PROVEN     | loading-red (persistent store missing); `06695c5`; mutant killed (restore filter inverted) |
| A1       | TEST_AFTER | first red was a test-arithmetic bug (threshold 10 vs 8 messages), repaired → green; underlying units PROVEN |
| A2       | TEST_AFTER | first-run pass; exercises U2/store retrieve through the public entity API |
| A3       | TEST_AFTER | first-run pass; exercises U9-U10 through restore() |
| A4       | TEST_AFTER | first-run pass; exercises U5-U6 through the tool + compressor |
| A5       | TEST_AFTER | first red was fixture arithmetic (round-2 history too short), repaired → green; exercises U7 |

## Findings

| # | Severity | Finding | Evidence |
| - | -------- | ------- | -------- |
| 1 | LOW | Five acceptance behaviors had no genuine red of their own (outside-in A-layer over already-green units); compensated by unit-level reds + 3/3 killed mutants | cycle log cycles 12-16 |
| 2 | LOW | `PersistentEpisodicMemoryStore.add` returns `Future<void>` while the base class returns `void` (legal — void is a top type): callers through the `EpisodicMemoryStore` static type fire-and-forget the storage write. The current compressor call site is synchronous-only, so a persistent store injected there would mirror writes racily; the awaited wiring belongs to the spec-002 engine integration | lib/src/llm/persistent_episodic_memory_store.dart:47 |

## Mutation testing summary

| Mutant | Applied to | Result |
| ------ | ---------- | ------ |
| `skip(offset)` → `skip(offset + 1)` | store.list slicing | KILLED (+2 -2) |
| snapshot_id branch → `if (false)` | tool.execute | KILLED (+2 -2) |
| restore filter `!=` → `==` | PersistentEpisodicMemoryStore.restore | KILLED (+1 -2) |

## Gates

- `dart analyze` — 111 issues, all pre-existing (baseline at branch point:
  111); zero in spec-010 files.
- `dart test` — +469 / -6; baseline +453 / -6; delta: +16 new passing,
  0 new failing.
- Constitution VII — no `dart:io` imports in spec-010 files.
- Constitution VIII — dart_agent_core-lineage attribution headers retained
  on the three new lib files.

## Remediation

- T017: When spec 002 wires the compressor into the engine loop with a
  persistent store, introduce an awaited persistence seam (or make
  `EpisodicMemoryStore.add` async across the board) so storage mirroring is
  not fire-and-forget.
