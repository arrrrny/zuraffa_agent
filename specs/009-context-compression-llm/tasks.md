# Tasks: Context Compression (LLM-based)

**Input**: Design documents from `/specs/009-context-compression-llm/`

**Prerequisites**: plan.md (required), spec.md (required for user stories)

**Tests**: MANDATORY — one behavior per red (per the 007/008 verification remediations).

## Phase 1: Episodic memory entity + store (US2)

- [X] T001 [U1] Test: EpisodicMemory value object (id, summary XML, original messages; JSON round-trip)
- [X] T002 [U1] Implement the @Zorphy entity + run build_runner (generated code committed)
- [X] T003 [U2] Test: EpisodicMemoryStore add/retrieve-by-id/search returns the snapshot with its original messages
- [X] T004 [U2] Implement `lib/src/llm/episodic_memory_store.dart`

## Phase 2: Compressor core (US1)

- [X] T005 [U3] Test: below tokenThreshold → identity result (strategy none, no LLM call, no memory entry)
- [X] T006 [U3] Implement threshold gate + identity result
- [X] T007 [U4] Test: above threshold → LLM called once; recent keepRecentMessages preserved verbatim; older messages compressed
- [X] T008 [U4] Implement the compress path (split, LLM call, result assembly, store entry)
- [X] T009 [U5] Test: the compression prompt names the five XML sections and carries the older messages
- [X] T10 [U5] Implement prompt construction
- [X] T011 [U6] Test: an invalid XML snapshot (missing sections) falls back to the heuristic summarizer
- [X] T012 [U6] Implement snapshot validation + fallback
- [X] T013 [U7] Test: an LLM error falls back to the heuristic summarizer (SC-003)
- [X] T014 [U7] Implement error fallback

## Phase 3: Snapshot contract + thresholds (US1/US3)

- [X] T015 [U8] Test: compression creates an EpisodicMemory entry (snapshot + original messages) retrievable from the store
- [X] T016 [U8] Implement memory creation + store wiring
- [X] T017 [U9] Test: a 100-message conversation compresses to <3000 total tokens (SC-001)
- [X] T018 [U9] Verify/implement budget compliance (snapshot size + preserved slice)
- [X] T019 [U10] Test: tokenThreshold 32000 triggers where 64000 does not; messageCountThreshold honored (AC-5)
- [X] T020 [U10] Implement configurable thresholds
- [X] T021 [U11] Test: heuristic fallback result also creates a memory entry and preserves recent messages (path parity)
- [X] T022 [U11] Implement fallback path parity

## Phase 4: Closing gates

- [X] T023 [A1][A2][A3][A4][A5] Outer-loop acceptance check: AC-1..AC-5 green through the compressor's public API
- [X] T024 `dart analyze` pristine for all files added by this feature (SC-004)
- [X] T025 Full-suite delta check vs the spec-008 baseline (442/-6 → +N passing, still 6 unrelated failures); commit spec-kit artifacts

---

## Phase 5: TDD remediation (from tdd/verification.md — verdict: FAIL)

- [ ] T026 [MED, process] For future compressor work, isolate one behavior per red — the bundled greens (U3/U4/U6) left nine tests without their own reds. Proven by: cycle logs with a red per behavior.
- [ ] T027 [LOW] Always assert a deliberate mutant actually applied before reading its test result (one silent no-op was initially read as a survivor). Proven by: mutant scripts asserting the pattern matched.
