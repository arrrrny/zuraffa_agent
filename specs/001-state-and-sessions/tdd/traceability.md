# Traceability: 001-state-and-sessions

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:f1effe95428daa57bc37dd199857fa45b4b33747f295655e0c511485648ad17e
statements: 15
automated: 15
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 25 | 1. **Given** a completed mission, **When** inspected, **Then** every turn, message, tool invocation, and usage record is a distinct typed entity retrievable independently by identity. | A1 | automated |
| AC-2 | 26 | 2. **Given** a mission's state persisted and reloaded, **When** entities are deserialized, **Then** each equals its pre-persistence value as a typed object — no untyped map escapes anywhere in the entity API. | A2 | automated |
| AC-3 | 40 | 3. **Given** a session at entry N, **When** forked, **Then** the new branch shares ancestry entries 1..N with the original and diverges cleanly after N; both branches remain resumable. | A3 | automated |
| AC-4 | 41 | 4. **Given** two diverged branches, **When** switching between them, **Then** `buildContext()` reconstructs each branch's conversation exactly — the original branch matches its pre-fork history, with no cross-contamination. | A4 | automated |
| AC-5 | 42 | 5. **Given** a persisted session, **When** the engine restarts, **Then** the session resumes from its latest leaf. | A5 | automated |
| AC-6 | 43 | 6. **Given** the same session tree persisted to both the Hive and JSONL stores, **When** each store is reloaded, **Then** both yield the identical branch structure and entries (round-trip equivalence). | A6 | automated |
| AC-7 | 57 | 7. **Given** context usage crossing the compaction threshold, **When** compaction runs, **Then** decisions, tool names, key results, and plan state survive verbatim, and discarded verbose material is replaced by structured summaries that reference retrievable artifacts. | A7 | automated |
| AC-8 | 58 | 8. **Given** the fixture mission suite, **When** compacted runs are compared to uncompacted baselines, **Then** mission outcomes are equal and context usage stays under the configured budget across the full 50+ tool calls. | A8 | automated |
| AC-9 | 72 | 9. **Given** the pi_agent source (branch `001-dart-agent-package`), **When** merged, **Then** types/tools/session-tree/SSE/skills/templates carry attribution headers and pass the engine's test suite. | A9 | automated |
| AC-10 | 73 | 10. **Given** pi_agent's unwired loop stub, **When** the merge completes, **Then** no stub code ships — the live loop is delivered by spec 002 (engine core), not ported as a stub. | A10 | automated |
| FR-001 | 87 | - **FR-001**: State MUST be granular typed entities (session/message/turn/invocation/usage), defined through Zorphy per constitution IX — no monolithic blob, no untyped map escapes. | U1 | automated |
| FR-002 | 88 | - **FR-002**: Sessions MUST form a tree with first-class branch, fork, switch, and resume. | U2 | automated |
| FR-003 | 89 | - **FR-003**: Persistence MUST ship Hive (device) and JSONL (debug/CI) datasources behind one storage interface. | U3 | automated |
| FR-004 | 90 | - **FR-004**: Compaction MUST be selective and structured (retain/summarize/artifact-ref), never naive truncation. | U4 | automated |
| FR-005 | 91 | - **FR-005**: pi_agent assets MUST be merged with attribution; stubs replaced, not shipped. | U5 | automated |

