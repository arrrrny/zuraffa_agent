# Traceability: 007-llm-provider-clients

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:0c04571528d6cc0c7fe26b602a79118f4b7362aac271a74b7805827be782ab53
statements: 15
automated: 15
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 25 | 1. **Given** an OpenAI-compatible endpoint, **When** streaming, **Then** content deltas, tool call fragments, and usage parse correctly. **[AC-1]** | A1 | automated |
| AC-2 | 27 | 2. **Given** a malformed tool argument from the model, **When** parsed, **Then** it tolerates gracefully (empty map default). **[AC-2]** | A2 | automated |
| AC-3 | 29 | 3. **Given** a non-2xx response, **When** received, **Then** a typed error with status code and body is thrown. **[AC-3]** | A3 | automated |
| AC-4 | 42 | 4. **Given** an Anthropic endpoint, **When** streaming, **Then** thinking blocks and content blocks parse correctly. **[AC-4]** | A4 | automated |
| AC-5 | 44 | 5. **Given** tool calls in the response, **When** accumulated, **Then** they assemble from streamed argument fragments. **[AC-5]** | A5 | automated |
| AC-6 | 57 | 6. **Given** a Gemini endpoint, **When** streaming, **Then** JSON line chunks parse correctly. **[AC-6]** | A6 | automated |
| AC-7 | 59 | 7. **Given** a MALFORMED_FUNCTION_CALL, **When** retried, **Then** the client handles it gracefully. **[AC-7]** | A7 | automated |
| AC-8 | 72 | 8. **Given** recorded fixtures for each provider, **When** the contract suite runs, **Then** all providers produce identical event sequences, tool-call buffering, and usage fields. **[AC-8]** | A8 | automated |
| FR-001 | 79 | - **FR-001**: The engine MUST provide a unified `LlmClient` interface with `generate()` and `stream()` methods. | U1 | automated |
| FR-002 | 80 | - **FR-002**: OpenAI-compatible, Anthropic, and Gemini clients MUST implement this interface. | U2 | automated |
| FR-003 | 81 | - **FR-003**: All clients MUST support multimodal input (text, image, audio, document) and output. | U3 | automated |
| FR-004 | 82 | - **FR-004**: All clients MUST support streaming with tool call fragment assembly. | U4 | automated |
| FR-005 | 83 | - **FR-005**: All clients MUST track usage (input, output, cached, thought tokens). | U5 | automated |
| FR-006 | 84 | - **FR-006**: All clients MUST implement retry with exponential backoff for 429/5xx. | U6 | automated |
| FR-007 | 85 | - **FR-007**: All clients MUST be vendored from dart_agent_core with attribution; dart_agent_core MUST NOT appear in the dependency graph. | U7 | automated |

