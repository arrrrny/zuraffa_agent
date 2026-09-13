# Traceability: 004-providers-and-fallback

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:9b7759f23261392a1c3af7389a49ab116d032e23b53f412ca678a42742d5c47a
statements: 12
automated: 12
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 25 | 1. **Given** recorded provider fixtures, **When** each client streams, **Then** events, tool-call buffering, and usage fields parse identically across providers. | A1 | automated |
| AC-2 | 27 | 2. **Given** the engine's pubspec, **When** resolved, **Then** dart_agent_core is absent; vendored files carry attribution. | A2 | automated |
| AC-3 | 40 | 3. **Given** any completed LLM call, **When** inspected, **Then** its ledger entry exists with provider + model + token counts. | A3 | automated |
| AC-4 | 53 | 4. **Given** provider A failing, **When** a call is made, **Then** B serves it; the mission observes only latency. | A4 | automated |
| AC-5 | 55 | 5. **Given** A in open state, **When** the cooldown elapses, **Then** a half-open probe routes real traffic back on success. | A5 | automated |
| AC-6 | 57 | 6. **Given** a mid-stream failure after partial chunks, **Then** the policy restarts on the next provider (or surfaces, per config) — never silently truncates. | A6 | automated |
| AC-7 | 70 | 7. **Given** any chain state, **When** the snapshot is read, **Then** it matches the internal breaker states. | A7 | automated |
| FR-001 | 84 | - **FR-001**: The engine MUST provide OpenAI-compatible, Anthropic, and Gemini clients behind one `LlmClient` interface on engine primitives. | U1 | automated |
| FR-002 | 85 | - **FR-002**: Provider code MUST be vendored from dart_agent_core with attribution; dart_agent_core MUST NOT appear in the dependency graph. | U2 | automated |
| FR-003 | 86 | - **FR-003**: Every call MUST account usage into the UsageLedger. | U3 | automated |
| FR-004 | 87 | - **FR-004**: A fallback chain MUST advance on connection/timeout/5xx/context-overflow/repeated-429 with per-provider circuit breaker (open/half-open/closed) and explicit mid-stream policy. | U4 | automated |
| FR-005 | 88 | - **FR-005**: A health snapshot API MUST expose chain state. | U5 | automated |

