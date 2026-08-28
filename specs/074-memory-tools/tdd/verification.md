# Verification: Memory tools — the agent-facing surface

---
feature: 074-memory-tools
loop: outside-in
profile: .specify/memory/tdd-profile.md # referenced by sibling 023; file absent at HEAD — 023 artifact as de-facto rubric + constitution.md Principles II/V/X
executed_at: feat/spec-074-memory-tools (stacked on feat/spec-073-agent-memory @ 4dd76e2)
gates:
  analyze: "dart analyze --fatal-infos → No issues found! (exit 0)"
  tests: "dart test → 935 passed / 0 failed / 2 skipped (baseline 925/2 at 4dd76e2, +10 new)"
---

## Cycle integrity

- **RED (genuine)**: `test/engine/memory_tools_test.dart` written first and
  run against a missing library — `Error when reading
  'lib/src/engine/memory_tools.dart': No such file or directory`, then
  `MemoryTools`/`MemoryToolDispatcher` undefined, exit 1.
- **GREEN**: implementation landed; file +10 ALL PASSING on the first
  full run (no compile iterations this cycle); analyze clean first try.
- All mutation runs executed in this session with outputs captured
  verbatim; every mutant cp-restored and re-verified green before the
  next.

## Acceptance criteria → tests (all FRs traced)

| FR | Test (test/engine/memory_tools_test.dart) | Result |
| --- | --- | --- |
| FR-001 declarations | `declarations are safe-tier typed tools` | PASS |
| FR-002 remember dispatch + routing | `remember generates ids and flows arguments`; `remember routes by session_id argument` | PASS |
| FR-003 failure results not exceptions | `model-shaped failures come back as failure results` (7 cases) | PASS |
| FR-004 recall lines + limit | `recall renders ranked layer-attributed lines` | PASS |
| FR-005 link dispatch | `link validates and delegates to the system` | PASS |
| FR-006 dispatchBatch | `dispatchBatch maps every call in order` | PASS |
| FR-007 validateSchema + checkRiskTier | `schema validation and risk tier` | PASS |
| FR-008 prompt projection | `projection ranks by salience and marks session notes` | PASS |
| FR-009 gates | analyze clean; 935/2 | PASS |
| (story) end-to-end through the tool surface | `agent story: remember, link, recall, project` | PASS |

## Mutation results (deliberate, one at a time, cp-restored)

| id | mutant | result | evidence (test file run) |
| -- | ------ | ------ | ------------------------ |
| M1 | remember returns success but never writes to the memory system | **KILLED** | +3 −7: store-empty assertions, recall `no memories match`, projection and story tests all fail — the write path is heavily pinned |
| M2 | recall limit parsed but ignored | **KILLED** | +9 −1: `Expected: length 1` (two lines returned) |
| M3 | link type hardcoded `relatesTo` after validation | **KILLED** | +9 −1: `graph.linksOf(MemoryLinkType.supports)` empty — the typed assertion catches the swap |
| M4 | projection renders insertion order, not salience desc | **KILLED** | +9 −1: top-2 `Expected: contains 'high note'` — 'low note' ranked first |
| M5 | session_id argument ignored (everything long-term) | **KILLED** | +7 −3: session store empty after session-scoped write; renderWithSession length 4 vs 2; story recall lines wrong |

**5/5 killed.**

## Gates (actual runs at branch HEAD)

- `dart analyze --fatal-infos` → **No issues found!** (exit 0)
- `dart test` → **935 passed / 0 failed / 2 skipped** (2 pre-existing KIMI_API_KEY skips, unrelated)

## Findings

1. **M1's blast radius** (+3 −7) is the healthiest signal of the cycle:
   the write path is asserted by store-count, recall, projection, batch,
   and story tests — a silent no-op write cannot survive.
2. **Failure results, not exceptions** (FR-003) is a deliberate contract:
   model-generated arguments are untrusted input; `ArgumentError`s from
   the memory system (spec 073's validation) are caught at the dispatcher
   boundary and converted to `success: false` results so the LLM can
   read the reason and retry. Programmer errors still throw.
3. **Auto-id discipline**: `mem-<n>` ids are per-DISPATCHER counter state;
   cross-referencing memories across dispatchers requires explicit `id`
   arguments (documented in plan.md; the link tool tests use explicit
   ids for exactly this reason).

## Verdict

**PASS** — FR-001..FR-009 all traced to passing tests; 5/5 deliberate
mutants killed; both gates clean at branch HEAD; genuine RED first;
GREEN on first full run.
