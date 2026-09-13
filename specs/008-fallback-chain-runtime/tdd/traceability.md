# Traceability: 008-fallback-chain-runtime

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:0dcca1b64965aa0e37220b7ca544c582e41aa163b12853574aeb949fd7a9a931
statements: 12
automated: 12
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 25 | 1. **Given** provider A failing, **When** a call is made, **Then** B serves it; the mission observes only latency. **[AC-1]** | A1 | automated |
| AC-2 | 27 | 2. **Given** A in open state, **When** the cooldown elapses, **Then** a half-open probe routes real traffic back on success. **[AC-2]** | A2 | automated |
| AC-3 | 29 | 3. **Given** a mid-stream failure after partial chunks, **Then** the policy restarts on the next provider — never silently truncates. **[AC-3]** | A3 | automated |
| AC-4 | 42 | 4. **Given** maxConsecutiveFailures=3, **When** 3 consecutive failures occur, **Then** the breaker opens. **[AC-4]** | A4 | automated |
| AC-5 | 44 | 5. **Given** an open breaker with cooldownMs=60000, **When** 60s elapse, **Then** the state transitions to half-open. **[AC-5]** | A5 | automated |
| AC-6 | 46 | 6. **Given** a half-open breaker, **When** a call succeeds, **Then** the state transitions to closed. **[AC-6]** | A6 | automated |
| AC-7 | 59 | 7. **Given** any chain state, **When** the snapshot is read, **Then** it matches the internal breaker states. **[AC-7]** | A7 | automated |
| FR-001 | 66 | - **FR-001**: A `FallbackChainClient` MUST wrap multiple `LlmClient` instances with automatic failover. | U1 | automated |
| FR-002 | 67 | - **FR-002**: Each provider MUST have an independent circuit breaker (open/half-open/closed). | U2 | automated |
| FR-003 | 68 | - **FR-003**: The chain MUST advance on connection error, timeout, 5xx, context overflow, or repeated 429. | U3 | automated |
| FR-004 | 69 | - **FR-004**: Mid-stream failures MUST restart on the next provider (configurable policy). | U4 | automated |
| FR-005 | 70 | - **FR-005**: A health snapshot API MUST expose chain state at any time. | U5 | automated |

