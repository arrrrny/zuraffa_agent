# Traceability: 084-llm-retry-backoff

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:aaacdd37c067124fbf995f3f6ba7bf7f25f33a5f634109091a47e3be041b29bc
statements: 24
automated: 24
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| FR-006 | 22 | - **FR-006**: The system MUST satisfy this requirement: ) already retry 429/5xx with capped exponential backoff behind an | U6, U6 | automated |
| FR-001 | 123 | - **FR-001**: The system MUST satisfy this requirement: The retryable set is exactly: HTTP 429, HTTP 5xx, and | U1 | automated |
| FR-002 | 127 | - **FR-002**: The system MUST satisfy this requirement: Backoff for computed delays is exponential | U2 | automated |
| FR-003 | 131 | - **FR-003**: The system MUST satisfy this requirement: A `Retry-After` header in seconds form is honored UNCLAMPED: | U3, U3 | automated |
| FR-004 | 136 | - **FR-004**: The system MUST satisfy this requirement: Network errors (`LlmNetworkException`) are retried under the | U4 | automated |
| FR-005 | 138 | - **FR-005**: The system MUST satisfy this requirement: On exhaustion the final error is typed and | U5 | automated |
| FR-006 | 145 | - **FR-006**: The system MUST satisfy this requirement: Timing is deterministic under the injected clock: the same | U6, U6 | automated |
| FR-007 | 149 | - **FR-007**: The system MUST satisfy this requirement: `openStreamWithRetry` follows the identical policy on the | U7 | automated |
| FR-008 | 152 | - **FR-008**: The system MUST satisfy this requirement: Gates — `dart analyze` reports no new issues relative to the | U8 | automated |
| FR-003 | 162 | - **FR-003**: The system MUST satisfy this requirement: /FR-005. | U3, U3 | automated |
| AC-1 | 189 | 1. **Given** the feature implementation under its clean-architecture seams **When** T1 (pin): one network error then 200 recovers with one backoff **Then** the pinned regression test passes (`test/llm/retry_084_test.dart`). | A1 | automated |
| AC-2 | 191 | 2. **Given** the feature implementation under its clean-architecture seams **When** T2: network exhaustion → terminal typed error with attempts **Then** the pinned regression test passes (`test/llm/retry_084_test.dart`). | A2 | automated |
| AC-3 | 193 | 3. **Given** the feature implementation under its clean-architecture seams **When** T3: HTTP exhaustion → LlmHttpException with attempts **Then** the pinned regression test passes (`test/llm/retry_084_test.dart`). | A3 | automated |
| AC-4 | 195 | 4. **Given** the feature implementation under its clean-architecture seams **When** T5: Retry-After: 7200 with maxDelayMs: 250 → sleep exactly **Then** the pinned regression test passes (`test/llm/retry_084_test.dart`). | A4 | automated |
| AC-5 | 197 | 5. **Given** the feature implementation under its clean-architecture seams **When** T6 (pin): Retry-After: 90 with maxDelayMs: 250 → 90000 **Then** the pinned regression test passes (`test/llm/retry_084_test.dart`). | A5 | automated |
| AC-6 | 199 | 6. **Given** the feature implementation under its clean-architecture seams **When** T7 (pin): negative Retry-After is treated as 0 **Then** the pinned regression test passes (`test/llm/retry_084_test.dart`). | A6 | automated |
| AC-7 | 201 | 7. **Given** the feature implementation under its clean-architecture seams **When** T8 (pin): openStreamWithRetry honors Retry-After on the initial **Then** the pinned regression test passes (`test/llm/retry_084_test.dart`). | A7 | automated |
| AC-8 | 203 | 8. **Given** the feature implementation under its clean-architecture seams **When** T9 (pin): identical runs record identical sleep sequences **Then** the pinned regression test passes (`test/llm/retry_084_test.dart`). | A8 | automated |
| AC-9 | 205 | 9. **Given** the feature implementation under its clean-architecture seams **When** U4: a 429 then success is retried exactly once with one backoff delay **Then** the pinned regression test passes (`test/llm/retry_test.dart`). | A9 | automated |
| AC-10 | 207 | 10. **Given** the feature implementation under its clean-architecture seams **When** U5: a 5xx then success is retried and succeeds **Then** the pinned regression test passes (`test/llm/retry_test.dart`). | A10 | automated |
| AC-11 | 209 | 11. **Given** the feature implementation under its clean-architecture seams **When** U6: exhausted retries throw the last HTTP error after maxAttempts attempts **Then** the pinned regression test passes (`test/llm/retry_test.dart`). | A11 | automated |
| AC-12 | 211 | 12. **Given** the feature implementation under its clean-architecture seams **When** U7: a non-retryable 4xx is thrown immediately with zero retries **Then** the pinned regression test passes (`test/llm/retry_test.dart`). | A12 | automated |
| AC-13 | 213 | 13. **Given** the feature implementation under its clean-architecture seams **When** U8: backoff delays grow exponentially, are capped, and jitter is deterministic **Then** the pinned regression test passes (`test/llm/retry_test.dart`). | A13 | automated |
| AC-14 | 215 | 14. **Given** the feature implementation under its clean-architecture seams **When** U9: a Retry-After header overrides the computed backoff delay **Then** the pinned regression test passes (`test/llm/retry_test.dart`). | A14 | automated |

