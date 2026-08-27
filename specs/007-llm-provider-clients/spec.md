# Feature Specification: LLM Provider Clients

**Feature Branch**: `007-llm-provider-clients`

**Created**: 2026-08-27

**Status**: Draft

**Input**: Gap analysis vs dart_agent_core — the engine has no LLM clients; all provider code exists only as data models.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - OpenAI-compatible client (Priority: P1)

As the engine, I call any OpenAI-compatible API (self-host, Kimi, Groq, etc.) with streaming, tool calls, and usage tracking — via a single `LlmClient` interface.

**Why this priority**: OpenAI-compatible is the workhorse provider; most self-hosted and third-party APIs use this protocol.

**Independent Test**: A recorded fixture round-trips streaming chunks, tool call assembly, and usage parsing identically to dart_agent_core's OpenAIClient.

**Acceptance Scenarios**:

1. **Given** an OpenAI-compatible endpoint, **When** streaming, **Then** content deltas, tool call fragments, and usage parse correctly.
2. **Given** a malformed tool argument from the model, **When** parsed, **Then** it tolerates gracefully (empty map default).
3. **Given** a non-2xx response, **When** received, **Then** a typed error with status code and body is thrown.

### User Story 2 - Anthropic client (Priority: P1)

As the engine, I call the Anthropic Messages API with thinking/reasoning support, content blocks, and tool use.

**Why this priority**: Claude is a primary provider for many use cases.

**Independent Test**: Same contract test suite as OpenAI-compatible, over Anthropic fixtures.

**Acceptance Scenarios**:

1. **Given** an Anthropic endpoint, **When** streaming, **Then** thinking blocks and content blocks parse correctly.
2. **Given** tool calls in the response, **When** accumulated, **Then** they assemble from streamed argument fragments.

### User Story 3 - Gemini client (Priority: P1)

As the engine, I call the Google Generative AI API with JSON line streaming and function calling.

**Why this priority**: Gemini is a major provider with unique protocol differences.

**Independent Test**: Same contract test suite over Gemini fixtures.

**Acceptance Scenarios**:

1. **Given** a Gemini endpoint, **When** streaming, **Then** JSON line chunks parse correctly.
2. **Given** a MALFORMED_FUNCTION_CALL, **When** retried, **Then** the client handles it gracefully.

### User Story 4 - Shared contract tests (Priority: P1)

As a developer, all three clients pass one shared contract-test suite over recorded-response fixtures, ensuring behavioral equivalence.

**Why this priority**: Prevents provider-specific regressions.

**Independent Test**: A seeded fixture suite runs against all providers with identical assertions.

**Acceptance Scenarios**:

1. **Given** recorded fixtures for each provider, **When** the contract suite runs, **Then** all providers produce identical event sequences, tool-call buffering, and usage fields.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The engine MUST provide a unified `LlmClient` interface with `generate()` and `stream()` methods.
- **FR-002**: OpenAI-compatible, Anthropic, and Gemini clients MUST implement this interface.
- **FR-003**: All clients MUST support multimodal input (text, image, audio, document) and output.
- **FR-004**: All clients MUST support streaming with tool call fragment assembly.
- **FR-005**: All clients MUST track usage (input, output, cached, thought tokens).
- **FR-006**: All clients MUST implement retry with exponential backoff for 429/5xx.
- **FR-007**: All clients MUST be vendored from dart_agent_core with attribution; dart_agent_core MUST NOT appear in the dependency graph.

### Key Entities

- **LlmClient** (interface): generate(), stream(), close()
- **LlmResponse**: content, toolCalls, usage, finishReason
- **LlmResponseChunk**: content, thinking, toolCalls, usage, isComplete
- **LlmUsage**: inputTokens, outputTokens, cachedTokens, thoughtTokens

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All three clients pass shared contract tests on recorded fixtures.
- **SC-002**: dart_agent_core absent from pubspec; vendored code attributed.
- **SC-003**: Each client handles streaming, tool calls, retry, and error cases.

## Dependencies

- After: spec 004 (provider resolution data model)
- Feeds: spec 002 (engine loop consumes clients), spec 008 (fallback chain)
