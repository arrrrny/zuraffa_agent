# Feature Specification: State & Sessions

**Feature Branch**: `001-state-and-sessions`

**Created**: 2026-08-18

**Status**: Draft

**Input**: Epic arrrrny/zuraffa_agent#1 §R2 — converted from issue #3. Ported pi_agent assets land here first (they seed the whole engine's types).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Granular typed state (Priority: P1)

As the engine, I persist agent state as granular typed entities — `AgentSession` (tree-of-entries, branching), `AgentMessage` (multimodal parts), `TurnRecord`, `ToolInvocation`, `UsageLedger` — never a monolithic state blob.

**Why this priority**: dart_agent_core's `AgentState` blob was the #1 audit rejection; granular entities are the zuraffa-native contract everything else consumes.

**Independent Test**: A mission's full state round-trips through the entity model with no `Map<String, dynamic>` escapes.

**Acceptance Scenarios**:

1. **Given** a completed mission, **When** inspected, **Then** every turn, message, tool invocation, and usage record is a distinct typed entity retrievable independently.

### User Story 2 - Branching session tree with fork/resume (Priority: P1)

As a user, I branch a session (explore an alternative strategy), later resume either branch — pi_agent's session tree model (tree-of-entries, JSONL) ported onto Hive + JSONL stores.

**Why this priority**: Sub-agents (spec 005) and eval replay (spec 006) both depend on branch/fork/resume.

**Independent Test**: Branch → diverge 2 turns → resume original branch → context reconstruction matches the pre-fork history exactly.

**Acceptance Scenarios**:

1. **Given** session at entry N, **When** forked, **Then** a new branch shares ancestry and diverges cleanly.
2. **Given** two branches, **When** switching, **Then** `buildContext()` reconstructs each branch's conversation without cross-contamination.
3. **Given** a persisted session, **When** the engine restarts, **Then** the session resumes from its latest leaf.

### User Story 3 - Selective compaction (Priority: P1)

As the engine, when context approaches the budget, I compact selectively — retain decisions, tool names, key results, plan state; discard verbose outputs via structured summaries + artifact refs — extending trajectories from ~10 to 50+ iterations (Kimi-Researcher pattern).

**Why this priority**: Without compaction, long missions die at the context window; naive truncation loses the mission.

**Independent Test**: A 50+ tool-call fixture mission stays under its context budget with no outcome regression versus the uncompacted baseline.

**Acceptance Scenarios**:

1. **Given** context usage crossing the threshold, **When** compaction runs, **Then** retained categories survive (decisions/tool names/key results/plan) and discarded material is replaced by structured summaries.
2. **Given** a fixture mission suite, **When** compacted runs are compared to baseline, **Then** outcome equality holds.

### User Story 4 - pi_agent seed merge (Priority: P1)

As the maintainer, I merge pi_agent's production-quality assets into the engine repo with attribution: sealed-class type system (`types.dart`), session tree + JSONL storage, skills (SKILL.md loading), prompt templates, ExecutionEnv, SSE parser.

**Why this priority**: R1 and R3 build on these types; the seed must land before the loop completes.

**Independent Test**: Seed lands as library code with tests; zero stub code remains (pi_agent's unwired loop stub is replaced, not shipped).

**Acceptance Scenarios**:

1. **Given** the pi_agent source (branch `001-dart-agent-package`), **When** merged, **Then** types/tools/session-tree/SSE/skills/templates carry attribution headers and pass the engine's test suite.

### Edge Cases

- Compaction triggered mid-tool-batch → runs only at turn boundaries (never inside a batch).
- Branch deleted while another references its ancestry → ancestry entries are retained (refcounted), leaf-only entries pruned.
- Corrupt JSONL tail → store loads to the last valid entry and reports the tear.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: State MUST be granular typed entities (session/message/turn/invocation/usage) — no monolithic blob.
- **FR-002**: Sessions MUST form a tree with first-class branch, fork, switch, and resume.
- **FR-003**: Persistence MUST ship Hive (device) and JSONL (debug/CI) datasources behind one storage interface.
- **FR-004**: Compaction MUST be selective and structured (retain/summarize/artifact-ref), never naive truncation.
- **FR-005**: pi_agent assets MUST be merged with attribution; stubs replaced.

### Key Entities

- **AgentSession / SessionTreeEntry**: branching conversation container (entry types: message, thinking-level change, model change, compaction, label, custom).
- **AgentMessage**: multimodal parts (text, image, audio, document).
- **UsageLedger**: per-call token accounting consumed by budgets (plugin policy shell).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Branch/fork/resume round-trip on Hive and JSONL stores (issue #3 AC).
- **SC-002**: 50+ tool-call fixture mission under context budget with no outcome regression (AC).
- **SC-003**: Entities granular + typed; no state-blob escapes (AC).
- **SC-004**: pi_agent seed merged with attribution; zero stub code (AC).

## Assumptions

- Compaction summaries may reference artifacts stored by tool-result discipline (spec 003).
- Usage ledger format feeds the plugin's MissionBudgetHook (arrrrny/zuraffa#387).

## Dependencies

- Issue: arrrrny/zuraffa_agent#3 · Epic: #1 · Shares types with: spec 001 · Feeds: specs 003/005/006, policy shell (arrrrny/zuraffa#387)
