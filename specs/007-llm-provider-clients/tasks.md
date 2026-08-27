# Tasks: LLM Provider Clients

**Input**: Design documents from `/specs/007-llm-provider-clients/`

**Prerequisites**: plan.md (required), spec.md (required for user stories)

**Tests**: Tests are MANDATORY for this feature (TDD extension active; every behavioral task is driven test-first with recorded red evidence).

**Organization**: Tasks are grouped by user story; US1 (OpenAI-compatible + shared interface) is the MVP — US2/US3 are ports onto the frozen contract, US4 is the cross-provider equivalence suite.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Namespace, attribution, and the single purity-gate exception.

- [X] T001 Create `lib/src/llm/` namespace; all files open with dart_agent_core (MIT) port-attribution headers
- [X] T002 [P] Register `lib/src/llm/io_llm_transport.dart` in the CI purity allowlist (`.github/workflows/pipeline.yml`) with justification comment

---

## Phase 2: Foundational contract (US1 prerequisites — blocking)

**Purpose**: The seams every client builds on. No user story can start before these exist.

- [X] T003 [U1] Test: `LlmUsage`/`LlmResponse`/`LlmResponseChunk`/`LlmToolCall` value objects (construction, value equality, copyWith)
- [X] T004 [U1] Implement the value objects in `lib/src/llm/llm_client.dart` (spec-exact fields)
- [X] T005 [U2] Test: `LlmHttpException` carries provider, statusCode, body, and a readable message
- [X] T006 [U2] Implement typed error hierarchy in `lib/src/llm/llm_client.dart`
- [X] T007 [U3] Test: `LlmTransport` seam round-trips request → response/line-stream via `FakeLlmTransport`
- [X] T008 [U3] Implement `lib/src/llm/llm_transport.dart` + `test/llm/fake_llm_transport.dart` fixture helper
- [X] T009 [U4][U5][U6][U7][U8][U9] Test: retry policy — 429/5xx/connection error retried with exponential backoff (injected clock), 4xx not retried, exhaustion throws last error, Retry-After honored
- [X] T010 [U4][U5][U6][U7][U8][U9] Implement `lib/src/llm/retry.dart` + `lib/src/llm/llm_clock.dart` seams
- [X] T011 [U10] Test: `IoLlmTransport` maps `LlmHttpRequest` onto `dart:io` HttpClient (status/headers/body/line stream)
- [X] T012 [U10] Implement `lib/src/llm/io_llm_transport.dart` (the single allowlisted dart:io adapter)

**Checkpoint**: Contract + seams ready; OpenAI client work can begin.

---

## Phase 3: User Story 1 — OpenAI-compatible client (Priority: P1) 🎯 MVP

**Goal**: generate() + stream() against any OpenAI-compatible endpoint, fixture-proven.

- [X] T013 [U11] Test: `generate()` builds the chat/completions body (model, messages incl. multimodal content blocks, tools) and parses content, finishReason, usage
- [X] T014 [U11] Implement `OpenAiCompatibleClient.generate()` (+ request/response mapping)
- [X] T015 [U12] Test: `stream()` parses SSE `data:` lines → content deltas; final chunk carries usage; `[DONE]` yields isComplete
- [X] T016 [U12] Implement `OpenAiCompatibleClient.stream()` SSE parsing
- [X] T017 [U13][A2] Test: tool-call fragments assemble by index across chunks; malformed arguments default to empty map
- [X] T018 [U13][A2] Implement tool-call buffering in the OpenAI streaming path
- [X] T019 [U14][A3] Test: non-2xx response raises `LlmHttpException` with statusCode + body
- [X] T020 [U14][A3] Implement error mapping (already via shared transport; assert client surface)

---

## Phase 4: User Story 2 — Anthropic client (Priority: P1)

**Goal**: Messages API with thinking, content blocks, tool use.

- [X] T021 [U15] Test: `generate()` builds the Messages body (system, messages, tools) and parses content blocks incl. thinking
- [X] T022 [U15] Implement `AnthropicClient.generate()`
- [X] T023 [U16] Test: `stream()` parses message_start/content_block_delta (text + thinking)/message_delta; usage input+output; stop_reason
- [X] T024 [U16] Implement `AnthropicClient.stream()` SSE event parsing
- [X] T025 [U17][A5] Test: tool_use blocks assemble from `input_json_delta` partial-json fragments
- [X] T026 [U17][A5] Implement Anthropic tool-call buffering
- [X] T027 [U18] Test: non-2xx → typed error
- [X] T028 [U18] Implement Anthropic error mapping

---

## Phase 5: User Story 3 — Gemini client (Priority: P1)

**Goal**: Generative Language API with JSON-line streaming and function calling.

- [X] T029 [U19] Test: `generate()` builds generateContent body (contents/parts, tools) and parses text + usageMetadata (prompt/candidates/thoughts/cached)
- [X] T030 [U19] Implement `GeminiClient.generate()`
- [X] T031 [U20] Test: `stream()` parses JSONL chunks → text parts + functionCall assembly + isComplete
- [X] T032 [U20] Implement `GeminiClient.stream()` JSONL parsing
- [X] T033 [U21][A7] Test: MALFORMED_FUNCTION_CALL finishReason handled gracefully (no throw; reason surfaced)
- [X] T034 [U21][A7] Implement Gemini malformed-function-call handling
- [X] T035 [U22] Test: non-2xx → typed error
- [X] T036 [U22] Implement Gemini error mapping

---

## Phase 6: User Story 4 — Shared contract suite (Priority: P1)

**Goal**: One suite, three providers, identical observable behavior.

- [X] T037 [A1] Test: shared contract suite (event sequence, tool-call buffering, usage fields) passes over OpenAI fixtures
- [X] T038 [A4] Test: the same suite passes over Anthropic fixtures
- [X] T039 [A6] Test: the same suite passes over Gemini fixtures
- [X] T040 [A8] Implement/extract `test/llm/llm_client_contract_test.dart` parameterization (fixture adapters per provider)

---

## Phase 7: Closing gates

- [X] T041 `dart analyze` pristine for all files added by this feature (SC-004)
- [X] T042 Full-suite delta check vs. cycle-log baseline (no new failures) + verify SC-002 (dart_agent_core absent from pubspec.yaml/pubspec.lock; attribution headers grep clean) + commit spec-kit artifacts (`spec.md`, `plan.md`, `tasks.md`, `tdd/*`)
- [X] T043 [A1][A2][A3][A4][A5][A6][A7][A8] Outer-loop acceptance check: AC-1..AC-8 each green through the client's public API on recorded fixtures

---

## Phase 8: TDD remediation (from tdd/verification.md — verdict: FAIL)

- [ ] T044 [MED] Add a JSON-literal fixture helper (e.g. `test/llm/wire.dart` building SSE/JSONL lines via `jsonEncode`) so recorded fixtures cannot carry hand-escaping bugs; migrate the two hand-escaped fixtures from cycles 13/17. Proven by: `dart test test/llm` green with fixtures built through the helper.
- [ ] T045 [LOW] Include `arguments` in `LlmToolCall.toString()` (`lib/src/llm/llm_client.dart:143`) so equality failures are diagnosable. Proven by: `dart test test/llm/llm_client_test.dart`.
- [ ] T046 [HIGH, process] Restore one-behavior-per-red discipline for specs 008/009: every behavior gets its own observed red before its implementation exists; no bundled greens. Proven by: cycle logs for 008/009 recording a red per behavior; verification classifying all behaviors PROVEN or LIKELY.
