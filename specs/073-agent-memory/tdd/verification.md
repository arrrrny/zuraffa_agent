# Verification: Agent memory — three layers

---
feature: 073-agent-memory
loop: outside-in
profile: .specify/memory/tdd-profile.md # referenced by sibling 023; file absent at HEAD — 023 artifact as de-facto rubric + constitution.md Principles II/V/X
executed_at: feat/spec-073-agent-memory (off master fec7889)
gates:
  analyze: "dart analyze --fatal-infos → No issues found! (exit 0)"
  tests: "dart test → 925 passed / 0 failed / 2 skipped (baseline 915/2 at fec7889, +10 new)"
---

## Cycle integrity

- **RED (genuine)**: `test/engine/agent_memory_test.dart` written first and
  run against a missing library — `Error when reading
  'lib/src/engine/agent_memory.dart': No such file or directory`, then
  `MemorySource`/`MemoryRecord` undefined, exit 1.
- **GREEN**: implementation landed; file +10. Two honest compile-fix
  iterations during GREEN (constructor fields initialized both in the
  parameter list and the initializer list — Dart rejects that; fixed by
  moving `content`/`tags`/`createdAt`/`salience` to plain parameters with
  initializer-list validation), then all green first full run.
- All mutation runs executed in this session with outputs captured
  verbatim; every mutant cp-restored and re-verified green before the
  next.

## Acceptance criteria → tests (all FRs traced)

| FR | Test (test/engine/agent_memory_test.dart) | Result |
| --- | --- | --- |
| FR-001 record/source/link/hit value semantics + validation | `value objects carry house semantics and validation` | PASS |
| FR-002 long-term store | `LongTermMemoryStore replaces, ranks, and filters` | PASS |
| FR-003 session store (scoping, relocation, evaporate) | `SessionMemoryStore scopes by session with global id uniqueness` | PASS |
| FR-004 link types + direction | `value objects…` (a supports b ≠ b supports a) + `MemoryGraph traverses…` | PASS |
| FR-005 graph traversal/filters/idempotence | `MemoryGraph traverses both directions and filters by type`; `link validates endpoints and stays idempotent` | PASS |
| FR-006 facade routing | `three-layer story…` (long-term + session writes) | PASS |
| FR-007 recall across layers, ranking, limit, empty guard | `three-layer story…`; `recall ranks by salience then recency across both layers`; `recall honors the limit and rejects empty queries` | PASS |
| FR-008 link integrity + linked resolution | `link validates endpoints…`; `forgetSession evaporates…` (dangling → null record) | PASS |
| FR-009 promote move semantics | `promote moves a session memory into long-term` | PASS |
| FR-010 gates | analyze clean; 925/2 | PASS |

## Mutation results (deliberate, one at a time, cp-restored)

| id | mutant | result | evidence (test file run) |
| -- | ------ | ------ | ------------------------ |
| M1 | recall returns insertion order (salience/createdAt ranking dropped) | **KILLED** | +8 −2: three-layer story `Expected: 'note-1' Actual: 'fact-1'`; ranking test `Expected: ['lt-high','s-high','lt-low'] Actual: ['lt-high','lt-low','s-high']` |
| M2 | recall searches long-term only (session layer skipped) | **KILLED** | +8 −2: `Expected: length 2 Actual: [fact-1]` (session hit vanished); ranking `Actual: ['lt-high','lt-low']` |
| M3 | promote copies to long-term but record stays in session store | **KILLED** | +9 −1: post-promote recall `Expected: length 2` fails (note still session-attributed) |
| M4 | neighborsOf returns outgoing links only | **KILLED** | +8 −2: `Expected: length 3 Actual: [a supports b, a derivedFrom d]` (incoming contradicts invisible); dangling-link test `Actual: []` |
| M5 | duplicate (from,to,type) link throws instead of idempotent replace | **KILLED** | +8 −2: `MemoryGraph traverses…` and `link validates endpoints and stays idempotent` both fail on the duplicate throw |

**5/5 killed.**

## Gates (actual runs at branch HEAD)

- `dart analyze --fatal-infos` → **No issues found!** (exit 0)
- `dart test` → **925 passed / 0 failed / 2 skipped** (2 pre-existing KIMI_API_KEY skips, unrelated)

## Findings

1. **GREEN-phase compile iterations (process, minor).** Two analyze
   failures during the first GREEN run: Dart forbids initializing a
   constructor parameter field both in the parameter list and the
   initializer list (`field_initialized_in_parameter_and_initializer` for
   `salience`, then `tags`). Fixed by demoting those to plain parameters
   validated in the initializer list — validation semantics unchanged.
   No test was touched during these fixes.
2. **SessionMemoryStore relocation semantics** (design decision pinned by
   U3): record ids are globally unique across the session store —
   re-remembering an existing id under a different session relocates the
   record rather than duplicating it. This keeps `byId`/`remove`
   unambiguous and matches the graph's id-based references.
3. **Dangling links are honest, not hidden**: `forgetSession` leaves the
   graph untouched; `linked` resolves a dead endpoint to `null` record
   and `null` layer instead of filtering the link out (A6 asserts this).
   The alternative — cascading link deletion — would silently rewrite
   history; rejected deliberately.

## Verdict

**PASS** — FR-001..FR-010 all traced to passing tests; 5/5 deliberate
mutants killed; both gates clean at branch HEAD; genuine RED first.
