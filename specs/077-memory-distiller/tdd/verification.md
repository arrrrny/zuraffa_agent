# Verification: Memory distiller (spec 077)

---
feature: 077-memory-distiller
loop: outside-in
profile: .specify/memory/tdd-profile.md # referenced by sibling 023; file absent at HEAD — 023 artifact as de-facto rubric + constitution.md Principles II/V/X
executed_at: feat/spec-077-memory-distiller (off feat/spec-076-memory-persistence fdc9f89)
gates:
  analyze: "dart analyze --fatal-infos → No issues found! (exit 0)"
  tests: "dart test → 945 passed / 0 failed / 2 skipped (baseline 935/2 at fdc9f89, +10 new)"
---

## Cycle integrity

- **RED (genuine)**: `test/engine/memory_distiller_test.dart` written first
  and run against a missing library —
  `Error when reading 'lib/src/engine/memory_distiller.dart': No such file
  or directory`, then `DistillationPolicy` / `MemoryDistiller` /
  `SkipReason` not-found errors, exit 1.
- **GREEN**: implementation landed; target file 10/10 on the first full
  run, `dart analyze` clean throughout.
- Two test-side design fixes BEFORE the first run (process finding #1):
  (a) `mid` in the cap test needed a distinct `createdAt` — with the
  default it tied `tie-old` exactly, making the expected order
  ambiguous under any sort; (b) a self-contradictory double assertion in
  the report test (`isNot(equals)` followed by `equals` on identical
  content) was replaced by a positive + negative pair. Neither change
  weakened a pin — both strengthened determinism.
- All mutation runs executed in this session with outputs captured
  verbatim; every mutant cp-restored and re-verified 10/10 green before
  the next.

## Acceptance criteria → tests (all FRs traced)

| FR | Test (test/engine/memory_distiller_test.dart) | Result |
| --- | --- | --- |
| FR-001 policy value semantics + validation | `DistillationPolicy defaults and validation` | PASS |
| FR-002 gate + identity-preserving promotion | `distills a mixed-salience session — gate, identity, residue` | PASS |
| FR-003 boundary == threshold promotes (default 0.7) | `boundary salience equal to threshold promotes; default is 0.7` | PASS |
| FR-004 duplicate guard (normalized, live store) | `duplicate guard skips content already known to long-term` + `same-content session siblings dedupe within one run` | PASS |
| FR-005 cap + ranking (salience desc, older first) | `cap promotes the best N — salience desc, older first among equals` | PASS |
| FR-006 below-threshold skipped + stays | `distills a mixed-salience session…` (weak-1/weak-2) | PASS |
| FR-007 idempotency | `distill is idempotent — no double promotion, no duplicates` | PASS |
| FR-008 unknown session → empty report | `unknown session distills to an empty report` | PASS |
| FR-009 report full accounting + value semantics | `DistillationReport accounts for every record` | PASS |
| FR-010 durability over 076 stores | `distilled knowledge is durable across a store rebuild` | PASS |
| FR-011 gates | analyze clean; 945/2 | PASS |

## Mutation results (deliberate, one at a time, cp-restored)

| id | mutant | result | evidence (test file run) |
| -- | ------ | ------ | ------------------------ |
| M1 | salience gate inverted (`<` instead of `>=`) | **KILLED** | +2 −8: `Expected: ['good-1','good-2'] Actual: ['weak-2','weak-1']` — the weak records get promoted instead |
| M2 | duplicate guard dropped (`if (false)`) | **KILLED** | +8 −2: `Expected: ['fresh-1'] Actual: ['dup-1','fresh-1']` (known content re-promoted); sibling dedup `Expected: ['first'] Actual: ['first','second']` |
| M3 | cap not enforced (check + budget decrement removed) | **KILLED** | +8 −2: `Expected: ['top','tie-old'] Actual: ['top','tie-old','mid','tie-new','low']` — all five promoted under cap 2 |
| M4 | ranking inverted (salience asc, newer first) | **KILLED** | +6 −4: promotion-order assertions fail across the suite (`Expected: ['good-1','good-2'] Actual: ['good-2','good-1']`) |
| M5 | promote never called (report fabricated) | **KILLED** | +3 −7: long-term assertions fail (`Expected: length <2>` — store never grew); the never-growing store also breaks sibling dedup (`Actual: ['first','second']`) |

**5/5 killed.**

## Gates (actual runs at branch HEAD)

- `dart analyze --fatal-infos` → **No issues found!** (exit 0)
- `dart test` → **945 passed / 0 failed / 2 skipped** (2 pre-existing
  KIMI_API_KEY skips, unrelated)

## Findings

1. **Test-side determinism fixes before first run (process, minor).** The
   cap test originally gave `mid` the default `createdAt`, tying
   `tie-old` exactly — the expected promotion order was then ambiguous.
   Fixed by giving `mid` its own timestamp (Feb), which also makes the
   age tie-break meaningfully tested (older record wins despite being
   remembered later). The report test's contradictory assertion pair was
   replaced with a proper positive/negative equality pair.
2. **Duplicate check runs against the LIVE long-term store** (design).
   No separate seen-set: each promotion lands in long-term immediately,
   so same-content session siblings dedupe against each other mid-run —
   pinned by the sibling test, and re-proven by mutant M5's side effect
   (never-promoting broke sibling dedup too).
3. **Duplicate reason outranks cap reason** (design). When a record is
   both a duplicate and out of budget, `duplicateOfLongTerm` is reported:
   a duplicate is not promotable even with budget left, so the more
   informative reason wins.
4. **Total, deterministic ranking** (design). Salience desc → createdAt
   asc → session insertion order. Dart's `List.sort` is not guaranteed
   stable, so insertion index is an explicit final tie-break — FIFO among
   full ties.

## Verdict

**PASS.** All 11 FRs traced to passing tests; RED was genuine (missing
library); 5/5 mutants killed with verbatim evidence; gates clean at 945/2
(baseline 935/2 + 10).
