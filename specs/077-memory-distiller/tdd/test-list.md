# Test List: Memory distiller (spec 077)

---
feature: 077-memory-distiller
loop: outside-in
profile: .specify/memory/tdd-profile.md # referenced by sibling 023; file absent at HEAD — 023 artifact as de-facto rubric + constitution.md Principles II/V/X
spec_criteria: 11 # FR-001..FR-011 in spec.md
planned_at: feat/spec-076-memory-persistence (fdc9f89)
updated_at: feat/spec-077-memory-distiller (all A/U behaviors green, 5/5 mutants killed)
suite_baseline: green # 935 passed / 2 skipped at fdc9f89 (076 branch tip)
---

## Outer loop: acceptance behaviors

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| A1  | Mixed-salience session distilled: >= threshold promoted into long-term with identity preserved, below stays in session | FR-002, FR-006 | example | PASSING | `test/engine/memory_distiller_test.dart::spec 077 — distiller::distills a mixed-salience session — gate, identity, residue` |
| A2  | Duplicate guard: content equal (trim + case-fold) to an existing long-term record is skipped duplicateOfLongTerm, not re-promoted; same-content session siblings dedupe within the run | FR-004 | example | PASSING | `…::duplicate guard skips content already known to long-term` |
| A3  | Cap: maxPerSession 2 with 3 candidates → top-2 by salience promoted, third skipped capReached; ties broken older-first | FR-005 | example | PASSING | `…::cap promotes the best N — salience desc, older first among equals` |
| A4  | Idempotency: second distill promotes nothing new and long-term is unchanged | FR-007 | example | PASSING | `…::distill is idempotent — no double promotion, no duplicates` |
| A5  | Durability (076 payoff): distill over persistent stores → rebuild → promoted records still long-term | FR-010 | example | PASSING | `…::distilled knowledge is durable across a store rebuild` |
| A6  | Gates: `dart analyze --fatal-infos` exit 0; full `dart test` green (baseline 935/2 + new) | FR-011 | gate | PASSING | gates at branch HEAD (counts in verification.md) |

## Inner loop: unit behaviors

### `lib/src/engine/memory_distiller.dart` (new)

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U1  | Policy value semantics + defaults (threshold 0.7, cap null) + validation | FR-001 | unit | PASSING | `…::DistillationPolicy defaults and validation` |
| U2  | Boundary: salience == threshold promotes; default threshold pinned at 0.7 (0.69 stays, 0.70 goes) | FR-003 | unit | PASSING | `…::boundary salience equal to threshold promotes; default is 0.7` |
| U3  | Report accounting: every snapshot record appears in promoted or skipped with the right reason; sessionRemaining reflects the residue | FR-009 | unit | PASSING | `…::DistillationReport accounts for every record` |
| U4  | Unknown / empty session → empty report, no throw | FR-008 | unit | PASSING | `…::unknown session distills to an empty report` |

## Edge cases & invariants

- Ranking stability: equal salience → createdAt asc (older first, FIFO).
- Duplicate normalization: trim + toLowerCase; tags/salience NOT part of
  the duplicate key (content only).
- Report lists promoted ids in promotion (ranking) order.
- Promotions route through the facade — links and layer attribution of
  promoted records follow 073 semantics untouched.

## Out of scope

- Async/scheduled distillation (no event infra in the memory module).
- Salience mutation/boosting on promotion (identity is preserved).
- Cross-session duplicate sweeping beyond the live long-term check.

## Verification commands

- Single test: `dart test {file} -n "{name}"`
- Full suite: `dart test`
- Analyze: `dart analyze --fatal-infos`
