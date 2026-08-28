# Test List: Memory tools — the agent-facing surface

---
feature: 074-memory-tools
loop: outside-in
profile: .specify/memory/tdd-profile.md # referenced by sibling 023; file absent at HEAD — 023 artifact as de-facto rubric + constitution.md Principles II/V/X
spec_criteria: 9 # FR-001..FR-009 in spec.md
planned_at: 4dd76e2 # feat/spec-073-agent-memory HEAD (stack base)
updated_at: HEAD
suite_baseline: green # 925 passed / 2 skipped at 4dd76e2
---

## Outer loop: acceptance behaviors

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| A1  | End-to-end story through the TOOL surface only: dispatch `memory_remember` ×2 (one with session_id), `memory_link` between them, `memory_recall` finds both with layer lines, projection shows the top one | FR-002, FR-004, FR-005, FR-008 | example | PASSING | `test/engine/memory_tools_test.dart::spec 074 — MemoryTools::agent story: remember, link, recall, project` |
| A2  | Session routing: `session_id` argument writes to session memory (empty long-term store after), absent writes long-term | FR-002 | example | PASSING | `…::remember routes by session_id argument` |
| A3  | Failure results, never exceptions: missing content, whitespace content, bad salience, unknown tool, empty recall query, unknown link type, unknown link endpoint — each returns success:false with a non-empty error | FR-003, FR-004, FR-005 | example | PASSING | `…::model-shaped failures come back as failure results` |
| A4  | dispatchBatch: two remembers + one recall in one batch — 3 results in order, all succeed | FR-006 | example | PASSING | `…::dispatchBatch maps every call in order` |
| A5  | Prompt projection: top-2 by salience (desc) among 3 long-term memories; renderWithSession prepends capped session notes marked `[session]`; empty memory renders empty | FR-008 | example | PASSING | `…::projection ranks by salience and marks session notes` |
| A6  | Gates: `dart analyze --fatal-infos` exit 0; full `dart test` green (baseline 925/2 + new) | FR-009 | gate | PASSING | gates at branch HEAD (counts in verification.md) |

## Inner loop: unit behaviors

### `lib/src/engine/memory_tools.dart` (new)

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U1  | Declarations: three AgentTools, ids `memory_remember`/`memory_recall`/`memory_link`, RiskTier.safe, sequential mode, schemas declare the required params, descriptions non-empty; `declarations` unmodifiable | FR-001 | example | PASSING | `…::declarations are safe-tier typed tools` |
| U2  | remember happy path: auto id `mem-1`, `mem-2` from the counter; explicit `id` argument wins; tags + salience flow through; success result carries the id | FR-002 | example | PASSING | `…::remember generates ids and flows arguments` |
| U3  | recall happy path: line format `<layer> \| <id> \| salience <s> \| <content>`, ranking order from the system, limit honored | FR-004 | example | PASSING | `…::recall renders ranked layer-attributed lines` |
| U4  | link happy path: valid type string maps to MemoryLinkType; note flows; success result names from→to; self-link failure result | FR-005 | example | PASSING | `…::link validates and delegates to the system` |
| U5  | validateSchema: missing required key per tool reported; complete args valid; checkRiskTier true for any input | FR-007 | example | PASSING | `…::schema validation and risk tier` |

## Invariants and edge cases

- No-throw invariant: `dispatch` NEVER throws for model-shaped argument problems (A3) — the agent reads `error` and retries.
- Routing invariant: `session_id` present → session memory; absent → long-term (A2).
- Ordering invariants: recall = system ranking; projection = salience desc; session notes = insertion order (A5, U3).
- Auto-id monotonicity: counter increments per remember, never reused within a dispatcher (U2).
- Empty memory projects to an empty list — callers omit the section (A5).

## Mutation plan (deliberate, one at a time, cp-restored)

| id  | mutant | killed by |
| --- | ------ | --------- |
| M1  | remember dispatch returns success but never writes to the memory system | A1 (recall finds nothing) / A2 (store empty assertion) |
| M2  | recall limit ignored (returns everything) | U3 (capped line count) |
| M3  | link type hardcoded `relatesTo` regardless of the argument | U4 (typed assertion via graph.linksOf) |
| M4  | projection renders insertion order, not salience desc | A5 (top-2 would be wrong) |
| M5  | session_id argument ignored — everything long-term | A2 (session store empty after session-scoped write) |
